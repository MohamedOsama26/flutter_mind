part of 'flutter_mind_exception.dart';
 
/// Thrown when the package is misconfigured at init time.
///
/// Caught at startup — before any API call is made.
///
/// Common causes:
/// - Missing or empty API key
/// - Wrong model type passed to engine
/// - Required fields missing on custom engine
/// - Conflicting config options
///
/// ```dart
/// try {
///   await FlutterMind.init(engine: GeminiEngine(apiKey: ''));
/// } on ConfigException catch (e) {
///   print(e.message); // 'FlutterMind: apiKey cannot be empty'
/// }
/// ```
final class ConfigException extends FlutterMindException {
  const ConfigException(super.message);
}
