part of 'flutter_mind_exception.dart';


/// Thrown when the AI engine fails to complete a request.
///
/// Common causes:
/// - Invalid or expired API key
/// - Model does not exist on the provider
/// - Rate limit exceeded
/// - Network timeout or no internet
/// - Provider server error (5xx)
/// - Local engine not reachable (Ollama not running)
///
/// Always includes the [statusCode] when available,
/// so developers can handle specific HTTP errors:
///
/// ```dart
/// try {
///   final response = await FlutterMind.send(userMessage: 'hello');
/// } on EngineException catch (e) {
///   if (e.statusCode == 429) {
///     // rate limited — wait and retry
///   } else if (e.statusCode == 401) {
///     // invalid API key
///   } else {
///     print(e.message);
///   }
/// }
/// ```
final class EngineException extends FlutterMindException {
  const EngineException(
    super.message, {
    this.statusCode,
    this.raw,
  });

  /// HTTP status code returned by the provider, if available.
  ///
  /// `null` for network errors, timeouts, or local engine failures.
  final int? statusCode;

  /// Raw response body from the provider, if available.
  ///
  /// Useful for debugging unexpected API responses.
  final String? raw;

  @override
  String toString() {
    final code = statusCode != null ? ' (HTTP $statusCode)' : '';
    return '[FlutterMind] EngineException$code: $message';
  }
}