part 'config_exception.dart';
part 'engine_exception.dart';
part 'validation_exception.dart';


/// Base exception for all flutter_mind errors.
///
/// All package-specific exceptions extend this class,
/// so developers can catch everything with one handler:
///
/// ```dart
/// try {
///   await FlutterMind.instance.send('hello');
/// } on FlutterMindException catch (e) {
///   print(e.message);
/// }
/// ```
sealed class FlutterMindException implements Exception {
  const FlutterMindException(this.message);
 
  /// Human-readable description of what went wrong.
  final String message;
 
  @override
  String toString() => '[FlutterMind] $message';
}
 
