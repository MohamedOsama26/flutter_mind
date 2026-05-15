part of 'ai_model.dart';

/// Known OpenAI models.
///
/// For unlisted models use [CustomModel]:
/// ```dart
/// CustomModel('gpt-5')
/// ```
final class OpenAiModel extends AiModel {
  const OpenAiModel._(this.value);

  @override
  final String value;

  /// GPT-4o — flagship multimodal model.
  static const gpt4o = OpenAiModel._('gpt-4o');

  /// GPT-4o Mini — fast, affordable GPT-4 level model. Default for [OpenAiEngine].
  static const gpt4oMini = OpenAiModel._('gpt-4o-mini');

  /// O3 Mini — reasoning model, efficient.
  static const o3Mini = OpenAiModel._('o3-mini');

  /// O3 — full reasoning model.
  static const o3 = OpenAiModel._('o3');
}
