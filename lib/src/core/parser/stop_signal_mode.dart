/// Controls how the model signals it has finished responding.
///
/// A stop signal is a special word or token the model writes at the end of
/// its output. The API stops generating the moment it sees that word —
/// saving tokens and preventing the model from rambling after it is done.
///
/// Set this via [Prompt.stopSignalMode]:
///
/// ```dart
/// // Recommended — let the package decide automatically
/// Prompt(
///   format: ResponseFormat.numberedList,
///   maxItems: 3,
///   stopSignalMode: StopSignalMode.auto, // adds [END] for lists
/// )
///
/// // Custom stop signal
/// Prompt(
///   stopSignalMode: StopSignalMode.manual,
///   customStopSignal: '[DONE]',
/// )
///
/// // No stop signal
/// Prompt(stopSignalMode: StopSignalMode.none)
/// ```
///
/// Pass [Prompt.stopSequences] to [GeminiConfig.stopSequences]
/// so the API actually halts at the signal:
///
/// ```dart
/// final prompt = Prompt(
///   format: ResponseFormat.numberedList,
///   maxItems: 3,
/// );
///
/// GeminiConfig(
///   systemPrompt: prompt,
///   stopSequences: prompt.stopSequences,
/// )
/// ```
enum StopSignalMode {
  /// Package adds a stop signal automatically based on format and maxItems.
  ///
  /// Adds `[END]` when format is a list type and [Prompt.maxItems] is set.
  /// No stop signal is added for other formats.
  ///
  /// Recommended for most apps — saves tokens without any extra setup.
  auto,

  /// You define the stop signal via [Prompt.customStopSignal].
  ///
  /// ```dart
  /// Prompt(
  ///   stopSignalMode: StopSignalMode.manual,
  ///   customStopSignal: '[DONE]',
  /// )
  /// ```
  manual,

  /// No stop signal — model stops naturally when it finishes.
  none,
}
