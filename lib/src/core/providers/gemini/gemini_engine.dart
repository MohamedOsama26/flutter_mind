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

/// AI engine for Google Gemini models.
///
/// ```dart
/// // Minimal setup — smart defaults applied automatically
/// final gemini = GeminiEngine(apiKey: 'AIza...');
///
/// // Full setup
/// final gemini = GeminiEngine(
///   apiKey: 'AIza...',
///   config: GeminiConfig(
///     model: GeminiModel.pro25,
///     systemPrompt: Prompt(role: 'helpful assistant'),
///     temperature: 0.7,
///   ),
///   timeout: Duration(seconds: 60),
///   retry: RetryConfig(maxAttempts: 3),
/// );
///
/// // Send a single message
/// final response = await gemini.send(userMessage: 'hello');
/// print(response.text);
///
/// // Stream a message chunk by chunk
/// gemini.stream(userMessage: 'tell me a story').listen((chunk) {
///   print(chunk); // prints as the model generates
/// });
///
/// // Multi-turn conversation
/// final history = <ChatMessage>[];
/// final r1 = await gemini.send(userMessage: 'My name is Mohamed.');
/// history.add(ChatMessage.user('My name is Mohamed.'));
/// history.add(ChatMessage.model(r1.text));
/// final r2 = await gemini.send(userMessage: 'What is my name?', history: history);
///
/// // Override config for a single call only
/// final response = await gemini.send(
///   userMessage: 'solve this hard problem',
///   config: GeminiConfig(
///     model: GeminiModel.pro25,
///     thinkingLevel: ThinkingLevel.deep,
///   ),
/// );
/// ```
///
/// Always call [dispose] when the engine is no longer needed to close
/// the underlying HTTP client and free resources.
///
/// **API reference:** https://ai.google.dev/api/generate-content
class GeminiEngine implements AiEngine {
  /// Creates a Gemini engine.
  ///
  /// [apiKey] is required — get yours at https://aistudio.google.com/apikey
  ///
  /// [config] is optional — smart defaults are applied automatically for any
  /// field you leave unset. If you skip it entirely, the engine uses
  /// [GeminiModel.flash25] with `temperature: 0.7`.
  ///
  /// [timeout] is the max time to wait for a response. Defaults to 30 seconds.
  /// Increase this for thinking models or long responses.
  ///
  /// [retry] controls automatic retry on server errors. Defaults to 2 attempts
  /// on status codes 429, 500, and 503. Use [RetryConfig.none] to disable.
  ///
  GeminiEngine({
    required String apiKey,
    GeminiConfig? config,
    Duration timeout = const Duration(seconds: 30),
    RetryConfig retry = const RetryConfig(),
  }) : _apiKey = apiKey,
       _timeout = timeout,
       _retry = retry,
       _defaultConfig = _resolveSmartDefaults(config),
       _dio = Dio(
         BaseOptions(
           baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models/',
           queryParameters: {'key': apiKey},
           headers: {'Content-Type': 'application/json'},
           sendTimeout: timeout,
           receiveTimeout: timeout,
         ),
       ) {
    validate();
  }

  final String _apiKey;
  final Duration _timeout;
  final RetryConfig _retry;
  final GeminiConfig _defaultConfig;
  final Dio _dio;

  /// The model this engine uses by default.
  ///
  /// Set via [config] in the constructor. Falls back to [GeminiModel.flash25]
  /// if no config was provided. Individual calls can override this via their
  /// own `config` parameter.
  @override
  AiModel get model => _defaultConfig.model!;

  /// Sends a message and returns the complete [AiResponse].
  ///
  /// Waits for the full response before returning. Use [stream] instead
  /// for typing-effect UIs where you want output to appear as it is generated.
  ///
  /// [config] — optional per-call override. Only the fields you set replace
  /// the engine defaults; everything else stays the same.
  ///
  /// [history] — optional list of previous [ChatMessage]s to give the model
  /// context of the conversation so far. Pass turns in order, oldest first.
  /// Omit for stateless single-turn requests.
  ///
  /// [maxHistoryMessages] — caps how many history messages are included.
  /// When the list is longer, the oldest messages are dropped automatically
  /// to keep token usage under control. Default: 20.
  ///
  /// ```dart
  /// // Single-turn
  /// final r = await gemini.send(userMessage: 'What is Dart?');
  ///
  /// // Multi-turn
  /// final r = await gemini.send(
  ///   userMessage: 'What did I just ask?',
  ///   history: [ChatMessage.user('What is Dart?'), ChatMessage.model(r.text)],
  /// );
  /// ```
  ///
  /// Throws [EngineException] on API or network errors.
  /// Throws [ConfigException] if [config] is not a [GeminiConfig].
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
  /// Each emitted chunk is a small piece of the response as the model generates
  /// it. Use this for typing-effect UIs so the user sees output immediately
  /// instead of waiting for the full response.
  ///
  /// [config], [history], and [maxHistoryMessages] behave exactly as in [send].
  ///
  /// ```dart
  /// final buffer = StringBuffer();
  /// await gemini.stream(userMessage: 'Tell me a story').forEach((chunk) {
  ///   buffer.write(chunk);
  ///   setState(() => text = buffer.toString());
  /// });
  /// ```
  ///
  /// Throws [EngineException] on API or network errors.
  /// Throws [ConfigException] if [config] is not a [GeminiConfig].
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
  /// **This call is free — it does not consume any tokens.** Gemini counts
  /// tokens without generating a response, so you are never billed for it.
  /// Call it as often as needed before committing to a real [send] or [stream].
  ///
  /// Calls Gemini's real `countTokens` API for an accurate result.
  /// If that call fails for any reason, falls back to a rough estimate
  /// of 1 token per 4 characters.
  ///
  /// Use this to check if a message fits the model's context window or to
  /// estimate cost before sending:
  ///
  /// ```dart
  /// final tokens = await gemini.countTokens(userMessage: longText);
  ///
  /// if (tokens > 100000) {
  ///   // trim or warn the user — no tokens spent
  /// } else {
  ///   final response = await gemini.send(userMessage: longText);
  /// }
  /// ```
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
      );
      final response = await _dio.post(
        '${resolved.model!.value}:countTokens',
        data: body,
      );
      return response.data['totalTokens'] as int? ?? 0;
    } catch (_) {
      // Fallback — rough estimate: 1 token ≈ 4 characters
      final systemLength =
          resolved.systemPrompt?.build(userMessage: userMessage).length ?? 0;
      return ((userMessage.length + systemLength) / 4).ceil();
    }
  }

  /// Checks if the Gemini API is reachable with the current API key.
  ///
  /// Returns `true` if the API responds successfully.
  /// Returns `false` on network errors or invalid API key.
  @override
  Future<bool> isAvailable() async {
    try {
      await _dio.get(
        _defaultConfig.model!.value,
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
        'GeminiEngine: apiKey cannot be empty. '
        'Get your API key at https://aistudio.google.com/apikey',
      );
    }
    if (_apiKey.contains(' ')) {
      throw const ConfigException(
        'GeminiEngine: apiKey appears invalid — contains spaces.',
      );
    }
  }

  /// Releases resources held by this engine.
  ///
  /// Call when the engine is no longer needed to close the HTTP client.
  @override
  void dispose() => _dio.close();

  /// Merges a per-call config override with the stored default config.
  ///
  /// Only fields explicitly set in [override] replace the defaults.
  /// All other fields fall back to [_defaultConfig].
  GeminiConfig _mergeConfig(AiConfig? override) {
    if (override == null) return _defaultConfig;
    if (override is! GeminiConfig) {
      throw ConfigException(
        'GeminiEngine received ${override.runtimeType} — '
        'expected GeminiConfig. Use the matching engine for other providers.',
      );
    }
    return _defaultConfig.copyWith(
      model: override.model,
      systemPrompt: override.systemPrompt,
      temperature: override.temperature,
      maxOutputTokens: override.maxOutputTokens,
      stopSequences: override.stopSequences,
      topP: override.topP,
      topK: override.topK,
      thinkingLevel: override.thinkingLevel,
      responseMimeType: override.responseMimeType,
      responseSchema: override.responseSchema,
      candidateCount: override.candidateCount,
      seed: override.seed,
      presencePenalty: override.presencePenalty,
      frequencyPenalty: override.frequencyPenalty,
    );
  }

  /// Applies smart defaults based on what the developer configured.
  ///
  /// Runs once at construction — zero cost per request.
  static GeminiConfig _resolveSmartDefaults(GeminiConfig? config) {
    // Developer set nothing — use best defaults for general use
    if (config == null) {
      return const GeminiConfig(model: GeminiModel.flash25, temperature: 0.7);
    }

    final model = config.model;
    final hasThinking = config.thinkingLevel != null;
    final hasStructuredOutput = config.responseMimeType != null;

    return GeminiConfig(
      // Model — fall back to flash25 if not explicitly set
      model: model ?? GeminiModel.flash25,

      // System prompt — keep as is
      systemPrompt: config.systemPrompt,

      // Temperature — smart default based on use case
      temperature:
          config.temperature ??
          (hasThinking
              ? 0.3 // thinking models work better with lower temp
              : hasStructuredOutput
              ? 0.1 // structured output needs deterministic responses
              : 0.7), // general use
      // Rest — keep as is
      maxOutputTokens: config.maxOutputTokens,
      stopSequences: config.stopSequences,
      topP: config.topP,
      topK: config.topK,
      thinkingLevel: config.thinkingLevel,
      responseMimeType: config.responseMimeType,
      responseSchema: config.responseSchema,
      candidateCount: config.candidateCount,
      seed: config.seed,
      presencePenalty: config.presencePenalty,
      frequencyPenalty: config.frequencyPenalty,
    );
  }

  /// Sends a request with automatic retry on safe error codes.
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

  /// Sends a single generateContent request.
  Future<AiResponse> _sendRequest(AiRequest request) async {
    final config = request.config as GeminiConfig;

    try {
      final response = await _dio.post(
        '${config.model!.value}:generateContent',
        data: _buildRequestBody(
          userMessage: request.userMessage,
          config: config,
          history: request.history,
          maxHistoryMessages: request.maxHistoryMessages,
        ),
      );
      return _parseResponse(response.data, config.model!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Streams a streamGenerateContent request.
  Stream<String> _streamRequest(AiRequest request) async* {
    final config = request.config as GeminiConfig;

    try {
      final response = await _dio.post<ResponseBody>(
        '${config.model!.value}:streamGenerateContent',
        data: _buildRequestBody(
          userMessage: request.userMessage,
          config: config,
          history: request.history,
          maxHistoryMessages: request.maxHistoryMessages,
        ),
        options: Options(responseType: ResponseType.stream),
        queryParameters: {'alt': 'sse'},
      );

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        // SSE lines start with 'data: '
        if (!line.startsWith('data: ')) continue;
        final jsonStr = line.substring(6).trim();
        if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final text = _extractTextFromJson(json);
          if (text != null && text.isNotEmpty) yield text;
        } catch (_) {
          continue;
        }
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Builds the JSON request body for generateContent.
  Map<String, dynamic> _buildRequestBody({
    required String userMessage,
    required GeminiConfig config,
    List<ChatMessage>? history,
    int maxHistoryMessages = 20,
  }) {
    final trimmed = history == null || history.isEmpty
        ? const <ChatMessage>[]
        : history.length > maxHistoryMessages
        ? history.sublist(history.length - maxHistoryMessages)
        : history;

    final contents = [
      for (final msg in trimmed)
        {
          'role': msg.role,
          'parts': [
            {'text': msg.text},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      },
    ];

    final body = <String, dynamic>{'contents': contents};

    // System instruction
    if (config.systemPrompt != null) {
      body['systemInstruction'] = {
        'parts': [
          {'text': config.systemPrompt!.build(userMessage: userMessage)},
        ],
      };
    }

    // Generation config — only include non-null values
    final generationConfig = <String, dynamic>{};

    if (config.temperature != null) {
      generationConfig['temperature'] = config.temperature;
    }
    if (config.maxOutputTokens != null) {
      generationConfig['maxOutputTokens'] = config.maxOutputTokens;
    }
    if (config.topP != null) generationConfig['topP'] = config.topP;
    if (config.topK != null) generationConfig['topK'] = config.topK;
    if (config.candidateCount != null) {
      generationConfig['candidateCount'] = config.candidateCount;
    }
    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      generationConfig['stopSequences'] = config.stopSequences;
    }
    if (config.seed != null) generationConfig['seed'] = config.seed;
    if (config.presencePenalty != null) {
      generationConfig['presencePenalty'] = config.presencePenalty;
    }
    if (config.frequencyPenalty != null) {
      generationConfig['frequencyPenalty'] = config.frequencyPenalty;
    }
    if (config.responseMimeType != null) {
      generationConfig['responseMimeType'] = config.responseMimeType;
    }
    if (config.responseSchema != null) {
      generationConfig['responseSchema'] = config.responseSchema;
    }
    if (config.thinkingLevel != null) {
      generationConfig['thinkingConfig'] = {
        'thinkingBudget': config.thinkingLevel!.tokens,
      };
    }

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    return body;
  }

  /// Parses a full generateContent response into [AiResponse].
  AiResponse _parseResponse(Map<String, dynamic> json, AiModel model) {
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const EngineException('GeminiEngine: response has no candidates.');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final finishReason = candidate['finishReason'] as String?;

    String text = '';
    String? thinkingText;

    if (parts != null) {
      for (final part in parts) {
        final p = part as Map<String, dynamic>;
        final isThought = p['thought'] as bool? ?? false;
        final partText = p['text'] as String? ?? '';

        if (isThought) {
          thinkingText = partText;
        } else {
          text += partText;
        }
      }
    }

    // Token usage
    final usage = json['usageMetadata'] as Map<String, dynamic>?;
    final inputTokens = usage?['promptTokenCount'] as int?;
    final outputTokens = usage?['candidatesTokenCount'] as int?;

    return AiResponse(
      text: text,
      model: model,
      thinkingText: thinkingText,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      finishReason: finishReason,
    );
  }

  /// Extracts text from a streaming SSE chunk.
  String? _extractTextFromJson(Map<String, dynamic> json) {
    try {
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final parts =
          (candidates.first as Map<String, dynamic>)['content']?['parts']
              as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;
      return (parts.first as Map<String, dynamic>)['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Converts a [DioException] into a meaningful [EngineException].
  EngineException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final raw = e.response?.data?.toString();

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return EngineException(
        'GeminiEngine: request timed out after ${_timeout.inSeconds}s. '
        'Consider increasing the timeout.',
        statusCode: statusCode,
        raw: raw,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const EngineException(
        'GeminiEngine: no internet connection or server unreachable.',
      );
    }

    return switch (statusCode) {
      400 => EngineException(
        'GeminiEngine: bad request — ${raw ?? 'no details from server'}',
        statusCode: 400,
        raw: raw,
      ),
      401 => EngineException(
        'GeminiEngine: invalid API key. '
        'Check your key at https://aistudio.google.com/apikey',
        statusCode: 401,
        raw: raw,
      ),
      403 => EngineException(
        'GeminiEngine: API key does not have permission for this model.',
        statusCode: 403,
        raw: raw,
      ),
      404 => EngineException(
        'GeminiEngine: model not found — "${_defaultConfig.model!.value}". '
        'Check the model name or use a CustomModel string.',
        statusCode: 404,
        raw: raw,
      ),
      429 => EngineException(
        'GeminiEngine: rate limit exceeded. '
        'Consider adding a RetryConfig or upgrading your API plan.',
        statusCode: 429,
        raw: raw,
      ),
      500 => EngineException(
        'GeminiEngine: Gemini server error. Try again shortly.',
        statusCode: 500,
        raw: raw,
      ),
      503 => EngineException(
        'GeminiEngine: Gemini service temporarily unavailable.',
        statusCode: 503,
        raw: raw,
      ),
      _ => EngineException(
        'GeminiEngine: unexpected error — ${e.message}',
        statusCode: statusCode,
        raw: raw,
      ),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      final data = await _dio.get(
        'https://api.openai.com/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
      );
      final models = data.data['data'] as List<dynamic>;
      return models.map((model) => model as Map<String, dynamic>).toList();
    } catch (error) {
      throw EngineException(
        'GeminiEngine: failed to fetch models — ${error.toString()}',
        raw: error.toString(),
      );
    }
  }
}
