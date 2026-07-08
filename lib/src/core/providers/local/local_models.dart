part of '../../shared/ai_model.dart';

/// **Deprecated.** Local model support has moved to `package:flutter_mind_local`.
///
/// Migration:
/// ```yaml
/// # pubspec.yaml
/// dependencies:
///   flutter_mind_local: ^0.1.0
/// ```
/// ```dart
/// // Before
/// import 'package:flutter_mind/flutter_mind.dart';
///
/// // After — re-exports all base types, no other imports needed
/// import 'package:flutter_mind_local/flutter_mind_local.dart';
/// ```
///
/// ---
///
/// Represents a local on-device model identified by its `.gguf` file path.
///
/// ```dart
/// LocalModel('/data/user/0/com.app/files/qwen.gguf')
/// ```
@Deprecated(
  'LocalModel has moved to package:flutter_mind_local. '
  'Add flutter_mind_local to your pubspec.yaml and replace this import with '
  '`package:flutter_mind_local/flutter_mind_local.dart` — '
  'it re-exports all base types (AiEngine, AiConfig, AiResponse) so no other imports are needed. '
  'This will be removed in flutter_mind v1.0.0.',
)
final class LocalModel extends AiModel {
  /// Creates a local model from the absolute path to a `.gguf` file.
  const LocalModel(this.modelPath);

  /// Absolute path to the `.gguf` model file on device.
  final String modelPath;

  /// Returns the filename (without directory) as the model identifier.
  @override
  String get value => modelPath.split('/').last;
}
