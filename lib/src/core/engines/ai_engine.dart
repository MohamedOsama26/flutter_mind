import '../models/ai_model.dart';

/// Abstract contract that every AI engine must implement.
///
/// flutter_mind ships three built-in engines:
/// - `GeminiEngine` — Google Gemini
/// - `OpenAiEngine` — OpenAI GPT
/// - `ClaudeEngine` — Anthropic Claude
///
/// To connect any other model (Ollama, HuggingFace, local, etc.),
/// implement this interface:
///
/// ```dart
/// class OllamaEngine implements AiEngine {
///   const OllamaEngine({
///     required this.baseUrl,
///     this.model = const CustomModel('llama3.2'),
///   });
///
///   final String baseUrl;
///
///   @override
///   final AiModel model;
///
///   @override
///   Future<String> send(String systemPrompt, String userMessage) async {
///     // your HTTP call here
///   }
///
///   @override
///   Stream<String> stream(String systemPrompt, String userMessage) async* {
///     // your streaming logic here
///   }
/// }
/// ```
abstract interface class AiEngine {
  /// The model this engine will use.
  AiModel get model;

  /// Sends a single request and returns the full response as a [String].
  ///
  /// [systemPrompt] — the engineered system context built by flutter_mind.
  /// [userMessage]  — the raw or enriched message from the end user.
  ///
  /// Throws [EngineException] on API errors.
  Future<String> send({
    required String systemPrompt,
    required String userMessage,
  });

  /// Sends a request and returns the response as a word-by-word [Stream].
  ///
  /// Use this for typing-effect UIs.
  ///
  /// [systemPrompt] — the engineered system context built by flutter_mind.
  /// [userMessage]  — the raw or enriched message from the end user.
  ///
  /// Throws [EngineException] on API errors.
  Stream<String> stream({
    required String systemPrompt,
    required String userMessage,
  });

  /// Optional: checks if the engine is available in the current environment.
  /// For example, a local engine might check if the required binary is installed,
  /// or if the HuggingFace API is reachable.
  Future<bool> isAvailable();

  /// Optional: validates engine-specific config at init time.
  ///
  /// Called by [FlutterMindClient.init()] automatically.
  /// Override to add custom startup checks.
  /// Throw [ConfigException] with a clear message if something is wrong.
  void validate();
  
  /// Optional: performs any cleanup when the engine is disposed.
  /// For example, closing HTTP clients, WebSocket connections, etc.
  Future<void> dispose();
}
