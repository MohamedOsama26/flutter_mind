/// Configures automatic retry behavior for failed AI engine requests.
///
/// By default, [GeminiEngine] (and all engines) use conservative retry
/// settings that handle temporary failures silently without wasting tokens.
///
/// Retrying is only performed on errors where the API rejected the request
/// before processing it — so no tokens are burned on retry attempts.
///
/// ```dart
/// // Use defaults — retries twice on safe error codes
/// GeminiEngine(apiKey: 'key');
///
/// // Customize retry behavior
/// GeminiEngine(
///   apiKey: 'key',
///   retry: RetryConfig(
///     maxAttempts: 5,
///     delay: Duration(seconds: 3),
///     retryOn: {429, 503},
///   ),
/// );
///
/// // Disable retry completely
/// GeminiEngine(
///   apiKey: 'key',
///   retry: RetryConfig.none,
/// );
/// ```
class RetryConfig {
  /// Creates a retry configuration.
  ///
  /// All parameters have sensible defaults — pass nothing for standard behavior.
  const RetryConfig({
    this.maxAttempts = 2,
    this.delay = const Duration(seconds: 1),
    this.retryOn = const {429, 500, 503},
  }) : assert(maxAttempts >= 1, 'FlutterMind: maxAttempts must be at least 1');

  /// Disables retry completely — any failure throws immediately.
  ///
  /// Use when you want full control over error handling in your app.
  ///
  /// ```dart
  /// GeminiEngine(
  ///   apiKey: 'key',
  ///   retry: RetryConfig.none,
  /// );
  /// ```
  static const none = RetryConfig(maxAttempts: 1);

  /// Aggressive retry — for apps where availability is critical.
  ///
  /// Retries up to 5 times with a 2 second delay.
  static const aggressive = RetryConfig(
    maxAttempts: 5,
    delay: Duration(seconds: 2),
    retryOn: {429, 500, 502, 503, 504},
  );

  /// Maximum number of attempts including the first request.
  ///
  /// `2` means: try once, if it fails try one more time.
  /// `1` means: try once and never retry (same as [RetryConfig.none]).
  ///
  /// Default: 2
  final int maxAttempts;

  /// How long to wait between retry attempts.
  ///
  /// Longer delays give the provider time to recover from rate limits.
  ///
  /// Default: 1 second
  final Duration delay;

  /// HTTP status codes that trigger a retry.
  ///
  /// Only codes where the API rejected the request before processing —
  /// so no tokens are burned on retry.
  ///
  /// | Code | Meaning            | Safe to retry |
  /// |------|--------------------|---------------|
  /// | 429  | Rate limit         | ✅ Yes        |
  /// | 500  | Server error       | ✅ Yes        |
  /// | 503  | Service unavailable| ✅ Yes        |
  /// | 401  | Invalid API key    | ❌ No         |
  /// | 400  | Bad request        | ❌ No         |
  ///
  /// Default: `{429, 500, 503}`
  final Set<int> retryOn;

  /// Whether retry is effectively disabled.
  bool get isDisabled => maxAttempts <= 1;

  /// Whether the given [statusCode] should trigger a retry.
  bool shouldRetry(int statusCode) => retryOn.contains(statusCode);
}
