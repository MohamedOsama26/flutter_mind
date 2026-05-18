/// Controls how the model signals it has finished responding.
///
/// A stop signal is a special word or token the model writes at the end of
/// its output. The API stops generating the moment it sees that word —
/// saving tokens and preventing the model from rambling after it is done.
///
/// Set this via [Prompt.stopSignalMode] or [PromptBuilder.stopSignal]:
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
/// Pass [PromptBuilder.buildStopSequences] to [GeminiConfig.stopSequences]
/// so the API actually halts at the signal:
///
/// ```dart
/// final builder = PromptBuilder()
///   .format(ResponseFormat.numberedList)
///   .maxItems(3);
///
/// GeminiConfig(
///   systemPrompt: builder.build(),
///   stopSequences: builder.buildStopSequences(),
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
