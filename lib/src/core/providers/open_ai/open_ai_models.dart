part of '../../shared/ai_model.dart';

/// Known OpenAI text/chat models for use with [OpenAiEngine].
///
/// All constants here support text input and text output and work with
/// [OpenAiEngine.send] and [OpenAiEngine.stream].
///
/// For models not listed (image, realtime, audio, transcription) use [CustomModel]:
/// ```dart
/// CustomModel('gpt-image-2')
/// CustomModel('gpt-realtime-2.1')
/// ```
///
/// ## Choosing a model
///
/// | Model | Best for | Cost |
/// |---|---|---|
/// | [gpt55] | Complex reasoning, coding, professional work | $$$ |
/// | [gpt54] | Coding and professional work, lower cost | $$ |
/// | [gpt54Mini] | High-volume, low-latency workloads | $ |
/// | [gpt54Nano] | Cheapest and fastest | ¢ |
final class OpenAiModel extends AiModel {
  const OpenAiModel._(this.value);

  @override
  final String value;

  // ─── GPT-5 family ─────────────────────────────────────────────────────────

  /// GPT-5.5 — flagship model for complex reasoning and coding.
  ///
  /// Context window: 1M tokens. Max output: 128K tokens.
  /// Supports functions, web search, file search, computer use.
  static const gpt55 = OpenAiModel._('gpt-5.5');

  /// GPT-5.4 — affordable model for coding and professional work.
  ///
  /// Context window: 1M tokens. Max output: 128K tokens.
  /// Supports functions, web search, file search, computer use.
  static const gpt54 = OpenAiModel._('gpt-5.4');

  /// GPT-5.4 mini — fast mini model for coding, computer use, and subagents.
  ///
  /// Context window: 400K tokens. Max output: 128K tokens.
  /// Supports functions, web search, file search, computer use.
  static const gpt54Mini = OpenAiModel._('gpt-5.4-mini');

  /// GPT-5.4 nano — cheapest and fastest variant. Best for high-volume tasks.
  ///
  /// Use when latency and cost matter more than reasoning depth.
  static const gpt54Nano = OpenAiModel._('gpt-5.4-nano');

  // ─── GPT-4o family (previous generation) ──────────────────────────────────

  /// GPT-4o — previous generation flagship multimodal model.
  @Deprecated('Use OpenAiModel.gpt55 instead.')
  static const gpt4o = OpenAiModel._('gpt-4o');

  /// GPT-4o Mini — previous generation fast, affordable model.
  @Deprecated('Use OpenAiModel.gpt54Mini instead.')
  static const gpt4oMini = OpenAiModel._('gpt-4o-mini');

  // ─── O3 reasoning family (previous generation) ────────────────────────────

  /// O3 — previous generation full reasoning model.
  @Deprecated('Use OpenAiModel.gpt55 for reasoning tasks instead.')
  static const o3 = OpenAiModel._('o3');

  /// O3 Mini — previous generation efficient reasoning model.
  @Deprecated('Use OpenAiModel.gpt54Mini for reasoning tasks instead.')
  static const o3Mini = OpenAiModel._('o3-mini');
}
