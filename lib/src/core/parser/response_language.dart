/// The language the AI should use in its response.
///
/// Pass this to [PromptConfig] to control which language the model
/// writes in. [auto] is the smart default — the model detects the
/// user's language from their message and replies in the same language.
///
/// ```dart
/// PromptConfig(
///   language: ResponseLanguage.auto, // matches whatever the user writes
/// )
/// ```
///
/// For language detection logic, see [MessageAnalyzer].
enum ResponseLanguage {
  /// Respond only in English, regardless of the user's message language.
  english,

  /// Respond only in Arabic (Modern Standard or dialect, depending on context).
  ///
  /// Works well for Egyptian Arabic apps — the model respects colloquial
  /// phrasing when the system prompt uses Arabic examples.
  arabic,

  /// Respond in both English and Arabic side by side.
  ///
  /// Useful for language-learning apps or mixed-audience products
  /// where users may be more comfortable in either language.
  bilingual,

  /// Detect the user's language automatically and reply in the same language.
  ///
  /// This is the recommended default. [MessageAnalyzer] detects whether
  /// the message is Arabic, English, or mixed, and the [PromptBuilder]
  /// injects the matching language instruction.
  ///
  /// Arabic detection uses the Unicode range ؀–ۿ.
  /// If both scripts appear, [bilingual] behavior applies.
  auto;

  /// The natural-language instruction injected into the system prompt.
  ///
  /// Returns an empty string for [auto] — the instruction is resolved
  /// at build time by [MessageAnalyzer.detectLanguage].
  String get instruction => switch (this) {
        ResponseLanguage.english   => 'Always respond in English.',
        ResponseLanguage.arabic    => 'Always respond in Arabic.',
        ResponseLanguage.bilingual => 'Respond in both English and Arabic.',
        ResponseLanguage.auto      => '',
      };

  /// Short token-compressed label used in the telegraphic system prompt.
  ///
  /// Returns an empty string for [auto] — resolved at build time.
  String get compressed => switch (this) {
        ResponseLanguage.english   => 'en',
        ResponseLanguage.arabic    => 'ar',
        ResponseLanguage.bilingual => 'en+ar',
        ResponseLanguage.auto      => '',
      };
}
