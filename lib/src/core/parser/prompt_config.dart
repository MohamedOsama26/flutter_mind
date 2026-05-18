import 'package:flutter_mind/src/core/parser/prompt_builder.dart';
import 'package:flutter_mind/src/core/parser/prompt_example.dart';
import 'package:flutter_mind/src/core/parser/response_format.dart';
import 'package:flutter_mind/src/core/parser/response_language.dart';
import 'package:flutter_mind/src/core/parser/response_tone.dart';
import 'package:flutter_mind/src/core/parser/stop_signal_mode.dart';

/// Holds everything that defines how the AI should behave and respond.
///
/// Think of [Prompt] as a form you fill in once — role, tone, format,
/// constraints — and then call [build] to get the final system prompt
/// string ready for [GeminiConfig.systemPrompt].
///
/// ## Simple usage — one line
///
/// ```dart
/// GeminiConfig(
///   model: GeminiModel.flash25,
///   systemPrompt: Prompt(role: 'game suggestion assistant').build(),
/// )
/// ```
///
/// ## With user message — enables language auto-detection
///
/// Pass the user's message to [build] and the prompt will automatically
/// tell the model to respond in the same language the user wrote in:
///
/// ```dart
/// // User writes in Arabic → model replies in Arabic
/// // User writes in English → model replies in English
/// systemPrompt: Prompt(
///   role: 'game suggestion assistant',
///   language: ResponseLanguage.auto,
/// ).build(userMessage: message),
/// ```
///
/// ## Full config
///
/// ```dart
/// systemPrompt: Prompt(
///   role: 'mobile game expert for Egyptian users',
///   goal: 'suggest games that match the user mood and age',
///   constraints: ['mobile only', 'no violent games', 'available in Egypt'],
///   format: ResponseFormat.numberedList,
///   maxItems: 3,
///   language: ResponseLanguage.auto,
///   tone: ResponseTone.friendly,
///   audience: 'Egyptian teenagers',
///   context: 'Egyptian mobile gaming market',
///   examples: [
///     PromptExample(input: 'fun game', output: 'Hollow Knight — challenging platformer'),
///     PromptExample(input: 'relaxing game', output: 'Stardew Valley — peaceful farming'),
///   ],
/// ).build(userMessage: message),
/// ```
///
/// For dynamic construction (e.g. adding constraints at runtime),
/// use [PromptBuilder] instead — it has the same fields as method chains.
///
/// ## Relationship between Prompt and PromptBuilder
///
/// [Prompt] is the **data** — you declare what you want.
/// [PromptBuilder] is the **logic** — it assembles the final string.
/// [Prompt.build] delegates to [PromptBuilder] internally.
class Prompt {
  const Prompt({
    this.role,
    this.goal,
    this.constraints = const [],
    this.format = ResponseFormat.paragraph,
    this.language = ResponseLanguage.auto,
    this.tone = ResponseTone.casual,
    this.maxItems,
    this.audience,
    this.context,
    this.examples = const [],
    this.stopSignalMode = StopSignalMode.auto,
    this.customStopSignal,
  });

  /// Who the AI is in this app — the single most impactful field.
  ///
  /// The model uses this to set its entire persona and scope.
  ///
  /// ```dart
  /// role: 'mobile game suggestion assistant'
  /// role: 'Egyptian local discovery guide'
  /// role: 'friendly Flutter code reviewer'
  /// ```
  final String? role;

  /// What the AI should achieve in every response.
  ///
  /// Complements [role] — role is **who**, goal is **what**:
  ///
  /// ```dart
  /// goal: 'suggest games that match the user mood and age group'
  /// goal: 'find nearby places based on user location and preference'
  /// ```
  final String? goal;

  /// Rules the model must always follow.
  ///
  /// Each constraint narrows the output and reduces unwanted responses.
  /// Keep constraints short and specific.
  ///
  /// ```dart
  /// constraints: ['mobile only', 'no violent games', 'available in Egypt']
  /// ```
  final List<String> constraints;

  /// How the response should be structured. Default: [ResponseFormat.paragraph].
  ///
  /// Matching format to your use case reduces token waste significantly.
  /// See [ResponseFormat] for all options and when to use each.
  final ResponseFormat format;

  /// Language the model responds in. Default: [ResponseLanguage.auto].
  ///
  /// [ResponseLanguage.auto] detects the user's language from [build]'s
  /// `userMessage` parameter and replies in the same language.
  /// Ideal for apps with Arabic and English users.
  final ResponseLanguage language;

  /// Personality and style of the response. Default: [ResponseTone.casual].
  ///
  /// See [ResponseTone] for all options and when to use each.
  final ResponseTone tone;

  /// Maximum items in list or steps responses.
  ///
  /// Only applies when [format] is [ResponseFormat.numberedList],
  /// [ResponseFormat.bulletedList], or [ResponseFormat.steps].
  ///
  /// ```dart
  /// format: ResponseFormat.numberedList,
  /// maxItems: 3, // model returns exactly 3 — no more, no less
  /// ```
  final int? maxItems;

  /// Who the end users of this app are.
  ///
  /// Helps the model calibrate vocabulary and complexity automatically.
  ///
  /// ```dart
  /// audience: 'Egyptian teenagers'
  /// audience: 'non-technical business users'
  /// audience: 'senior Flutter developers'
  /// ```
  final String? audience;

  /// Additional context about the app or market.
  ///
  /// ```dart
  /// context: 'Egyptian mobile gaming market'
  /// context: 'Arabic language learning app for beginners'
  /// ```
  final String? context;

  /// Input/output examples for few-shot prompting.
  ///
  /// 2–3 examples dramatically improve response quality and consistency.
  /// See [PromptExample] for details and token cost guidance.
  final List<PromptExample> examples;

  /// Controls when the model stops generating. Default: [StopSignalMode.auto].
  final StopSignalMode stopSignalMode;

  /// Custom stop signal string. Only used when [stopSignalMode]
  /// is [StopSignalMode.manual].
  final String? customStopSignal;

  /// Builds and returns the final system prompt string.
  ///
  /// Pass [userMessage] to enable [ResponseLanguage.auto] detection —
  /// the model will reply in the same language the user wrote in.
  ///
  /// Call this once and pass the result to [GeminiConfig.systemPrompt]:
  ///
  /// ```dart
  /// // Fixed language — build once at init
  /// GeminiConfig(
  ///   systemPrompt: Prompt(role: 'game assistant').build(),
  /// )
  ///
  /// // Auto language — build on each request with the user's message
  /// GeminiConfig(
  ///   systemPrompt: Prompt(
  ///     role: 'game assistant',
  ///     language: ResponseLanguage.auto,
  ///   ).build(userMessage: message),
  /// )
  /// ```
  /// Returns a copy of this prompt with the given fields replaced.
  ///
  /// Useful for customizing [AiPreset] presets without rebuilding from scratch:
  ///
  /// ```dart
  /// // Start from a preset, change only what you need
  /// AiPreset.chat.copyWith(role: 'Egyptian culture guide')
  /// AiPreset.summarizer.copyWith(maxItems: 5, tone: ResponseTone.formal)
  /// ```
  Prompt copyWith({
    String? role,
    String? goal,
    List<String>? constraints,
    ResponseFormat? format,
    ResponseLanguage? language,
    ResponseTone? tone,
    int? maxItems,
    String? audience,
    String? context,
    List<PromptExample>? examples,
    StopSignalMode? stopSignalMode,
    String? customStopSignal,
  }) =>
      Prompt(
        role: role ?? this.role,
        goal: goal ?? this.goal,
        constraints: constraints ?? this.constraints,
        format: format ?? this.format,
        language: language ?? this.language,
        tone: tone ?? this.tone,
        maxItems: maxItems ?? this.maxItems,
        audience: audience ?? this.audience,
        context: context ?? this.context,
        examples: examples ?? this.examples,
        stopSignalMode: stopSignalMode ?? this.stopSignalMode,
        customStopSignal: customStopSignal ?? this.customStopSignal,
      );

  /// Builds and returns the final system prompt string.
  ///
  /// Pass [userMessage] to enable [ResponseLanguage.auto] detection —
  /// the model will reply in the same language the user wrote in.
  ///
  /// Call this once and pass the result to [GeminiConfig.systemPrompt]:
  ///
  /// ```dart
  /// // Fixed language — build once at init
  /// GeminiConfig(
  ///   systemPrompt: Prompt(role: 'game assistant').build(),
  /// )
  ///
  /// // Auto language — build on each request with the user's message
  /// GeminiConfig(
  ///   systemPrompt: Prompt(
  ///     role: 'game assistant',
  ///     language: ResponseLanguage.auto,
  ///   ).build(userMessage: message),
  /// )
  /// ```
  String build({String? userMessage}) =>
      PromptBuilder.fromPrompt(this).build(userMessage: userMessage);
}
