import 'package:flutter_mind/src/core/models/ai_model.dart';

/// Represents the response returned from an AI engine.
///
/// Returned by [FlutterMindClient.send] after every successful request.
/// For streaming responses, the full text is assembled from chunks
/// and returned as a single [AiResponse] at the end.
///
/// ```dart
/// final response = await FlutterMind.send(userMessage: 'suggest a game');
///
/// print(response.text);
/// print(response.totalTokens);
/// ```
class AiResponse {
  const AiResponse({
    required this.text,
    required this.model,
    this.inputTokens,
    this.outputTokens,
    this.thinkingText,
    this.finishReason,
  });


  /// The generated text response from the model.
  final String text;

  /// The model that generated this response.
  final AiModel model;

  /// Internal reasoning text from thinking models.
  ///
  /// Only populated when using a model with [Capability.thinking]
  /// and a [GeminiConfig.thinkingLevel] greater than 0 tokens.
  ///
  /// `null` for non-thinking models or when thinking is disabled.
  final String? thinkingText;


  /// Number of tokens in the input (system prompt + user message).
  ///
  /// `null` if the provider did not return token usage.
  final int? inputTokens;

  /// Number of tokens in the generated response.
  ///
  /// `null` if the provider did not return token usage.
  final int? outputTokens;

  /// Total tokens used by this request.
  ///
  /// `null` if either [inputTokens] or [outputTokens] is unavailable.
  ///
  /// Use this to track credit consumption per request.
  int? get totalTokens {
    if (inputTokens == null || outputTokens == null) return null;
    return inputTokens! + outputTokens!;
  }

  // METADATA
  /// Why the model stopped generating.
  ///
  /// The exact values are **provider-specific** — each AI provider uses
  /// different strings. Do not hardcode these values for cross-provider logic.
  ///
  /// **Gemini** common values:
  /// - `'STOP'` — natural end of response
  /// - `'MAX_TOKENS'` — hit [maxOutputTokens] limit
  /// - `'SAFETY'` — blocked by safety filters
  ///
  /// Use the helper getters [wasTruncated] and [wasBlocked] for safe,
  /// provider-aware checks instead of comparing this string directly.
  ///
  /// `null` if the provider did not return this information.
  final String? finishReason;

  // HELPERS
  /// Whether the response was cut off by the token limit.
  ///
  /// If `true`, consider increasing [GeminiConfig.maxOutputTokens].
  bool get wasTruncated => finishReason == 'MAX_TOKENS';

  /// Whether the response was blocked by safety filters.
  bool get wasBlocked => finishReason == 'SAFETY';

  /// Whether thinking text is available in this response.
  bool get hasThinking => thinkingText != null && thinkingText!.isNotEmpty;

  @override
  String toString() => 'AiResponse(model: ${model.value}, '
      'length: ${text.length}, tokens: $totalTokens)';
}