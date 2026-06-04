## 0.2.1

### Fixed

- **Garbage output on long conversations** — when the KV cache reached the
  context limit (default 2048 tokens), llama.cpp read beyond the window and
  produced random bytes. The context is now cleared automatically when within
  100 tokens of the limit.

---

## 0.2.0

### New — LocalEngine: offline on-device inference via llama.cpp

Run AI models entirely offline — no API key, no internet, no server.
The model runs on the device using llama.cpp compiled from C++.

**New classes:**
- `LocalEngine` — implements `AiEngine` for local .gguf models. Drop-in
  replacement for `GeminiEngine` — same `send`, `stream`, `dispose` API.
- `LocalConfig` — configuration for `LocalEngine`. Supports `modelPath`,
  `systemPrompt`, `stopSequences`, `temperature`, `maxOutputTokens`,
  `contextSize`, `repeatPenalty`, `topP`, `topK`, `threads`, `seed`,
  `modelType`.
- `LocalModelType` — chat template enum: `auto`, `qwen`, `llama3`, `gemma`,
  `phi`, `mistral`, `deepSeek`. Use `auto` to detect from .gguf metadata.

**Supported platforms:** Android, iOS, Linux, macOS (Windows coming soon).

**Model support:** any quantized `.gguf` model from HuggingFace —
Qwen 2.5, Llama 3, Gemma 3, Phi 4, Mistral, DeepSeek, and more.

**Usage:**
```dart
FlutterMind.init(
  engine: LocalEngine(
    config: LocalConfig(
      modelPath: '/data/user/0/com.app/files/models/qwen.gguf',
      systemPrompt: Prompt(role: 'helpful assistant'),
      stopSequences: ['<|im_end|>', '<|im_start|>'],
      modelType: LocalModelType.qwen,
    ),
  ),
);

final response = await FlutterMind.send(userMessage: 'Hello!');
```

---

### Fixed — LocalEngine stability

- **UI never freezes** — model loading (5–30 s) and inference run in a
  background `Isolate`. The main thread stays responsive throughout.
- **Concurrent call protection** — sending two messages before the model
  finishes loading no longer crashes. A `Completer` gate queues calls safely.
- **SIGSEGV fix** — dangling pointer crash when using a long `systemPrompt`
  (e.g. from `Prompt.build()`). The C++ layer now copies the string into stable
  storage before Dart frees its native buffer.
- **Stop sequences now work** — `LocalConfig.stopSequences` are passed through
  FFI to C++ and checked after every generated token. Previously silently ignored.
- **Default threads is 4** — was `0` (handed to `hardware_concurrency()`,
  which uses all cores including slow efficiency cores). `4` targets performance
  cores and keeps the OS responsive.

---

## 0.1.0

### New — Prompt Engineering System

A complete prompt engineering API. Build system prompts from structured data
instead of writing raw strings — from one field to full expert config.

**New classes:**
- `Prompt` — builds the system prompt string automatically. Pass it to
  `GeminiConfig.systemPrompt` and the engine calls `build()` per request.
- `AiPreset` — five ready-made `Prompt` presets: `chat`, `codeHelper`,
  `summarizer`, `qa`, `stepByStep`. Use as-is or customize with `copyWith`.
- `ResponseFormat` — controls response shape: `paragraph`, `numberedList`,
  `bulletedList`, `steps`, `table`, `json`, `code`, `oneSentence`, `oneWord`.
- `ResponseTone` — controls writing style: `casual`, `friendly`, `formal`,
  `concise`, `detailed`.
- `ResponseLanguage` — controls output language: `english`, `arabic`,
  `bilingual`, `auto` (detects per message).
- `StopSignalMode` — controls stop sequences: `auto`, `manual`, `none`.
- `PromptExample` — a single input/output pair for few-shot prompting.
- `MessageAnalyzer` — static helpers to detect language, tone, and question
  intent from a user message. Used internally by `ResponseLanguage.auto`.

**Token-compressed output (default):**
`Prompt.build()` emits a telegraphic key:value format by default (~45% fewer
tokens than natural language). Set `compressed: false` for verbose output.

**Expert fields on `Prompt`:**
- `chainOfThought` / `chainSteps` — adds step-by-step reasoning directive.
- `preventInjection` — prepends immutable headers that resist jailbreak attempts.
- `responseAnchor` — forces the model to start its response with an exact phrase.
- `negativePatterns` — phrases the model must never output.
- `exampleSelector` — callback to dynamically pick examples per message.

**Stop sequences integration:**
```dart
final prompt = Prompt(format: ResponseFormat.numberedList, maxItems: 3);
GeminiConfig(
  systemPrompt: prompt,
  stopSequences: prompt.stopSequences, // ['[END]'] — model stops exactly here
)
```

---

### Improved — `GeminiConfig.model` is now optional

`model` no longer needs to be set in per-call config overrides. Omit it to
inherit the engine's default model:

```dart
// Before — had to repeat the model on every override
await FlutterMind.send(
  userMessage: message,
  config: GeminiConfig(model: GeminiModel.flash25, systemPrompt: Prompt(...)),
);

// Now — only set what changes
await FlutterMind.send(
  userMessage: message,
  config: GeminiConfig(systemPrompt: Prompt(role: 'new role')),
);
```

---

### Fixed

- `_resolveSmartDefaults` now falls back to `GeminiModel.flash25` when a
  `GeminiConfig` is passed at engine init without a model — previously caused
  a null crash at request time.
- Corrected 15 documentation errors across the codebase (stale class references,
  wrong parameter names, wrong API call syntax in code examples).

---

## 0.0.1

- Initial release — Google Gemini engine with `send`, `stream`, multi-turn
  history, thinking models, structured JSON output, token counting, retry
  configuration, and `beforeSend` hook.
