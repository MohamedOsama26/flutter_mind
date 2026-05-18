import 'package:flutter_mind/src/core/configs/ai_config.dart';
import 'package:flutter_mind/src/core/engines/ai_engine.dart';
import 'package:flutter_mind/src/core/models/chat_message.dart';
import 'package:flutter_mind/src/ai_response.dart';
import 'package:flutter_mind/src/core/validators/input_validator.dart';

/// A function that enriches the user message before it is sent to the engine.
///
/// Receives the raw user message and returns an enriched version.
/// Use to inject runtime context like location, user profile, or app state.
///
/// ```dart
/// FlutterMindClient(
///   engine: gemini,
///   beforeSend: (message) async {
///     final location = await LocationService.current();
///     return '$message — user location: $location';
///   },
/// );
/// ```
typedef BeforeSendHook = Future<String> Function(String userMessage);

/// The main entry point for flutter_mind.
///
/// Orchestrates the full request pipeline:
/// validate → beforeSend hook → build request → engine → response.
///
/// ## Simple setup
/// ```dart
/// final ai = FlutterMindClient(
///   engine: GeminiEngine(apiKey: 'AIza...'),
/// );
///
/// final response = await ai.send(userMessage: 'suggest a game');
/// print(response.text);
/// ```
///
/// ## With config
/// ```dart
/// final ai = FlutterMindClient(
///   engine: GeminiEngine(
///     apiKey: 'AIza...',
///     defaultConfig: GeminiConfig(
///       model: GeminiModel.pro25,
///       systemPrompt: 'You are a game suggestion assistant.',
///       temperature: 0.8,
///     ),
///   ),
/// );
/// ```
///
/// ## With beforeSend hook
/// ```dart
/// final ai = FlutterMindClient(
///   engine: GeminiEngine(apiKey: 'AIza...'),
///   beforeSend: (message) async {
///     final location = await LocationService.current();
///     return '$message — user is in $location';
///   },
/// );
/// ```
///
/// ## Singleton usage
/// ```dart
/// // Set once at app startup
/// FlutterMindClient.init(
///   engine: GeminiEngine(apiKey: 'AIza...'),
/// );
///
/// // Use anywhere in the app
/// FlutterMindClient.instance.send(userMessage: 'hello');
/// ```
class FlutterMindClient {
  /// Creates a [FlutterMindClient] instance.
  ///
  /// [engine] is required — the AI engine to use for all requests.
  ///
  /// [beforeSend] is optional — enrich user message before sending.
  ///
  /// [validator] is optional — custom input validation rules.
  /// Defaults to standard validation (non-empty, max 50,000 chars).
  FlutterMindClient({
    required AiEngine engine,
    BeforeSendHook? beforeSend,
    InputValidator validator = const InputValidator(),
  })  : _engine = engine,
        _beforeSend = beforeSend,
        _validator = validator;

  // SINGLETON
  static FlutterMindClient? _instance;

  /// The global singleton instance.
  ///
  /// Must call [init] before accessing this.
  /// Throws [StateError] if accessed before [init].
  static FlutterMindClient get instance {
    if (_instance == null) {
      throw StateError(
        'FlutterMindClient is not initialized. '
        'Call FlutterMindClient.init() before using FlutterMindClient.instance.',
      );
    }
    return _instance!;
  }

  /// Initializes the global singleton instance.
  ///
  /// Call once at app startup — typically in `main()` before `runApp()`.
  ///
  /// ```dart
  /// void main() async {
  ///   FlutterMindClient.init(
  ///     engine: GeminiEngine(apiKey: 'AIza...'),
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  static void init({
    required AiEngine engine,
    BeforeSendHook? beforeSend,
    InputValidator validator = const InputValidator(),
  }) {
    _instance = FlutterMindClient(
      engine: engine,
      beforeSend: beforeSend,
      validator: validator,
    );
  }

  /// Disposes the singleton instance and releases its resources.
  static void dispose() {
    _instance?._engine.dispose();
    _instance = null;
  }

  // PRIVATE FIELDS
  final AiEngine _engine;
  final BeforeSendHook? _beforeSend;
  final InputValidator _validator;

  // PUBLIC API
  /// Sends a message and returns the full response.
  ///
  /// Pipeline: validate → beforeSend → engine → response
  ///
  /// [userMessage] — the message from the end user.
  ///
  /// [config] — optional per-call config override. Only fields you set
  /// override the engine's default — rest use defaults.
  ///
  /// [history] — optional conversation history for multi-turn chat.
  /// Package never stores history — developer manages their own state.
  ///
  /// [maxHistoryMessages] — limits how many history turns are sent.
  /// Older turns are dropped first. Default: 20.
  /// Lower this to save tokens on long conversations.
  ///
  /// Throws [ValidationException] if message is invalid.
  /// Throws [EngineException] on API errors.
  ///
  /// ```dart
  /// // Simple
  /// final response = await ai.send(userMessage: 'suggest a game');
  ///
  /// // With history
  /// final response = await ai.send(
  ///   userMessage: 'what is my name',
  ///   history: [
  ///     ChatMessage.user('call me osama'),
  ///     ChatMessage.model('Sure! I will call you Osama.'),
  ///   ],
  /// );
  ///
  /// // With config override
  /// final response = await ai.send(
  ///   userMessage: 'solve this',
  ///   config: GeminiConfig(model: GeminiModel.pro25),
  /// );
  /// ```
  Future<AiResponse> send({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) async {
    final message = await _prepare(userMessage);
    return _engine.send(
      userMessage: message,
      config: config,
      history: history,
      maxHistoryMessages: maxHistoryMessages,
    );
  }

  /// Streams the response word by word as it is generated.
  ///
  /// Use for typing-effect UIs — user sees text appearing immediately
  /// instead of waiting for the full response.
  ///
  /// Same parameters as [send].
  ///
  /// ```dart
  /// ai.stream(userMessage: 'tell me a story').listen((chunk) {
  ///   setState(() => displayText += chunk);
  /// });
  /// ```
  Stream<String> stream({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) async* {
    final message = await _prepare(userMessage);
    yield* _engine.stream(
      userMessage: message,
      config: config,
      history: history,
      maxHistoryMessages: maxHistoryMessages,
    );
  }

  /// Returns the estimated token count for the given message.
  ///
  /// Uses the engine's real token counting API when available.
  /// Falls back to rough estimation (1 token ≈ 4 characters).
  ///
  /// Use before sending long messages to check cost upfront.
  ///
  /// ```dart
  /// final tokens = await ai.countTokens(userMessage: longText);
  /// print('Estimated cost: $tokens tokens');
  /// ```
  Future<int> countTokens({
    required String userMessage,
    AiConfig? config,
  }) async {
    _validator.validate(userMessage);
    return _engine.countTokens(
      userMessage: userMessage,
      config: config,
    );
  }

  /// Checks if the AI engine is reachable.
  ///
  /// Returns `true` if the engine responds successfully.
  /// Use before sending to show a friendly error instead of a timeout.
  ///
  /// ```dart
  /// if (!await ai.isAvailable()) {
  ///   showError('AI service is currently unavailable');
  ///   return;
  /// }
  /// ```
  Future<bool> isAvailable() => _engine.isAvailable();

  /// Estimates token count without calling the API.
  ///
  /// Rough estimate only — 1 token ≈ 4 characters.
  /// Use [countTokens] for accurate count.
  int estimateTokens(String message) => _validator.estimateTokens(message);


  /// Validates and enriches the user message before sending.
  ///
  /// 1. Validates input — throws [ValidationException] if invalid
  /// 2. Runs beforeSend hook — enriches message with runtime context
  Future<String> _prepare(String userMessage) async {
    // Step 1 — validate
    _validator.validate(userMessage);

    // Step 2 — beforeSend hook
    if (_beforeSend != null) {
      return await _beforeSend(userMessage);
    }

    return userMessage;
  }
}