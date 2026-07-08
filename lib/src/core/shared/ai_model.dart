import 'package:flutter_mind/src/core/shared/capability.dart';

part '../providers/gemini/gemini_models.dart';
part '../providers/open_ai/open_ai_models.dart';
part '../providers/claude/claude_models.dart';
part '../providers/custom/custom_models.dart';
part '../providers/deep_seek/deep_seek_models.dart';
part '../providers/grok/grok_models.dart';
part '../providers/minimax/minimax_models.dart';
part '../providers/local/local_models.dart';


/// Base sealed class for all AI models.
///
/// Use known model constants for compile-time safety and autocomplete:
/// ```dart
/// GeminiModel.flash25
/// OpenAiModel.gpt4oMini
/// ClaudeModel.sonnet
/// ```
///
/// Use [CustomModel] for any model not listed:
/// ```dart
/// CustomModel('gemini-3.0-ultra')
/// ```
sealed class AiModel {
  const AiModel();

  /// The raw model string sent to the API.
  String get value;

  /// The capabilities supported by this model, if known.
  ///
  /// This is used by flutter_mind to determine which features are available,
  /// such as whether to allow file uploads, agentic features, etc.
  ///
  /// For known models, this is populated based on public documentation.
  /// For [CustomModel], this is always empty since we have no information about the model.
  Set<Capability> get capabilities => const {};

  /// Returns true if this model supports the given capability.
  bool supports(Capability capability) => capabilities.contains(capability);
}