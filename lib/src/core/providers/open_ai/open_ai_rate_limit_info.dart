part of 'open_ai_engine.dart';

/// Rate limit information from the last OpenAI API response.
///
/// OpenAI returns these headers on every response, so this is updated
/// automatically after every [OpenAiEngine.send], [OpenAiEngine.stream],
/// and [OpenAiEngine.getModels] call.
///
/// Use it to monitor usage and warn users before they hit a limit:
///
/// ```dart
/// final response = await openai.send(userMessage: 'hello');
///
/// final info = openai.rateLimitInfo;
/// if (info != null && info.remainingTokens != null) {
///   if (info.remainingTokens! < 1000) {
///     print('Warning: only ${info.remainingTokens} tokens left. '
///           'Resets in ${info.resetTokens}');
///   }
/// }
/// ```
class OpenAiRateLimitInfo {
  const OpenAiRateLimitInfo({
    this.limitRequests,
    this.limitTokens,
    this.remainingRequests,
    this.remainingTokens,
    this.resetRequests,
    this.resetTokens,
    this.limitProjectTokens,
    this.remainingProjectTokens,
    this.resetProjectTokens,
  });

  /// Maximum requests allowed per minute on your tier.
  final int? limitRequests;

  /// Maximum tokens allowed per minute on your tier.
  final int? limitTokens;

  /// Requests remaining before the rate limit resets.
  final int? remainingRequests;

  /// Tokens remaining before the rate limit resets.
  ///
  /// Monitor this to avoid hitting the limit mid-conversation.
  final int? remainingTokens;

  /// Human-readable time until the request limit resets (e.g. `"1s"`, `"2m30s"`).
  final String? resetRequests;

  /// Human-readable time until the token limit resets (e.g. `"6m0s"`).
  final String? resetTokens;

  /// Maximum project-scoped tokens per minute (present on some tiers).
  final int? limitProjectTokens;

  /// Remaining project-scoped tokens (present on some tiers).
  final int? remainingProjectTokens;

  /// Time until the project-scoped token limit resets (present on some tiers).
  final String? resetProjectTokens;

  /// Parses rate limit headers from a Dio [response].
  ///
  /// Returns `null` if no rate limit headers are present.
  static OpenAiRateLimitInfo? fromHeaders(Headers headers) {
    int? parseInt(String key) {
      final v = headers.value(key);
      return v == null ? null : int.tryParse(v);
    }

    String? parseStr(String key) => headers.value(key);

    final remainingRequests = parseInt('x-ratelimit-remaining-requests');
    final remainingTokens = parseInt('x-ratelimit-remaining-tokens');

    // Only build the object if at least one rate limit header is present.
    if (remainingRequests == null && remainingTokens == null) return null;

    return OpenAiRateLimitInfo(
      limitRequests: parseInt('x-ratelimit-limit-requests'),
      limitTokens: parseInt('x-ratelimit-limit-tokens'),
      remainingRequests: remainingRequests,
      remainingTokens: remainingTokens,
      resetRequests: parseStr('x-ratelimit-reset-requests'),
      resetTokens: parseStr('x-ratelimit-reset-tokens'),
      limitProjectTokens: parseInt('x-ratelimit-limit-project-tokens'),
      remainingProjectTokens: parseInt('x-ratelimit-remaining-project-tokens'),
      resetProjectTokens: parseStr('x-ratelimit-reset-project-tokens'),
    );
  }

  @override
  String toString() {
    final parts = <String>[];
    if (remainingRequests != null) {
      parts.add('requests: $remainingRequests/$limitRequests');
    }
    if (remainingTokens != null) {
      parts.add('tokens: $remainingTokens/$limitTokens');
    }
    if (resetTokens != null) parts.add('resets in: $resetTokens');
    return 'OpenAiRateLimitInfo(${parts.join(', ')})';
  }
}
