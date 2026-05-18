/// The tone and style the AI should use when writing its response.
///
/// Pass this to [PromptConfig] to shape how the model communicates —
/// not what it says, but how it says it. The [PromptBuilder] converts
/// this into a natural-language instruction in the system prompt.
///
/// ```dart
/// PromptConfig(
///   tone: ResponseTone.friendly,
///   format: ResponseFormat.bulletedList,
/// )
/// ```
enum ResponseTone {
  /// Professional and objective — no slang, no filler.
  ///
  /// Best for business apps, reports, and any context where credibility
  /// and precision matter more than personality.
  formal,

  /// Relaxed, conversational, everyday language.
  ///
  /// Best for social apps, entertainment, and any context where the user
  /// expects a natural, human-like back-and-forth.
  casual,

  /// Warm and encouraging — like a helpful friend, not a manual.
  ///
  /// Best for onboarding flows, health apps, coaching tools,
  /// or any product that benefits from a supportive tone.
  friendly,

  /// Short, direct, no fluff.
  ///
  /// Best when the user needs a fast answer and does not want context,
  /// caveats, or elaboration. Pairs well with [ResponseFormat.oneSentence]
  /// or [ResponseFormat.oneWord].
  concise,

  /// Thorough and explanatory — covers context, reasoning, and examples.
  ///
  /// Best for educational apps, technical documentation, or any case
  /// where the user benefits from understanding the full picture.
  detailed;

  /// The natural-language instruction injected into the system prompt.
  String get instruction => switch (this) {
        ResponseTone.formal    => 'Use formal, professional language.',
        ResponseTone.casual    => 'Use casual, conversational language.',
        ResponseTone.friendly  => 'Use a warm, friendly, and encouraging tone.',
        ResponseTone.concise   => 'Be concise and direct. Avoid unnecessary words.',
        ResponseTone.detailed  => 'Be thorough and detailed. Include context and examples where helpful.',
      };

  /// Short token-compressed label used in the telegraphic system prompt.
  String get compressed => switch (this) {
        ResponseTone.formal    => 'formal',
        ResponseTone.casual    => 'casual',
        ResponseTone.friendly  => 'friendly',
        ResponseTone.concise   => 'concise',
        ResponseTone.detailed  => 'detailed',
      };
}
