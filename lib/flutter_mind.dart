// PUBLIC API EXPORTS
export 'src/flutter_mind_client.dart';
export 'src/ai_response.dart';
export 'src/ai_request.dart';
export 'src/core/engines/ai_engine.dart';
export 'src/core/engines/gemini_engine.dart';
export 'src/core/engines/local_engine.dart';
export 'src/core/configs/ai_config.dart';
export 'src/core/configs/retry_config.dart';
export 'src/core/models/ai_model.dart';
export 'src/core/models/capability.dart';
export 'src/core/models/chat_message.dart';
export 'src/core/models/thinking_budget.dart';
export 'src/core/exceptions/flutter_mind_exception.dart';
export 'src/core/validators/input_validator.dart';
export 'src/core/parser/prompt_config.dart';
export 'src/core/parser/prompt_example.dart';
export 'src/core/parser/response_format.dart';
export 'src/core/parser/response_language.dart';
export 'src/core/parser/response_tone.dart';
export 'src/core/parser/stop_signal_mode.dart';
export 'src/core/parser/ai_preset.dart';
export 'src/core/parser/message_analyzer.dart';
export 'src/core/events/local_engine_event.dart';

import 'package:flutter_mind/src/core/configs/ai_config.dart';
import 'package:flutter_mind/src/core/engines/ai_engine.dart';
import 'package:flutter_mind/src/core/models/chat_message.dart';
import 'package:flutter_mind/src/ai_response.dart';
import 'package:flutter_mind/src/flutter_mind_client.dart';
import 'package:flutter_mind/src/core/validators/input_validator.dart';

/// The main entry point for flutter_mind.
///
/// Use [FlutterMind] for the simple case — one AI engine across the whole app.
/// Set up once in `main()`, then call from anywhere without passing anything around.
///
/// For multiple engines in the same app, create [FlutterMindClient] instances
/// directly instead.
///
/// ## Setup — call once in main()
///
/// ```dart
/// void main() {
///   FlutterMind.init(
///     engine: GeminiEngine(
///       apiKey: 'AIza...',
///       config: GeminiConfig(
///         model: GeminiModel.flash25,
///         systemPrompt: Prompt(role: 'helpful assistant'),
///       ),
///     ),
///   );
///   runApp(MyApp());
/// }
/// ```
///
/// ## Use anywhere in the app — no imports, no passing around
///
/// ```dart
/// // Send a message
/// final response = await FlutterMind.send(userMessage: 'suggest a game');
/// print(response.text);
///
/// // Stream a message
/// FlutterMind.stream(userMessage: 'tell me a story').listen((chunk) {
///   setState(() => text += chunk);
/// });
///
/// // Multi-turn conversation
/// final response = await FlutterMind.send(
///   userMessage: 'what is my name?',
///   history: [
///     ChatMessage.user('my name is Ali'),
///     ChatMessage.model('Nice to meet you, Ali!'),
///   ],
/// );
/// ```
///
/// ## Multiple engines — use FlutterMindClient directly
///
/// ```dart
/// final chatClient    = FlutterMindClient(engine: GeminiEngine(apiKey: '...'));
/// final summaryClient = FlutterMindClient(engine: GeminiEngine(
///   apiKey: '...',
///   config: GeminiConfig(model: GeminiModel.pro25),
/// ));
///
/// await chatClient.send(userMessage: 'hello');
/// await summaryClient.send(userMessage: 'summarize this article...');
/// ```
abstract final class FlutterMind {

  /// Initializes the global AI engine.
  ///
  /// Call once in `main()` before `runApp()`.
  /// After this, use [send], [stream], and other methods from anywhere.
  ///
  /// [engine] — the AI engine to use. Example: [GeminiEngine].
  ///
  /// [beforeSend] — optional hook to enrich the message before it is sent.
  /// Useful for injecting user context, location, or app state.
  ///
  /// [validator] — optional custom validation rules.
  /// Defaults to: non-empty, max 50,000 characters.
  ///
  /// ```dart
  /// FlutterMind.init(
  ///   engine: GeminiEngine(apiKey: 'AIza...'),
  ///   beforeSend: (message) async {
  ///     final user = await Auth.currentUser();
  ///     return '$message — user: ${user.name}';
  ///   },
  /// );
  /// ```
  static void init({
    required AiEngine engine,
    BeforeSendHook? beforeSend,
    InputValidator validator = const InputValidator(),
  }) {
    FlutterMindClient.init(
      engine: engine,
      beforeSend: beforeSend,
      validator: validator,
    );
  }

  /// Releases all resources and resets the global instance.
  ///
  /// Call when the app closes or when switching engines.
  /// After dispose, [init] must be called again before using any method.
  static void dispose() => FlutterMindClient.dispose();


  /// Sends a message and returns the complete [AiResponse].
  ///
  /// Waits for the full response before returning. Use [stream] instead
  /// for typing-effect UIs.
  ///
  /// [history] — optional previous turns for multi-turn conversation.
  /// [maxHistoryMessages] — limits how many turns are sent. Default: 20.
  ///
  /// Throws [ValidationException] if the message is empty or too long.
  /// Throws [EngineException] on API or network errors.
  ///
  /// ```dart
  /// final response = await FlutterMind.send(userMessage: 'hello');
  /// print(response.text);
  /// print(response.totalTokens);
  /// ```
  static Future<AiResponse> send({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) =>
      FlutterMindClient.instance.send(
        userMessage: userMessage,
        config: config,
        history: history,
        maxHistoryMessages: maxHistoryMessages,
      );

  /// Sends a message and returns the response as a stream of text chunks.
  ///
  /// Each chunk is a small piece of the response as the model generates it.
  /// Use for typing-effect UIs so the user sees output immediately.
  ///
  /// ```dart
  /// FlutterMind.stream(userMessage: 'tell me a story').listen((chunk) {
  ///   setState(() => text += chunk);
  /// });
  /// ```
  ///
  /// Throws [ValidationException] if the message is empty or too long.
  /// Throws [EngineException] on API or network errors.
  static Stream<String> stream({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) =>
      FlutterMindClient.instance.stream(
        userMessage: userMessage,
        config: config,
        history: history,
        maxHistoryMessages: maxHistoryMessages,
      );

  /// Returns the accurate token count for the given message.
  ///
  /// Calls the engine's real token-count API — always free, no tokens spent.
  ///
  /// ```dart
  /// final tokens = await FlutterMind.countTokens(userMessage: longText);
  /// if (tokens > 100000) print('Message too long');
  /// ```
  static Future<int> countTokens({
    required String userMessage,
    AiConfig? config,
  }) =>
      FlutterMindClient.instance.countTokens(
        userMessage: userMessage,
        config: config,
      );

  /// Returns a rough token estimate without calling the API.
  ///
  /// 1 token ≈ 4 characters in English. Arabic may be 2–3× higher.
  /// Use [countTokens] for accuracy.
  ///
  /// ```dart
  /// final estimate = FlutterMind.estimateTokens('عامل إيه النهارده؟');
  /// ```
  static int estimateTokens(String message) =>
      FlutterMindClient.instance.estimateTokens(message);

  /// Returns `true` if the AI engine is reachable right now.
  ///
  /// ```dart
  /// if (!await FlutterMind.isAvailable()) {
  ///   showError('AI is currently unavailable');
  /// }
  /// ```
  static Future<bool> isAvailable() =>
      FlutterMindClient.instance.isAvailable();
}
