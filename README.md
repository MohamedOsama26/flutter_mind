<p align="center">
  <img src="https://raw.githubusercontent.com/MohamedOsama26/flutter_mind/main/assets/logo.svg" width="100" alt="flutter_mind logo"/>
</p>

<h1 align="center">flutter_mind</h1>

<p align="center">
  <strong>Any AI. One interface.</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/flutter_mind"><img src="https://img.shields.io/pub/v/flutter_mind.svg" alt="pub version"/></a>
  <a href="https://pub.dev/packages/flutter_mind"><img src="https://img.shields.io/pub/likes/flutter_mind" alt="pub likes"/></a>
  <a href="https://pub.dev/packages/flutter_mind"><img src="https://img.shields.io/pub/points/flutter_mind" alt="pub points"/></a>
  <a href="https://github.com/MohamedOsama26/flutter_mind/blob/main/LICENSE"><img src="https://img.shields.io/github/license/MohamedOsama26/flutter_mind" alt="license"/></a>
</p>

---

## Why flutter_mind?

Most AI packages for Flutter just wrap the API — you still have to write the prompts, handle errors, manage tokens, and figure out streaming yourself.

**flutter_mind does more:**

- 🔌 **One API for all providers** — switch from Gemini to Claude in one line
- 💬 **Multi-turn chat** — conversation history with automatic token trimming
- ⚡ **Streaming** — typing-effect UI out of the box
- 🧠 **Thinking models** — built-in support for reasoning budgets
- 🛡️ **Safe by default** — input validation, retry logic, and clear error messages
- 🎯 **Zero Firebase required** — just an API key

---

## Supported Providers

| Provider | Status | Models |
|---|---|---|
| Google Gemini | ✅ v1 | Flash 2.5, Pro 2.5, Flash-Lite, and more |
| OpenAI | 🔜 v2 | GPT-4o, GPT-4o Mini |
| Anthropic Claude | 🔜 v2 | Sonnet, Opus, Haiku |
| Ollama (local) | 🔜 v2 | Llama, Mistral, DeepSeek |
| Grok | 🔜 v2 | — |
| DeepSeek | 🔜 v2 | — |

---

## Installation

```yaml
dependencies:
  flutter_mind: ^0.1.0
```

```bash
flutter pub get
```

---

## Quick Start

```dart
import 'package:flutter_mind/flutter_mind.dart';

void main() {
  FlutterMind.init(
    engine: GeminiEngine(apiKey: 'YOUR_GEMINI_API_KEY'),
  );
  runApp(MyApp());
}

// Anywhere in your app — no imports, no passing around
final response = await FlutterMind.send(userMessage: 'suggest a game');
print(response.text);
```

Three lines in `main()`. Done.

---

## Getting Your API Key

### Google Gemini — Free tier available

1. Go to [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click **Create API Key** — no credit card required

### OpenAI *(coming in v2)*

1. Go to [platform.openai.com](https://platform.openai.com) → **API Keys** → **Create new secret key**

### Anthropic Claude *(coming in v2)*

1. Go to [console.anthropic.com](https://console.anthropic.com) → **API Keys** → **Create Key**

### Ollama — Free, runs locally *(coming in v2)*

1. Download from [ollama.com](https://ollama.com), then run `ollama pull llama3.2` — no API key needed

---

## Usage

### Send a message

```dart
final response = await FlutterMind.send(userMessage: 'what is Flutter?');

print(response.text);          // the response text
print(response.totalTokens);   // total tokens used
print(response.inputTokens);   // tokens in your message
print(response.outputTokens);  // tokens in the response
```

---

### Streaming — typing effect UI

```dart
FlutterMind.stream(userMessage: 'tell me a story').listen((chunk) {
  setState(() => text += chunk); // text appears word by word
});
```

---

### Multi-turn chat — conversation with memory

```dart
final history = <ChatMessage>[];

// First turn
final r1 = await FlutterMind.send(
  userMessage: 'my name is Osama',
  history: history,
);
history.add(ChatMessage.user('my name is Osama'));
history.add(ChatMessage.model(r1.text));

// Second turn — model remembers the name
final r2 = await FlutterMind.send(
  userMessage: 'what is my name?',
  history: history,
  maxHistoryMessages: 20, // oldest turns are dropped automatically
);
print(r2.text); // "Your name is Osama"
```

---

### Engine configuration

Set your defaults once — every call uses them automatically:

```dart
FlutterMind.init(
  engine: GeminiEngine(
    apiKey: 'YOUR_KEY',
    config: GeminiConfig(
      model: GeminiModel.flash25,
      systemPrompt: Prompt(role: 'game suggestion assistant'),
      temperature: 0.8,
      maxOutputTokens: 500,
    ),
  ),
);
```

---

### Prompt engineering

Control how the model behaves with the `Prompt` class — from one field to full expert config.

**Tier 1 — Minimal**

```dart
GeminiConfig(
  systemPrompt: Prompt(role: 'game suggestion assistant'),
)
```

**Tier 2 — Standard**

```dart
Prompt(
  role: 'game assistant',
  format: ResponseFormat.numberedList,
  maxItems: 3,
  language: ResponseLanguage.auto, // detects Arabic vs English per message
  constraints: ['mobile only', 'no violent games'],
)
```

**Tier 3 — Advanced**

```dart
Prompt(
  role: 'mobile game expert for Egyptian users',
  goal: 'suggest games that match the user mood and age',
  constraints: ['mobile only', 'no violent games', 'available in Egypt'],
  format: ResponseFormat.numberedList,
  maxItems: 3,
  language: ResponseLanguage.auto,
  tone: ResponseTone.friendly,
  audience: 'Egyptian teenagers',
  examples: [
    PromptExample(input: 'fun game', output: 'Hollow Knight — platformer'),
    PromptExample(input: 'relaxing', output: 'Stardew Valley — farming sim'),
  ],
)
```

**Tier 4 — Expert**

```dart
Prompt(
  role: 'game assistant',
  chainOfThought: true,
  chainSteps: ['identify user mood', 'match game genre', 'select 3 games'],
  preventInjection: true,        // resists jailbreak attempts
  responseAnchor: 'Here are your top 3 games:',
  negativePatterns: ['never suggest PC games'],
  compressed: false,             // verbose output for complex reasoning
)
```

**Ready-made presets**

```dart
// Use directly
GeminiConfig(systemPrompt: AiPreset.chat)
GeminiConfig(systemPrompt: AiPreset.summarizer)
GeminiConfig(systemPrompt: AiPreset.codeHelper)
GeminiConfig(systemPrompt: AiPreset.stepByStep)

// Customize one field
GeminiConfig(
  systemPrompt: AiPreset.chat.copyWith(role: 'Egyptian culture guide'),
)
```

**Stop sequences — pair with the prompt**

```dart
final prompt = Prompt(
  format: ResponseFormat.numberedList,
  maxItems: 3,
);

GeminiConfig(
  systemPrompt: prompt,
  stopSequences: prompt.stopSequences, // → ['[END]'] — model stops exactly here
)
```

---

### Per-call config override

Override only what changes for a single call — defaults stay untouched:

```dart
// Uses your default config
await FlutterMind.send(userMessage: 'suggest a game');

// Overrides just for this one call
await FlutterMind.send(
  userMessage: 'solve this complex math problem',
  config: GeminiConfig(
    model: GeminiModel.pro25,
    temperature: 0.1,
    thinkingLevel: ThinkingLevel.deep,
  ),
);
```

---

### Thinking models

Let the model reason before answering — better results on hard problems:

```dart
GeminiConfig(
  model: GeminiModel.pro25,
  thinkingLevel: ThinkingLevel.moderate,
)

// Or set an exact token budget
GeminiConfig(
  model: GeminiModel.pro25,
  thinkingLevel: CustomThinkingBudget(tokens: 4000),
)
```

| Level | Tokens | Best For |
|---|---|---|
| `ThinkingLevel.none` | 0 | Fastest, cheapest |
| `ThinkingLevel.light` | 512 | Simple reasoning |
| `ThinkingLevel.moderate` | 2,048 | Coding, math |
| `ThinkingLevel.deep` | 8,192 | Complex problems |
| `ThinkingLevel.max` | 24,576 | Hardest problems |

Access the model's reasoning in the response:

```dart
final response = await FlutterMind.send(
  userMessage: 'explain quantum entanglement simply',
  config: GeminiConfig(
    model: GeminiModel.pro25,
    thinkingLevel: ThinkingLevel.moderate,
  ),
);

print(response.text);         // the answer
print(response.thinkingText); // how it got there (null if not a thinking model)
print(response.hasThinking);  // true / false
```

---

### Structured JSON output

Force the model to always return valid, parseable JSON:

```dart
GeminiConfig(
  model: GeminiModel.flash25,
  responseMimeType: 'application/json',
  responseSchema: {
    'type': 'object',
    'properties': {
      'name':   {'type': 'string'},
      'genre':  {'type': 'string'},
      'rating': {'type': 'number'},
    },
    'required': ['name', 'genre', 'rating'],
  },
)
```

---

### beforeSend hook — inject runtime context

Enrich every message with user profile, location, or app state before it reaches the AI:

```dart
FlutterMind.init(
  engine: GeminiEngine(apiKey: 'YOUR_KEY'),
  beforeSend: (message) async {
    final user = await UserService.getProfile();
    final location = await LocationService.current();
    return 'User: ${user.name}, Location: $location\n\n$message';
  },
);

// User types: "what restaurants are near me?"
// Model receives: "User: Osama, Location: Cairo, Egypt\n\nwhat restaurants are near me?"
```

---

### Token management

```dart
// Accurate count — calls the API, always free
final tokens = await FlutterMind.countTokens(userMessage: longText);
if (tokens > 100000) print('Message too long');

// Rough estimate — instant, no API call
// Note: Arabic text uses 2–3× more tokens than English
final estimate = FlutterMind.estimateTokens(message);
```

---

### Retry configuration

```dart
GeminiEngine(
  apiKey: 'YOUR_KEY',

  // Default — 2 attempts on 429, 500, 503
  retry: RetryConfig(),

  // Custom
  retry: RetryConfig(
    maxAttempts: 5,
    delay: Duration(seconds: 2),
    retryOn: {429, 503},
  ),

  // Disable
  retry: RetryConfig.none,
)
```

---

### Availability check

```dart
if (!await FlutterMind.isAvailable()) {
  showDialog(context, 'AI is currently unavailable. Try again later.');
  return;
}
```

---

### Multiple engines in one app

Use `FlutterMindClient` directly when you need more than one engine:

```dart
final chatClient = FlutterMindClient(
  engine: GeminiEngine(
    apiKey: 'YOUR_KEY',
    config: GeminiConfig(
      model: GeminiModel.flash25,
      systemPrompt: Prompt(role: 'friendly chat assistant'),
    ),
  ),
);

final summaryClient = FlutterMindClient(
  engine: GeminiEngine(
    apiKey: 'YOUR_KEY',
    config: GeminiConfig(
      model: GeminiModel.pro25,
      systemPrompt: Prompt(role: 'document summarizer', tone: ResponseTone.concise),
      temperature: 0.1,
    ),
  ),
);

await chatClient.send(userMessage: 'hello');
await summaryClient.send(userMessage: longDocument);
```

---

## Gemini Models

| Constant | Model ID | Status | Best For |
|---|---|---|---|
| `GeminiModel.flash25` | gemini-2.5-flash | ✅ Stable | General use — recommended default |
| `GeminiModel.flash25Lite` | gemini-2.5-flash-lite | ✅ Stable | High volume, lowest cost |
| `GeminiModel.pro25` | gemini-2.5-pro | ✅ Stable | Complex reasoning, analysis |
| `GeminiModel.flash3Preview` | gemini-3-flash-preview | ⚠️ Preview | Frontier performance |
| `GeminiModel.flash31Lite` | gemini-3.1-flash-lite | ✅ Stable | Fast, affordable, Gemini 3 |
| `GeminiModel.pro31Preview` | gemini-3.1-pro-preview | ⚠️ Preview | Most powerful available |

Use `CustomModel` for any model not listed:

```dart
GeminiConfig(model: CustomModel('gemini-4.0-ultra'))
```

---

## Error Handling

```dart
try {
  final response = await FlutterMind.send(userMessage: message);
  print(response.text);
} on ValidationException catch (e) {
  // Bad input — empty message or exceeds 50,000 characters
  print(e.message);
} on EngineException catch (e) {
  // API error — invalid key, rate limit, network issue
  print(e.message);
  print(e.statusCode); // 401, 429, 500 ...
} on FlutterMindException catch (e) {
  // Any other flutter_mind error
  print(e.message);
}
```

### Common status codes

| Code | Meaning | Fix |
|---|---|---|
| 400 | Bad request or invalid API key | Check your key at aistudio.google.com/apikey |
| 401 | Unauthorized | API key rejected |
| 403 | No permission | Key may not have access to this model |
| 404 | Model not found | Check model name or use `CustomModel` |
| 429 | Rate limit | Add `RetryConfig` or upgrade your API plan |
| 500 | Server error | Temporary — try again |

---

## API Key Security

**Never hardcode API keys in production apps.** Anyone can extract them from your APK or IPA.

```dart
// During development — environment variable
GeminiEngine(
  apiKey: const String.fromEnvironment('GEMINI_KEY'),
)
```

```dart
// In production — proxy through your own backend
// Flutter app → Your server → Gemini API
// The key never leaves your server
```

Use [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) for local `.env` files.

---

## Roadmap

### v1 — Current
- [x] Google Gemini engine
- [x] Send and streaming
- [x] Multi-turn conversation history
- [x] Thinking model support (ThinkingLevel presets + custom budget)
- [x] Structured JSON output
- [x] Token management (accurate + estimate)
- [x] Retry configuration
- [x] Input validation
- [x] beforeSend hook
- [x] Prompt engineering system (Prompt, AiPreset, few-shot examples, chain of thought)

### v2 — Coming Soon
- [ ] OpenAI engine
- [ ] Anthropic Claude engine
- [ ] Ollama engine (local models — no API key, no cost)
- [ ] Response parser (JSON → typed Dart objects)
- [ ] flutter_mind_vision (image generation)
- [ ] flutter_mind_audio (TTS, STT)

---

## Contributing

Contributions are welcome. To contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes with a clear message
4. Push and open a Pull Request

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built by <a href="https://github.com/MohamedOsama26">Mohamed Osama</a> · Egypt 🇪🇬
</p>
