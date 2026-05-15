part of 'ai_model.dart';

/// A custom model identified by a raw string.
///
/// Use this for any model not listed as a known constant,
/// including new releases, local models, or custom deployments:
///
/// ```dart
/// // New model not yet in package
/// CustomModel('gemini-3.0-ultra')
///
/// // Local Ollama model
/// CustomModel('llama3.2')
///
/// // HuggingFace hosted model
/// CustomModel('mistralai/Mistral-7B-Instruct-v0.3')
/// ```
///
/// The value is passed through as-is to the engine.
/// No validation is performed — errors from invalid model
/// names will be returned by the API at runtime.
final class CustomModel extends AiModel {
  /// Creates a custom model with the given [value].
  ///
  /// Throws an [AssertionError] in debug mode if [value] is empty.
  const CustomModel(this.value)
    : assert(
        value != '',
        'FlutterMind: CustomModel value cannot be empty string.',
      );

  @override
  final String value;
}