import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_mind/src/core/configs/ai_config.dart';
import 'package:flutter_mind/src/core/configs/retry_config.dart';
import 'package:flutter_mind/src/core/engines/ai_engine.dart';
import 'package:flutter_mind/src/core/exceptions/flutter_mind_exception.dart';
import 'package:flutter_mind/src/core/models/ai_model.dart';
import 'package:flutter_mind/src/ai_request.dart';
import 'package:flutter_mind/src/ai_response.dart';

/// AI engine for Google Gemini models.
///
/// Implements [AiEngine] using the Gemini REST API via [Dio].
///
/// ```dart
/// // Simple setup — smart defaults applied automatically
/// final gemini = GeminiEngine(apiKey: 'AIza...');
///
/// // Custom setup
/// final gemini = GeminiEngine(
///   apiKey: 'AIza...',
///   defaultConfig: GeminiConfig(
///     model: GeminiModel.pro25,
///     temperature: 0.3,
///     thinkingBudget: 2000,
///   ),
///   timeout: Duration(seconds: 60),
///   retry: RetryConfig(maxAttempts: 3),
/// );
///
/// // Send a message
/// final response = await gemini.send(userMessage: 'hello');
///
/// // Stream a message
/// gemini.stream(userMessage: 'tell me a story').listen((chunk) {
///   print(chunk);
/// });
///
/// // Override config per call
/// final response = await gemini.send(
///   userMessage: 'solve this',
///   config: GeminiConfig(
///     model: GeminiModel.pro25,
///     thinkingBudget: 5000,
///   ),
/// );
/// ```
///
/// Always call [dispose] when the engine is no longer needed.
///
/// **API reference:** https://ai.google.dev/api/generate-content
class GeminiEngine implements AiEngine {
  /// Creates a Gemini engine.
  ///
  /// [apiKey] is required — get yours at https://aistudio.google.com/apikey
  ///
  /// [defaultConfig] is optional — smart defaults are applied automatically
  /// based on the config you provide. See [_resolveSmartDefaults].
  ///
  /// [timeout] defaults to 30 seconds.
  ///
  /// [retry] defaults to [RetryConfig] — retries twice on safe error codes.
  ///
  /// [dio] is optional — pass your own configured instance if needed.
  /// If not provided, the engine creates one internally.
  GeminiEngine({
    required String apiKey,
    GeminiConfig? defaultConfig,
    Duration timeout = const Duration(seconds: 30),
    RetryConfig retry = const RetryConfig(),
    Dio? dio,
  })  : _apiKey = apiKey,
        _timeout = timeout,
        _retry = retry,
        _defaultConfig = _resolveSmartDefaults(defaultConfig),
        _dio = dio ?? Dio() {
    validate();
  }

  // ─────────────────────────────────────────────
  // PRIVATE FIELDS
  // ─────────────────────────────────────────────

  final String _apiKey;
  final Duration _timeout;
  final RetryConfig _retry;
  final GeminiConfig _defaultConfig;
  final Dio _dio;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ─────────────────────────────────────────────
  // AiEngine — PUBLIC API
  // ─────────────────────────────────────────────

  @override
  AiModel get model => _defaultConfig.model;

  /// Sends a single request and returns the full response.
  ///
  /// Optionally pass [config] to override the [defaultConfig] for this
  /// call only — only fields you set will override, rest use defaults.
  ///
  /// Throws [EngineException] on API errors.
  /// Throws [ConfigException] if [config] is not a [GeminiConfig].
  @override
  Future<AiResponse> send({
    required String userMessage,
    AiConfig? config,
  }) async {
    final resolved = _mergeConfig(config);
    final request = AiRequest(userMessage: userMessage, config: resolved);
    return _sendWithRetry(request);
  }

  /// Streams the response word by word as it is generated.
  ///
  /// Use for typing-effect UIs.
  ///
  /// Optionally pass [config] to override the [defaultConfig] for this
  /// call only.
  ///
  /// Throws [EngineException] on API errors.
  @override
  Stream<String> stream({
    required String userMessage,
    AiConfig? config,
  }) {
    final resolved = _mergeConfig(config);
    final request = AiRequest(userMessage: userMessage, config: resolved);
    return _streamRequest(request);
  }

  /// Returns the estimated token count for the given message and config.
  ///
  /// Uses Gemini's real countTokens API for accurate results.
  /// Falls back to rough estimation if the API call fails.
  @override
  Future<int> countTokens({
    required String userMessage,
    AiConfig? config,
  }) async {
    final resolved = _mergeConfig(config);
    try {
      final url = '$_baseUrl/${resolved.model.value}:countTokens'
          '?key=$_apiKey';
      final body = _buildRequestBody(
        userMessage: userMessage,
        config: resolved,
      );
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      return response.data['totalTokens'] as int? ?? 0;
    } catch (_) {
      // Fallback — rough estimate: 1 token ≈ 4 characters
      final systemLength = resolved.systemPrompt?.length ?? 0;
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
        '$_baseUrl/${_defaultConfig.model.value}?key=$_apiKey',
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

  // ─────────────────────────────────────────────
  // PRIVATE — CONFIG
  // ─────────────────────────────────────────────

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
    return GeminiConfig(
      model: override.model ?? _defaultConfig.model,
      systemPrompt: override.systemPrompt ?? _defaultConfig.systemPrompt,
      temperature: override.temperature ?? _defaultConfig.temperature,
      maxOutputTokens:
          override.maxOutputTokens ?? _defaultConfig.maxOutputTokens,
      stopSequences: override.stopSequences ?? _defaultConfig.stopSequences,
      topP: override.topP ?? _defaultConfig.topP,
      topK: override.topK ?? _defaultConfig.topK,
      thinkingBudget:
          override.thinkingBudget ?? _defaultConfig.thinkingBudget,
      responseMimeType:
          override.responseMimeType ?? _defaultConfig.responseMimeType,
      responseSchema:
          override.responseSchema ?? _defaultConfig.responseSchema,
      candidateCount:
          override.candidateCount ?? _defaultConfig.candidateCount,
      seed: override.seed ?? _defaultConfig.seed,
      presencePenalty:
          override.presencePenalty ?? _defaultConfig.presencePenalty,
      frequencyPenalty:
          override.frequencyPenalty ?? _defaultConfig.frequencyPenalty,
    );
  }

  /// Applies smart defaults based on what the developer configured.
  ///
  /// Runs once at construction — zero cost per request.
  static GeminiConfig _resolveSmartDefaults(GeminiConfig? config) {
    // Developer set nothing — use best defaults for general use
    if (config == null) {
      return const GeminiConfig(
        model: GeminiModel.flash25,
        temperature: 0.7,
      );
    }

    final model = config.model;
    final hasThinking = config.thinkingBudget != null;
    final hasStructuredOutput = config.responseMimeType != null;

    return GeminiConfig(
      // Model — if not set, pick based on config
      model: model,

      // System prompt — keep as is
      systemPrompt: config.systemPrompt,

      // Temperature — smart default based on use case
      temperature: config.temperature ??
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
      thinkingBudget: config.thinkingBudget,
      responseMimeType: config.responseMimeType,
      responseSchema: config.responseSchema,
      candidateCount: config.candidateCount,
      seed: config.seed,
      presencePenalty: config.presencePenalty,
      frequencyPenalty: config.frequencyPenalty,
    );
  }

  // ─────────────────────────────────────────────
  // PRIVATE — HTTP
  // ─────────────────────────────────────────────

  /// Sends a request with automatic retry on safe error codes.
  Future<AiResponse> _sendWithRetry(AiRequest request) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _sendRequest(request);
      } on EngineException catch (e) {
        final shouldRetry = e.statusCode != null &&
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
    final url =
        '$_baseUrl/${config.model.value}:generateContent?key=$_apiKey';

    try {
      final response = await _dio.post(
        url,
        data: _buildRequestBody(
          userMessage: request.userMessage,
          config: config,
        ),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      return _parseResponse(response.data, config.model);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Streams a streamGenerateContent request.
  Stream<String> _streamRequest(AiRequest request) async* {
    final config = request.config as GeminiConfig;
    final url =
        '$_baseUrl/${config.model.value}:streamGenerateContent'
        '?key=$_apiKey&alt=sse';

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: _buildRequestBody(
          userMessage: request.userMessage,
          config: config,
        ),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.stream,
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      final stream = response.data!.stream
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

  // ─────────────────────────────────────────────
  // PRIVATE — REQUEST BUILDING
  // ─────────────────────────────────────────────

  /// Builds the JSON request body for generateContent.
  Map<String, dynamic> _buildRequestBody({
    required String userMessage,
    required GeminiConfig config,
  }) {
    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userMessage}
          ],
        }
      ],
    };

    // System instruction
    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': config.systemPrompt}
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
    if (config.thinkingBudget != null) {
      generationConfig['thinkingConfig'] = {
        'thinkingBudget': config.thinkingBudget,
      };
    }

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    return body;
  }

  // ─────────────────────────────────────────────
  // PRIVATE — RESPONSE PARSING
  // ─────────────────────────────────────────────

  /// Parses a full generateContent response into [AiResponse].
  AiResponse _parseResponse(
    Map<String, dynamic> json,
    AiModel model,
  ) {
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
      final parts = (candidates.first as Map<String, dynamic>)['content']
          ?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;
      return (parts.first as Map<String, dynamic>)['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE — ERROR HANDLING
  // ─────────────────────────────────────────────

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
          'GeminiEngine: model not found — "${_defaultConfig.model.value}". '
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
}