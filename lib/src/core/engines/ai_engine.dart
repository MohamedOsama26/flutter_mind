import 'package:flutter_mind/src/core/configs/ai_config.dart';
import 'package:flutter_mind/src/core/models/ai_model.dart';
import 'package:flutter_mind/src/core/models/chat_message.dart';
import 'package:flutter_mind/src/ai_response.dart';

/// Contract that every AI engine must implement.
///
/// Each engine wraps one AI provider (Gemini, OpenAI, Claude, etc.) and
/// exposes a consistent API so the rest of the package — and your app —
/// can swap providers without changing any calling code.
///
/// ## Built-in engines
///
/// - [GeminiEngine] — Google Gemini
///
/// ## Custom engine
///
/// Implement this interface to connect any other provider — Ollama,
/// HuggingFace, a local model, or a custom REST endpoint:
///
/// ```dart
/// class OllamaEngine implements AiEngine {
///   OllamaEngine({
///     required String baseUrl,
///     AiConfig? config,
///   }) : _baseUrl = baseUrl,
///        _defaultConfig = config ?? CustomConfig(model: CustomModel('llama3.2'));
///
///   final String _baseUrl;
///   final AiConfig _defaultConfig;
///
///   @override
///   AiModel get model => _defaultConfig.model;
///
///   @override
///   Future<AiResponse> send({required String userMessage, AiConfig? config}) async {
///     // your HTTP call here
///   }
///
///   @override
///   Stream<String> stream({required String userMessage, AiConfig? config}) async* {
///     // your streaming logic here
///   }
///
///   @override
///   Future<int> countTokens({required String userMessage, AiConfig? config}) async {
///     return (userMessage.length / 4).ceil(); // rough estimate
///   }
///
///   @override
///   Future<bool> isAvailable() async => true;
///
///   @override
///   void validate() {}
///
///   @override
///   void dispose() {}
/// }
/// ```
abstract interface class AiEngine {
  /// The model this engine uses by default.
  ///
  /// Set at construction time via the engine's config.
  /// Individual calls can override the model via the `config` parameter.
  AiModel get model;

  /// Sends a single message and returns the full [AiResponse].
  ///
  /// Waits for the complete response before returning — use [stream] instead
  /// if you want to display output word by word as it arrives.
  ///
  /// [userMessage] — the message from the end user.
  /// [config] — optional per-call override. Only the fields you set will
  /// replace the engine's defaults; everything else stays the same.
  /// [history] — optional list of previous [ChatMessage]s to give the model
  /// context. Pass user and model turns in order, oldest first.
  /// [maxHistoryMessages] — caps how many history messages are sent.
  /// Older messages beyond this limit are dropped to control token usage.
  /// Default is 20 turns.
  ///
  /// ```dart
  /// // Single-turn (no history)
  /// final response = await engine.send(userMessage: 'What is Flutter?');
  ///
  /// // Multi-turn (with history)
  /// final response = await engine.send(
  ///   userMessage: 'What is my name?',
  ///   history: [
  ///     ChatMessage.user('My name is Mohamed.'),
  ///     ChatMessage.model('Nice to meet you, Mohamed!'),
  ///   ],
  /// );
  /// ```
  ///
  /// Throws [EngineException] on API or network errors.
  /// Throws [ConfigException] if [config] is the wrong type for this engine.
  Future<AiResponse> send({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  });

  /// Sends a message and returns the response as a word-by-word [Stream].
  ///
  /// Each emitted string is a small chunk of the response as it is generated.
  /// Use this for typing-effect UIs so the user sees output immediately
  /// instead of waiting for the full response.
  ///
  /// [userMessage] — the message from the end user.
  /// [config] — optional per-call override. Only the fields you set will
  /// replace the engine's defaults; everything else stays the same.
  /// [history] — optional list of previous [ChatMessage]s. Same as in [send].
  /// [maxHistoryMessages] — caps history length to control token usage.
  /// Default is 20 turns.
  ///
  /// ```dart
  /// engine.stream(
  ///   userMessage: 'Continue the story.',
  ///   history: previousTurns,
  /// ).listen((chunk) {
  ///   setState(() => text += chunk);
  /// });
  /// ```
  ///
  /// Throws [EngineException] on API or network errors.
  /// Throws [ConfigException] if [config] is the wrong type for this engine.
  Stream<String> stream({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  });

  /// Returns the token count for the given message under the given config.
  ///
  /// Use this before sending to estimate cost or check if the message fits
  /// within the model's context window.
  ///
  /// [userMessage] — the message to count tokens for.
  /// [config] — optional override, same as in [send].
  ///
  /// ```dart
  /// final tokens = await engine.countTokens(userMessage: 'Hello world');
  /// if (tokens > 8000) print('Message is too long');
  /// ```
  ///
  /// Some engines (e.g. [GeminiEngine]) call the provider's real token-count
  /// API for accuracy. Others fall back to a rough estimate (1 token ≈ 4 chars).
  Future<int> countTokens({
    required String userMessage,
    AiConfig? config,
  });

  /// Returns `true` if the engine can reach its provider right now.
  ///
  /// For cloud engines this checks network reachability and API key validity.
  /// For local engines this checks whether the required binary or model file
  /// is present on the device.
  ///
  /// Returns `false` on any error — never throws.
  ///
  /// ```dart
  /// if (!await engine.isAvailable()) {
  ///   showDialog(context, 'AI is currently unavailable. Check your connection.');
  /// }
  /// ```
  Future<bool> isAvailable();

  /// Validates the engine's configuration at startup.
  ///
  /// Called automatically by the engine constructor. Throw [ConfigException]
  /// with a clear message if something is wrong — missing API key, invalid
  /// model name, etc.
  ///
  /// ```dart
  /// @override
  /// void validate() {
  ///   if (_apiKey.isEmpty) throw ConfigException('API key cannot be empty');
  /// }
  /// ```
  void validate();

  /// Releases any resources held by this engine.
  ///
  /// Call this when the engine is no longer needed — for example in a widget's
  /// `dispose()` or when switching providers. Closes HTTP clients, WebSocket
  /// connections, or any other open handles.
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   _httpClient.close();
  /// }
  /// ```
  void dispose();
}
