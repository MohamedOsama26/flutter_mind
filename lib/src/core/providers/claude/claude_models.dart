part of '../../shared/ai_model.dart';


/// Known Anthropic Claude models.
///
/// For unlisted models use [CustomModel]:
/// ```dart
/// CustomModel('claude-opus-5')
/// ```
final class ClaudeModel extends AiModel {
  const ClaudeModel._(this.value);

  @override
  final String value;

  /// Claude Sonnet 4.6 — balanced speed and quality. Default for [ClaudeEngine].
  static const sonnet46 = ClaudeModel._('claude-sonnet-4-6');

  /// Claude Opus 4.6 — highest quality Claude model.
  static const opus46 = ClaudeModel._('claude-opus-4-6');

  /// Claude Haiku 4.5 — fastest, most affordable Claude model.
  static const haiku45 = ClaudeModel._('claude-haiku-4-5-20251001');
}