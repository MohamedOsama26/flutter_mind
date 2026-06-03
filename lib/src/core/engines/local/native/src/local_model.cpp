#include "local_model.h"
#include <llama.h> // Placeholder for the actual model header
#include <string>
#include <vector>
#include <cstring>
#include <thread>

static llama_model *g_model = nullptr;
static llama_context *g_context = nullptr;
static std::string g_response;
static LocalModelConfig g_config;
static std::vector<std::string> g_stop_sequences; // parsed from config.stop_sequences
// owns the system prompt string — Dart frees its native buffer after init returns
static char g_system_prompt_buf[4096] = {};

// detect model type from gguf metadata
static int detect_model_type()
{
    char arch_buf[64] = {};
    int len = llama_model_meta_val_str(g_model, "general.architecture", arch_buf, sizeof(arch_buf));
    if (len <= 0)
        return 0;
    std::string a(arch_buf);
    if (a == "qwen2")
        return 1;
    if (a == "llama")
        return 2;
    if (a == "gemma")
        return 3;
    if (a == "gemma2")
        return 3; // same template as gemma
    if (a == "gemma3")
        return 3;
    if (a == "phi2")
        return 4;
    if (a == "phi3")
        return 4; // same template as phi
    if (a == "mistral")
        return 5;
    if (a == "deepseek2")
        return 6;
    return 0;
}

// format prompt based on model type
static std::string format_prompt(const char *prompt)
{
    int type = g_config.model_type;
    if (type == 0)
        type = detect_model_type(); // auto

    std::string sys = g_config.system_prompt
                          ? g_config.system_prompt
                          : "You are a helpful assistant.";

    if (type == 1)
    { // Qwen
        return "<|im_start|>system\n" + sys + "<|im_end|>\n" + "<|im_start|>user\n" + prompt + "<|im_end|>\n" + "<|im_start|>assistant\n";
    }
    if (type == 2)
    { // Llama 3
        return "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n" + sys + "\n<|start_header_id|>user<|end_header_id|>\n" + prompt + "\n<|start_header_id|>assistant<|end_header_id|>\n";
    }
    if (type == 3)
    { // Gemma
        return "<start_of_turn>user\n" + sys + "\n" + prompt + "<end_of_turn>\n<start_of_turn>model\n";
    }
    if (type == 4)
    { // Phi
        return "<|system|>\n" + sys + "<|end|>\n" + "<|user|>\n" + prompt + "<|end|>\n" + "<|assistant|>\n";
    }
    if (type == 5)
    { // Mistral
        return "[INST] " + sys + "\n" + prompt + " [/INST]";
    }
    if (type == 6)
    { // DeepSeek
        return "<|begin▁of▁sentence|>" + sys + "\n\nUser: " + prompt + "\n\nAssistant:";
    }

    // default fallback
    return sys + "\n" + prompt;
}

// splits \x1F-delimited string into a vector of stop sequences
static std::vector<std::string> parse_stop_sequences(const char *raw)
{
    std::vector<std::string> result;
    if (!raw || raw[0] == '\0') return result;
    std::string s(raw);
    size_t start = 0, pos;
    while ((pos = s.find('\x1F', start)) != std::string::npos) {
        if (pos > start) result.push_back(s.substr(start, pos - start));
        start = pos + 1;
    }
    if (start < s.size()) result.push_back(s.substr(start));
    return result;
}

// returns true if response currently ends with any stop sequence
static bool ends_with_stop(const std::string &response)
{
    for (const auto &stop : g_stop_sequences) {
        if (response.size() >= stop.size() &&
            response.compare(response.size() - stop.size(), stop.size(), stop) == 0)
            return true;
    }
    return false;
}

// removes the matching stop sequence from the end of response
static void trim_stop(std::string &response)
{
    for (const auto &stop : g_stop_sequences) {
        if (response.size() >= stop.size() &&
            response.compare(response.size() - stop.size(), stop.size(), stop) == 0) {
            response.erase(response.size() - stop.size());
            return;
        }
    }
}

int local_model_init(LocalModelConfig config)
{
    g_config = config;
    g_stop_sequences = parse_stop_sequences(config.stop_sequences);
    llama_backend_init();                                                  // Placeholder: Initialize the backend (e.g., load libraries, set up threads, etc.)
    llama_model_params model_params = llama_model_default_params();        // Placeholder: Get default model parameters
    g_model = llama_model_load_from_file(config.model_path, model_params);
    if (!g_model)
    {
        return 1; // Error loading model
    }

    llama_context_params context_params = llama_context_default_params(); // Placeholder: Get default context parameters
    context_params.n_ctx = config.context_size > 0 ? config.context_size : 2048;
    context_params.n_threads = config.thread_count > 0 ? config.thread_count : std::thread::hardware_concurrency(); // Example: Set context size
    g_context = llama_init_from_model(g_model, context_params);
    if (!g_context)
    {
        return 1;
    }
    return 0; // Success
}

const char *local_model_prompt(const char *prompt)
{
    std::string formatted = format_prompt(prompt);

    int max_ctx = g_config.context_size > 0 ? g_config.context_size : 2048;
    std::vector<llama_token> tokens(max_ctx);

    int n_tokens = llama_tokenize(
        llama_model_get_vocab(g_model),
        formatted.c_str(),
        (int32_t)formatted.size(),
        tokens.data(),
        (int32_t)tokens.size(),
        true,
        false);
    if (n_tokens < 0)
        return nullptr;
    tokens.resize(n_tokens);

    // decode prompt
    llama_batch batch = llama_batch_get_one(tokens.data(), n_tokens);
    llama_decode(g_context, batch);

    // setup sampler with config values
    auto sparams = llama_sampler_chain_default_params();
    auto sampler = llama_sampler_chain_init(sparams);

    // apply top_k
    if (g_config.top_k > 0)
        llama_sampler_chain_add(sampler,
                                llama_sampler_init_top_k(g_config.top_k));

    // apply top_p
    if (g_config.top_p > 0)
        llama_sampler_chain_add(sampler,
                                llama_sampler_init_top_p(g_config.top_p, 1));

    // apply temperature
    float temp = g_config.temperature > 0
                     ? g_config.temperature
                     : 0.7f;
    llama_sampler_chain_add(sampler,
                            llama_sampler_init_temp(temp));

    // apply repeat penalty
    float penalty = g_config.repeat_penalty > 0
                        ? g_config.repeat_penalty
                        : 1.1f;
    llama_sampler_chain_add(sampler,
                            llama_sampler_init_penalties(64, penalty, 0.0f, 0.0f));

    // sample from the modified distribution using the configured seed
    uint32_t seed = g_config.seed > 0 ? (uint32_t)g_config.seed : LLAMA_DEFAULT_SEED;
    llama_sampler_chain_add(sampler,
                            llama_sampler_init_dist(seed));

    // generate response
    g_response = "";
    int max = g_config.max_tokens > 0 ? g_config.max_tokens : 512;

    for (int i = 0; i < max; i++)
    {
        llama_token token = llama_sampler_sample(sampler, g_context, -1);

        // stop if end of generation
        if (llama_vocab_is_eog(llama_model_get_vocab(g_model), token))
            break;

        // token to text
        char buf[128];
        int n = llama_token_to_piece(
            llama_model_get_vocab(g_model),
            token, buf, sizeof(buf), 0, false);
        if (n > 0)
            g_response += std::string(buf, n);

        // stop immediately if response ends with a user-defined stop sequence
        if (ends_with_stop(g_response)) {
            trim_stop(g_response);
            break;
        }

        // feed back
        batch = llama_batch_get_one(&token, 1);
        llama_decode(g_context, batch);
    }

    llama_sampler_free(sampler);

    // safety net — trim any stop sequence that spans the final token boundary
    trim_stop(g_response);

    return g_response.c_str();
}

// Flat-param wrapper — easier to call from Dart FFI (no struct layout needed)
extern "C" int local_model_init_params(
    const char *model_path,
    const char *system_prompt,
    const char *stop_sequences,
    float temperature,
    int max_tokens,
    int context_size,
    float repeat_penalty,
    float top_p,
    int top_k,
    int seed,
    int thread_count,
    int model_type)
{
    LocalModelConfig config = {};
    config.model_path = model_path; // safe — llama.cpp copies the path internally
    // copy system_prompt into stable storage — Dart frees the native buffer after this call returns
    if (system_prompt && system_prompt[0]) {
        strncpy(g_system_prompt_buf, system_prompt, sizeof(g_system_prompt_buf) - 1);
        g_system_prompt_buf[sizeof(g_system_prompt_buf) - 1] = '\0';
        config.system_prompt = g_system_prompt_buf;
    } else {
        config.system_prompt = nullptr;
    }
    config.stop_sequences = (stop_sequences && stop_sequences[0]) ? stop_sequences : nullptr;
    config.temperature = temperature;
    config.max_tokens = max_tokens;
    config.context_size = context_size;
    config.repeat_penalty = repeat_penalty;
    config.top_p = top_p;
    config.top_k = top_k;
    config.seed = seed;
    config.thread_count = thread_count;
    config.model_type = model_type;
    return local_model_init(config);
}

void local_model_cleanup()
{
    if (g_context)
    {
        llama_free(g_context); // Placeholder: Free the context
        g_context = nullptr;
    }
    if (g_model)
    {
        llama_model_free(g_model); // Placeholder: Free the model
        g_model = nullptr;
    }
    llama_backend_free();
}