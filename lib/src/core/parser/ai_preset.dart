import 'package:flutter_mind/src/core/parser/prompt_config.dart';
import 'package:flutter_mind/src/core/parser/response_format.dart';
import 'package:flutter_mind/src/core/parser/response_language.dart';
import 'package:flutter_mind/src/core/parser/response_tone.dart';

/// Ready-made [Prompt] presets for the most common AI use cases.
///
/// Each preset is a sensible starting point — use it as-is or customize
/// with [Prompt.copyWith] to fit your app.
///
/// Pass the [Prompt] object directly to [GeminiConfig.systemPrompt] —
/// the engine calls [Prompt.build] automatically per request:
///
/// ```dart
/// // Use directly
/// GeminiConfig(systemPrompt: AiPreset.chat)
///
/// // Customize one field
/// GeminiConfig(
///   systemPrompt: AiPreset.chat.copyWith(role: 'Egyptian culture guide'),
/// )
///
/// // Customize several fields
/// GeminiConfig(
///   systemPrompt: AiPreset.summarizer.copyWith(
///     maxItems: 5,
///     tone: ResponseTone.formal,
///     audience: 'business executives',
///   ),
/// )
/// ```
abstract final class AiPreset {
  /// General-purpose conversational assistant.
  ///
  /// Friendly tone, auto language detection, paragraph format.
  /// Good default for any chat feature.
  ///
  /// ```dart
  /// GeminiConfig(systemPrompt: AiPreset.chat)
  /// ```
  static const chat = Prompt(
    role: 'helpful and friendly assistant',
    tone: ResponseTone.friendly,
    format: ResponseFormat.paragraph,
    language: ResponseLanguage.auto,
  );

  /// Code generation and explanation assistant.
  ///
  /// Returns code blocks, concise tone, always in English.
  /// Good for developer tools, code review, or learning apps.
  ///
  /// ```dart
  /// GeminiConfig(systemPrompt: AiPreset.codeHelper)
  ///
  /// // Customize for a specific language
  /// GeminiConfig(
  ///   systemPrompt: AiPreset.codeHelper.copyWith(role: 'Flutter and Dart expert'),
  /// )
  /// ```
  static const codeHelper = Prompt(
    role: 'experienced software developer',
    goal: 'write clean, correct code and explain it clearly',
    tone: ResponseTone.concise,
    format: ResponseFormat.code,
    language: ResponseLanguage.english,
  );

  /// Text summarization assistant.
  ///
  /// Returns a bulleted list of key points, concise tone, auto language.
  /// Good for news apps, document readers, or content tools.
  ///
  /// ```dart
  /// GeminiConfig(systemPrompt: AiPreset.summarizer)
  ///
  /// // Limit bullet points
  /// GeminiConfig(
  ///   systemPrompt: AiPreset.summarizer.copyWith(maxItems: 5),
  /// )
  /// ```
  static const summarizer = Prompt(
    role: 'expert summarizer',
    goal: 'extract the key points clearly and concisely',
    tone: ResponseTone.concise,
    format: ResponseFormat.bulletedList,
    language: ResponseLanguage.auto,
  );

  /// Question answering assistant.
  ///
  /// Direct single-paragraph answers, auto language, friendly tone.
  /// Good for FAQ sections, help centers, or knowledge bases.
  ///
  /// ```dart
  /// GeminiConfig(systemPrompt: AiPreset.qa)
  ///
  /// // Add domain context
  /// GeminiConfig(
  ///   systemPrompt: AiPreset.qa.copyWith(context: 'Flutter mobile development'),
  /// )
  /// ```
  static const qa = Prompt(
    role: 'knowledgeable assistant who answers questions clearly',
    goal: 'give accurate, direct answers without unnecessary elaboration',
    tone: ResponseTone.friendly,
    format: ResponseFormat.paragraph,
    language: ResponseLanguage.auto,
  );

  /// Step-by-step instructions assistant.
  ///
  /// Returns numbered steps, concise tone, auto language.
  /// Good for how-to guides, tutorials, recipes, or onboarding flows.
  ///
  /// ```dart
  /// GeminiConfig(systemPrompt: AiPreset.stepByStep)
  ///
  /// // Limit number of steps
  /// GeminiConfig(
  ///   systemPrompt: AiPreset.stepByStep.copyWith(maxItems: 5),
  /// )
  /// ```
  static const stepByStep = Prompt(
    role: 'clear and precise instructor',
    goal: 'break down tasks into simple, actionable steps',
    tone: ResponseTone.concise,
    format: ResponseFormat.steps,
    language: ResponseLanguage.auto,
  );
}
