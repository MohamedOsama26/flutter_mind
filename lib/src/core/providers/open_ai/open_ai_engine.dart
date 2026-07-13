import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_mind/src/core/shared/ai_config.dart';
import 'package:flutter_mind/src/core/shared/chat_message.dart';
import 'package:flutter_mind/src/core/shared/retry_config.dart';
import 'package:flutter_mind/src/core/shared/ai_engine.dart';
import 'package:flutter_mind/src/core/exceptions/flutter_mind_exception.dart';
import 'package:flutter_mind/src/core/shared/ai_model.dart';
import 'package:flutter_mind/src/ai_request.dart';
import 'package:flutter_mind/src/ai_response.dart';

part 'open_ai_error_handler.dart';
part 'open_ai_rate_limit_info.dart';

/// AI engine for OpenAI models via the Responses API.
///
/// ```dart
/// // Minimal setup — smart defaults applied automatically
/// final openai = OpenAiEngine(apiKey: 'sk-...');
///
/// // Full setup
/// final openai = OpenAiEngine(
///   apiKey: 'sk-...',
///   config: OpenAiConfig(
///     model: OpenAiModel.gpt55,
///     systemPrompt: Prompt(role: 'helpful assistant'),
///     temperature: 0.7,
///   ),
///   timeout: Duration(seconds: 60),
///   retry: RetryConfig(maxAttempts: 3),
/// );
///
/// // Send a single message
/// final response = await openai.send(userMessage: 'hello');
/// print(response.text);
///
/// // Stream a message chunk by chunk
/// openai.stream(userMessage: 'tell me a story').listen((chunk) {
///   print(chunk);
/// });
///
/// // Multi-turn conversation
/// final history = <ChatMessage>[];
/// final r1 = await openai.send(userMessage: 'My name is Mohamed.');
/// history.add(ChatMessage.user('My name is Mohamed.'));
/// history.add(ChatMessage.model(r1.text));
/// final r2 = await openai.send(userMessage: 'What is my name?', history: history);
///
/// // Override config for a single call only
/// final response = await openai.send(
///   userMessage: 'solve this hard problem',
///   config: OpenAiConfig(
///     model: OpenAiModel.gpt55,
///     reasoningEffort: ReasoningEffort.high,
///   ),
/// );
/// ```
///
/// Always call [dispose] when the engine is no longer needed to close
/// the underlying HTTP client and free resources.
///
/// **API reference:** https://platform.openai.com/docs/api-reference/responses
class OpenAiEngine implements AiEngine {
  /// Creates an OpenAI engine.
  ///
  /// [apiKey] is required — get yours at https://platform.openai.com/api-keys
  ///
  /// [config] is optional — smart defaults are applied for any unset field.
  /// If skipped, the engine uses [OpenAiModel.gpt54Mini] with `temperature: 0.7`.
  ///
  /// [timeout] is the max time to wait for a response. Defaults to 30 seconds.
  /// Increase this for reasoning models or long responses.
  ///
  /// [retry] controls automatic retry on server errors. Defaults to 2 attempts
  /// on status codes 429, 500, and 503. Use [RetryConfig.none] to disable.
  OpenAiEngine({
    required String apiKey,
    String? organizationId,
    String? projectId,
    OpenAiConfig? config,
    Duration timeout = const Duration(seconds: 30),
    RetryConfig retry = const RetryConfig(),
  }) : _apiKey = apiKey,
       _timeout = timeout,
       _retry = retry,
       _defaultConfig = _resolveSmartDefaults(config),
       _dio = Dio(
         BaseOptions(
           baseUrl: 'https://api.openai.com/v1/',
           headers: {
             'Authorization': 'Bearer $apiKey',
             'Content-Type': 'application/json',
             'OpenAI-Organization': ?organizationId,
             'OpenAI-Project': ?projectId,
           },
           sendTimeout: timeout,
           receiveTimeout: timeout,
         ),
       ) {
    validate();
  }

  final String _apiKey;
  final Duration _timeout;
  final RetryConfig _retry;
  final OpenAiConfig _defaultConfig;
  final Dio _dio;
  late final _errors = _OpenAiErrorHandler(
    timeoutSeconds: _timeout.inSeconds,
    modelValue: _defaultConfig.model!.value,
  );

  OpenAiRateLimitInfo? _rateLimitInfo;

  /// Rate limit information from the last API response.
  ///
  /// Updated automatically after every [send], [stream], and [getModels] call.
  /// `null` until the first successful request completes.
  ///
  /// ```dart
  /// final response = await openai.send(userMessage: 'hello');
  /// final info = openai.rateLimitInfo;
  /// print('${info?.remainingTokens} tokens left');
  /// ```
  OpenAiRateLimitInfo? get rateLimitInfo => _rateLimitInfo;

  /// The resolved default config for this engine instance.
  ///
  /// Reflects smart defaults applied at construction time.
  /// Useful for inspecting what the engine will use when no per-call config
  /// is provided.
  OpenAiConfig get defaultConfig => _defaultConfig;

  /// The model this engine uses by default.
  @override
  AiModel get model => _defaultConfig.model!;

  /// Sends a message and returns the complete [AiResponse].
  ///
  /// [config] — optional per-call override. Only the fields you set replace
  /// the engine defaults; everything else stays the same.
  ///
  /// [history] — optional list of previous [ChatMessage]s, oldest first.
  ///
  /// [maxHistoryMessages] — caps how many history messages are sent.
  /// Default: 20.
  ///
  /// Throws [EngineException] on API or network errors.
  /// Throws [ConfigException] if [config] is not an [OpenAiConfig].
  @override
  Future<AiResponse> send({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) async {
    final resolved = _mergeConfig(config);
    final request = AiRequest(
      userMessage: userMessage,
      config: resolved,
      history: history,
      maxHistoryMessages: maxHistoryMessages,
    );
    return _sendWithRetry(request);
  }

  /// Sends a message and returns the response as a [Stream] of text chunks.
  ///
  /// [config], [history], and [maxHistoryMessages] behave exactly as in [send].
  ///
  /// Throws [EngineException] on API or network errors.
  /// Throws [ConfigException] if [config] is not an [OpenAiConfig].
  @override
  Stream<String> stream({
    required String userMessage,
    AiConfig? config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) {
    final resolved = _mergeConfig(config);
    final request = AiRequest(
      userMessage: userMessage,
      config: resolved,
      history: history,
      maxHistoryMessages: maxHistoryMessages,
    );
    return _streamRequest(request);
  }

  /// Returns the token count for the given message under the current config.
  ///
  /// Calls OpenAI's `POST /v1/responses/input_tokens` using the same request
  /// body as [send] — so instructions and formatting all count toward the
  /// total, giving you an accurate number.
  ///
  /// **Unlike Gemini's `countTokens`, this call is NOT free** — it consumes
  /// API quota the same way a regular request does. Use it when accuracy
  /// matters; use [estimateTokens] for a free rough estimate instead.
  ///
  /// Falls back to a rough estimate (1 token ≈ 4 chars) if the API call fails.
  @override
  Future<int> countTokens({
    required String userMessage,
    AiConfig? config,
  }) async {
    final resolved = _mergeConfig(config);
    try {
      final body = _buildRequestBody(
        userMessage: userMessage,
        config: resolved,
        stream: false,
      );
      final response = await _dio.post('responses/input_tokens', data: body);
      return response.data['input_tokens'] as int? ?? 0;
    } catch (_) {
      final systemLength =
          resolved.systemPrompt?.build(userMessage: userMessage).length ?? 0;
      return ((userMessage.length + systemLength) / 4).ceil();
    }
  }

  /// Checks if the OpenAI API is reachable with the current API key.
  ///
  /// Returns `true` if the API responds successfully.
  /// Returns `false` on network errors or invalid API key — never throws.
  @override
  Future<bool> isAvailable() async {
    try {
      await _dio.get(
        'models/${_defaultConfig.model!.value}',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validates engine configuration at init time.
  ///
  /// Called automatically in the constructor.
  /// Throws [ConfigException] if configuration is invalid.
  @override
  void validate() {
    if (_apiKey.isEmpty) {
      throw const ConfigException(
        'OpenAiEngine: apiKey cannot be empty. '
        'Get your API key at https://platform.openai.com/api-keys',
      );
    }
    if (_apiKey.contains(' ')) {
      throw const ConfigException(
        'OpenAiEngine: apiKey appears invalid — contains spaces.',
      );
    }
  }

  /// Releases resources held by this engine.
  ///
  /// Call when the engine is no longer needed to close the HTTP client.
  @override
  void dispose() => _dio.close();

  /// Lists all models available to the current API key.
  ///
  /// Calls `GET /v1/models`. Returns an unfiltered list that includes all model
  /// types (text, image, realtime, etc.). Filter by `id` or `owned_by` as needed.
  @override
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      final response = await _dio.get('models');
      _rateLimitInfo = OpenAiRateLimitInfo.fromHeaders(response.headers);
      final models = response.data['data'] as List<dynamic>;
      return models.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _errors.handle(e);
    }
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  OpenAiConfig _mergeConfig(AiConfig? override) {
    if (override == null) return _defaultConfig;
    if (override is! OpenAiConfig) {
      throw ConfigException(
        'OpenAiEngine received ${override.runtimeType} — '
        'expected OpenAiConfig. Use the matching engine for other providers.',
      );
    }
    return _defaultConfig.copyWith(
      model: override.model,
      systemPrompt: override.systemPrompt,
      temperature: override.temperature,
      maxOutputTokens: override.maxOutputTokens,
      stopSequences: override.stopSequences,
      topP: override.topP,
      reasoningEffort: override.reasoningEffort,
      responseFormat: override.responseFormat,
      topLogprobs: override.topLogprobs,
      parallelToolCalls: override.parallelToolCalls,
      seed: override.seed,
    );
  }

  static OpenAiConfig _resolveSmartDefaults(OpenAiConfig? config) {
    if (config == null) {
      return const OpenAiConfig(
        model: OpenAiModel.gpt54Mini,
        temperature: 0.7,
      );
    }

    return OpenAiConfig(
      model: config.model ?? OpenAiModel.gpt54Mini,
      systemPrompt: config.systemPrompt,
      temperature:
          config.temperature ??
          (config.reasoningEffort != null
              ? 0.3 // reasoning models work better with lower temp
              : 0.7),
      maxOutputTokens: config.maxOutputTokens,
      stopSequences: config.stopSequences,
      topP: config.topP,
      reasoningEffort: config.reasoningEffort,
      responseFormat: config.responseFormat,
      topLogprobs: config.topLogprobs,
      parallelToolCalls: config.parallelToolCalls,
      seed: config.seed,
    );
  }

  Future<AiResponse> _sendWithRetry(AiRequest request) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _sendRequest(request);
      } on EngineException catch (e) {
        final shouldRetry =
            e.statusCode != null &&
            _retry.shouldRetry(e.statusCode!) &&
            attempt < _retry.maxAttempts;

        if (!shouldRetry) rethrow;

        await Future.delayed(_retry.delay);
      }
    }
  }

  Future<AiResponse> _sendRequest(AiRequest request) async {
    final config = request.config as OpenAiConfig;

    try {
      final response = await _dio.post(
        'responses',
        data: _buildRequestBody(
          userMessage: request.userMessage,
          config: config,
          history: request.history,
          maxHistoryMessages: request.maxHistoryMessages,
          stream: false,
        ),
      );
      _rateLimitInfo = OpenAiRateLimitInfo.fromHeaders(response.headers);
      return _parseResponse(response.data, config.model!);
    } on DioException catch (e) {
      throw _errors.handle(e);
    }
  }

  Stream<String> _streamRequest(AiRequest request) async* {
    final config = request.config as OpenAiConfig;

    try {
      final response = await _dio.post<ResponseBody>(
        'responses',
        data: _buildRequestBody(
          userMessage: request.userMessage,
          config: config,
          history: request.history,
          maxHistoryMessages: request.maxHistoryMessages,
          stream: true,
        ),
        options: Options(responseType: ResponseType.stream),
      );
      _rateLimitInfo = OpenAiRateLimitInfo.fromHeaders(response.headers);

      final lines = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final jsonStr = line.substring(6).trim();
        if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final type = json['type'] as String?;

          // Only delta events carry text chunks
          if (type == 'response.output_text.delta') {
            final delta = json['delta'] as String?;
            if (delta != null && delta.isNotEmpty) yield delta;
          }
        } catch (_) {
          continue;
        }
      }
    } on DioException catch (e) {
      throw _errors.handle(e);
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required String userMessage,
    required OpenAiConfig config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
    required bool stream,
  }) {
    final trimmed = history == null || history.isEmpty
        ? const <ChatMessage>[]
        : history.length > maxHistoryMessages
        ? history.sublist(history.length - maxHistoryMessages)
        : history;

    // Build input: history items + current user message
    final input = [
      for (final msg in trimmed)
        {
          'role': msg.role,
          'content': msg.text,
        },
      {
        'role': 'user',
        'content': userMessage,
      },
    ];

    final body = <String, dynamic>{
      'model': config.model!.value,
      'input': input,
      'stream': stream,
    };

    // System prompt → `instructions`
    if (config.systemPrompt != null) {
      body['instructions'] =
          config.systemPrompt!.build(userMessage: userMessage);
    }

    if (config.temperature != null) body['temperature'] = config.temperature;
    if (config.maxOutputTokens != null) {
      body['max_output_tokens'] = config.maxOutputTokens;
    }
    if (config.topP != null) body['top_p'] = config.topP;
    if (config.seed != null) body['seed'] = config.seed;
    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      body['stop'] = config.stopSequences;
    }
    if (config.reasoningEffort != null) {
      body['reasoning'] = {'effort': config.reasoningEffort!.name};
    }
    if (config.responseFormat != null) {
      body['text'] = {'format': config.responseFormat!.toJson()};
    }
    if (config.topLogprobs != null) {
      body['top_logprobs'] = config.topLogprobs;
    }
    if (config.parallelToolCalls != null) {
      body['parallel_tool_calls'] = config.parallelToolCalls;
    }

    return body;
  }

  AiResponse _parseResponse(Map<String, dynamic> json, AiModel model) {
    final output = json['output'] as List<dynamic>?;
    if (output == null || output.isEmpty) {
      throw const EngineException(
        'OpenAiEngine: response has no output items.',
      );
    }

    // Find the first message item with content
    String text = '';
    String? finishReason;

    for (final item in output) {
      final map = item as Map<String, dynamic>;
      if (map['type'] != 'message') continue;

      finishReason = map['status'] as String?;
      final content = map['content'] as List<dynamic>?;
      if (content == null) continue;

      for (final part in content) {
        final p = part as Map<String, dynamic>;
        if (p['type'] == 'output_text') {
          text += (p['text'] as String? ?? '');
        }
      }
      break; // first message item is the answer
    }

    final usage = json['usage'] as Map<String, dynamic>?;
    final inputTokens = usage?['input_tokens'] as int?;
    final outputTokens = usage?['output_tokens'] as int?;

    return AiResponse(
      text: text,
      model: model,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      finishReason: finishReason,
    );
  }

}
