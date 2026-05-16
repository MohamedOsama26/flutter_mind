/// Controls how many tokens the model can spend on internal reasoning
/// before producing a visible response.
///
/// Gemini's "thinking" feature lets the model silently reason through a problem
/// step by step before answering. The more tokens it is allowed to spend
/// thinking, the deeper and more accurate the reasoning — but the slower and
/// more expensive the call becomes.
///
/// ## How to use
///
/// Pass a [ThinkingBudget] to [GeminiConfig.thinkingBudget]:
///
/// ```dart
/// final gemini = GeminiEngine(
///   apiKey: 'AIza...',
///   config: GeminiConfig(
///     model: GeminiModel.flash25,
///     thinkingBudget: ThinkingLevel.moderate,
///   ),
/// );
/// ```
///
/// Use a preset from [ThinkingLevel] or supply an exact token count with
/// [CustomThinkingBudget] when you have specific latency or cost requirements.
///
/// ## Choosing a level
///
/// | Level    | Tokens | Latency | Cost  | Best for                         |
/// |----------|--------|---------|-------|----------------------------------|
/// | none     | 0      | fastest | free  | Simple Q&A, no reasoning needed  |
/// | light    | 512    | fast    | low   | Basic analysis, simple decisions |
/// | moderate | 2048   | medium  | medium| Coding, math, structured tasks   |
/// | deep     | 8192   | slow    | high  | Hard problems, multi-step logic  |
/// | max      | 24576  | slowest | highest| Research, extremely hard tasks  |
///
/// ## Thinking vs. visible output
///
/// The thinking tokens are internal — they are **not** part of the text the
/// user sees. [AiResponse.thinkingText] exposes them if you want to show
/// the reasoning to the developer (e.g. for debugging), but typical apps
/// never display it.
///
/// ## Cost warning
///
/// Thinking tokens count toward your API usage just like output tokens.
/// [ThinkingLevel.max] can add thousands of tokens to every single call.
/// Prefer [ThinkingLevel.moderate] or [ThinkingLevel.deep] unless you are
/// solving genuinely hard problems.
sealed class ThinkingBudget {
  const ThinkingBudget({required this.tokens});

  /// The number of tokens reserved for internal reasoning.
  ///
  /// A value of `0` means thinking is disabled entirely.
  final int tokens;
}

/// Predefined thinking levels for common use cases.
///
/// Prefer these over [CustomThinkingBudget] — they cover most scenarios and
/// make intent clear at a glance. Use [CustomThinkingBudget] only when you
/// have measured a specific latency or cost target.
///
/// ```dart
/// // Disable thinking for a fast, cheap response
/// thinkingBudget: ThinkingLevel.none
///
/// // Light thinking for basic analysis
/// thinkingBudget: ThinkingLevel.light
///
/// // Deep thinking for complex code or hard math
/// thinkingBudget: ThinkingLevel.deep
/// ```
final class ThinkingLevel extends ThinkingBudget {
  const ThinkingLevel._({ required super.tokens});

  /// No thinking — the model responds immediately without internal reasoning.
  ///
  /// Use when the task is straightforward and latency or cost is a priority:
  /// - Simple questions and answers
  /// - Text summarisation
  /// - Translation
  /// - Retrieval-augmented generation (RAG) where context is already prepared
  static const none = ThinkingLevel._(tokens: 0);

  /// Light thinking — a small burst of reasoning before responding.
  ///
  /// Adds minimal latency but gives the model a chance to organise its
  /// thoughts on moderately straightforward tasks:
  /// - Basic data analysis
  /// - Simple decisions or comparisons
  /// - Short explanations that benefit from structure
  static const light = ThinkingLevel._(tokens: 512);

  /// Moderate thinking — balanced depth and speed.
  ///
  /// The recommended starting point for most developer tasks:
  /// - Writing or reviewing code
  /// - Step-by-step mathematical problems
  /// - Structured reasoning (pros/cons, planning)
  /// - Multi-part questions where order matters
  static const moderate = ThinkingLevel._(tokens: 2048);

  /// Deep thinking — extended reasoning for hard problems.
  ///
  /// Noticeably slower and more expensive than [moderate]. Use when accuracy
  /// on a difficult problem matters more than response time:
  /// - Complex algorithms or architecture decisions
  /// - Multi-step mathematical proofs
  /// - Research-style synthesis across many facts
  /// - Debugging subtle logic errors
  static const deep = ThinkingLevel._(tokens: 8192);

  /// Maximum thinking — the model's full reasoning capacity.
  ///
  /// **Reserve for the hardest problems only.** At 24 576 tokens, this level
  /// can multiply your API cost significantly for every call that uses it.
  /// Suitable for:
  /// - Competition-level math or programming problems
  /// - Long-horizon planning with many constraints
  /// - Tasks where any error has a high real-world cost
  ///
  /// Consider [deep] first — in practice it handles most hard tasks well
  /// without the cost of max.
  static const max = ThinkingLevel._(tokens: 24576);
}

/// A custom token budget for when the presets do not fit your needs.
///
/// Use this when you have profiled your workload and know the exact thinking
/// token count that balances quality, latency, and cost for your use case.
///
/// ```dart
/// // Exactly 1000 tokens of thinking
/// thinkingBudget: CustomThinkingBudget(tokens: 1000)
/// ```
///
/// [tokens] must be `>= 0`. Pass `0` to disable thinking, though
/// [ThinkingLevel.none] is more readable for that intent.
final class CustomThinkingBudget extends ThinkingBudget {
  const CustomThinkingBudget({ required super.tokens})
      : assert(tokens >= 0, 'FlutterMind: thinking budget cannot be negative');
}
