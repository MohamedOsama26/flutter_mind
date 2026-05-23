/**
 * @file local_model.h
 * @brief C API for the local model module.
 *
 * Provides a simple lifecycle interface for initializing, using, and
 * cleaning up a locally-hosted inference module. All functions are
 * exported with C linkage for FFI compatibility.
 */

#ifndef LOCAL_MODEL_H
#define LOCAL_MODEL_H

extern "C"
{

    struct LocalModelConfig
    {
        const char *model_path;
        const char *system_prompt;
        float temperature;
        int max_tokens;
        int context_size;
        float repeat_penalty;
        float top_p;
        int top_k;
        int seed;
        int thread_count;
        int model_type;
    };

    int local_model_init(LocalModelConfig config);

    int local_model_init_params(
        const char *model_path,
        const char *system_prompt,
        float temperature,
        int max_tokens,
        int context_size,
        float repeat_penalty,
        float top_p,
        int top_k,
        int seed,
        int thread_count,
        int model_type);

    const char *local_model_prompt(const char *prompt);

    void local_model_cleanup();
}

#endif // LOCAL_MODEL_H