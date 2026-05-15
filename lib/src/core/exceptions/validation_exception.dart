part of 'flutter_mind_exception.dart';

/// Thrown when the user message fails validation
/// before being sent to the engine.
///
/// Caught before any API call is made — no credits wasted.
///
/// Common causes:
/// - Empty message
/// - Message exceeds maximum allowed length
/// - Message contains disallowed characters or patterns
///
/// ```dart
/// try {
///   await FlutterMind.instance.send('');
/// } on ValidationException catch (e) {
///   print(e.message); // 'FlutterMind: message cannot be empty'
/// }
/// ```
final class ValidationException extends FlutterMindException {
  const ValidationException(super.message);
}