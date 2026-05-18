import 'package:flutter_mind/src/core/parser/message_analyzer.dart';
import 'package:flutter_mind/src/core/parser/prompt_config.dart';
import 'package:flutter_mind/src/core/parser/prompt_example.dart';
import 'package:flutter_mind/src/core/parser/response_format.dart';
import 'package:flutter_mind/src/core/parser/response_language.dart';
import 'package:flutter_mind/src/core/parser/response_tone.dart';
import 'package:flutter_mind/src/core/parser/stop_signal_mode.dart';

/// Assembles a system prompt string from individual settings.
///
/// Two ways to use this package's prompt system:
///
/// **Option 1 — [Prompt] data class (recommended for most apps)**
/// ```dart
/// systemPrompt: Prompt(
///   role: 'game assistant',
///   format: ResponseFormat.numberedList,
///   maxItems: 3,
/// ).build(userMessage: message),
/// ```
///
/// **Option 2 — [PromptBuilder] fluent API (for dynamic prompts)**
/// ```dart
/// final builder = PromptBuilder().role('game assistant');
/// if (isKidsApp) builder.constraint('no violent games');
/// if (egyptOnly) builder.constraint('available in Egypt');
///
/// systemPrompt: builder.build(userMessage: message),
/// ```
///
/// Both produce the same output — choose based on your preference.
/// [PromptBuilder] is what [Prompt.build] uses internally.
class PromptBuilder {
  String? _role;
  String? _goal;
  List<String> _constraints = [];
  ResponseFormat _format = ResponseFormat.paragraph;
  ResponseLanguage _language = ResponseLanguage.auto;
  ResponseTone _tone = ResponseTone.casual;
  int? _maxItems;
  String? _audience;
  String? _context;
  List<PromptExample> _examples = [];
  StopSignalMode _stopSignal = StopSignalMode.auto;
  String? _customStopSignal;


  /// Creates a [PromptBuilder] pre-filled from a [Prompt] data class.
  ///
  /// Used internally by [Prompt.build] — you rarely need to call this directly.
  static PromptBuilder fromPrompt(Prompt prompt) {
    final b = PromptBuilder();
    if (prompt.role != null) b.role(prompt.role!);
    if (prompt.goal != null) b.goal(prompt.goal!);
    if (prompt.constraints.isNotEmpty) b.constraints(prompt.constraints);
    b.format(prompt.format);
    b.language(prompt.language);
    b.tone(prompt.tone);
    if (prompt.maxItems != null) b.maxItems(prompt.maxItems!);
    if (prompt.audience != null) b.audience(prompt.audience!);
    if (prompt.context != null) b.context(prompt.context!);
    if (prompt.examples.isNotEmpty) b.examples(prompt.examples);
    b.stopSignal(prompt.stopSignalMode, signal: prompt.customStopSignal);
    return b;
  }


  /// Who the AI is in this app — the most impactful field.
  ///
  /// ```dart
  /// .role('mobile game suggestion assistant')
  /// .role('Egyptian local discovery guide')
  /// ```
  PromptBuilder role(String role) {
    _role = role;
    return this;
  }

  /// What the AI should achieve in every response.
  ///
  /// ```dart
  /// .goal('suggest games that match the user mood and age group')
  /// ```
  PromptBuilder goal(String goal) {
    _goal = goal;
    return this;
  }

  /// Rules the model must always follow — replaces the full list.
  ///
  /// ```dart
  /// .constraints(['mobile only', 'no violent games', 'available in Egypt'])
  /// ```
  PromptBuilder constraints(List<String> constraints) {
    _constraints = constraints;
    return this;
  }

  /// Adds a single constraint to the existing list.
  ///
  /// Use for building constraints dynamically at runtime:
  ///
  /// ```dart
  /// if (isKidsApp) builder.constraint('no violent games');
  /// if (egyptOnly) builder.constraint('available in Egypt');
  /// ```
  PromptBuilder constraint(String constraint) {
    _constraints.add(constraint);
    return this;
  }

  /// How the response should be structured.
  ///
  /// ```dart
  /// .format(ResponseFormat.numberedList) // game suggestions
  /// .format(ResponseFormat.steps)        // how-to instructions
  /// .format(ResponseFormat.json)         // structured data
  /// .format(ResponseFormat.oneSentence)  // quick answers
  /// ```
  PromptBuilder format(ResponseFormat format) {
    _format = format;
    return this;
  }

  /// Maximum number of items in list or steps responses.
  ///
  /// Only applies when [format] is a list type.
  ///
  /// ```dart
  /// .format(ResponseFormat.numberedList)
  /// .maxItems(3) // model returns exactly 3 — no more, no less
  /// ```
  PromptBuilder maxItems(int count) {
    assert(count > 0, 'FlutterMind: maxItems must be greater than 0');
    _maxItems = count;
    return this;
  }

  /// Language the model should respond in.
  ///
  /// ```dart
  /// .language(ResponseLanguage.auto)   // detects from user message
  /// .language(ResponseLanguage.arabic) // always Arabic
  /// ```
  PromptBuilder language(ResponseLanguage language) {
    _language = language;
    return this;
  }

  /// Personality and style of the responses.
  ///
  /// ```dart
  /// .tone(ResponseTone.friendly) // consumer apps
  /// .tone(ResponseTone.formal)   // business apps
  /// .tone(ResponseTone.concise)  // utilities
  /// ```
  PromptBuilder tone(ResponseTone tone) {
    _tone = tone;
    return this;
  }

  /// Who the end users of this app are.
  ///
  /// ```dart
  /// .audience('Egyptian teenagers')
  /// .audience('senior Flutter developers')
  /// ```
  PromptBuilder audience(String audience) {
    _audience = audience;
    return this;
  }

  /// Additional context about the app or market.
  ///
  /// ```dart
  /// .context('Egyptian mobile gaming market')
  /// ```
  PromptBuilder context(String context) {
    _context = context;
    return this;
  }

  /// Input/output examples for few-shot prompting. See [PromptExample].
  ///
  /// ```dart
  /// .examples([
  ///   PromptExample(input: 'fun game', output: 'Hollow Knight — platformer'),
  ///   PromptExample(input: 'relaxing game', output: 'Stardew Valley — farming'),
  /// ])
  /// ```
  PromptBuilder examples(List<PromptExample> examples) {
    _examples = examples;
    return this;
  }

  /// Controls when the model stops generating.
  ///
  /// ```dart
  /// .stopSignal(StopSignalMode.auto)                     // recommended
  /// .stopSignal(StopSignalMode.manual, signal: '[DONE]') // custom
  /// .stopSignal(StopSignalMode.none)                     // no stop signal
  /// ```
  PromptBuilder stopSignal(StopSignalMode mode, {String? signal}) {
    _stopSignal = mode;
    _customStopSignal = signal;
    return this;
  }


  /// Builds the final system prompt string.
  ///
  /// Pass [userMessage] to enable [ResponseLanguage.auto] detection.
  ///
  /// ```dart
  /// GeminiConfig(
  ///   systemPrompt: PromptBuilder()
  ///     .role('game assistant')
  ///     .format(ResponseFormat.numberedList)
  ///     .maxItems(3)
  ///     .build(userMessage: message),
  /// )
  /// ```
  String build({String? userMessage}) {
    final buffer = StringBuffer();

    // Role
    buffer.writeln(_role != null
        ? 'You are a $_role.'
        : 'You are a helpful assistant.');

    // Goal
    if (_goal != null && _goal!.isNotEmpty) {
      buffer.writeln('Your goal is to $_goal.');
    }

    // Audience
    if (_audience != null && _audience!.isNotEmpty) {
      buffer.writeln('You are speaking to $_audience.');
    }

    // Context
    if (_context != null && _context!.isNotEmpty) {
      buffer.writeln('Context: $_context.');
    }

    // Tone
    buffer.writeln(_tone.instruction);

    // Constraints
    if (_constraints.isNotEmpty) {
      buffer.writeln('\nRules you must always follow:');
      for (final c in _constraints) {
        buffer.writeln('- $c');
      }
    }

    // Format
    buffer.writeln('\n${_format.instruction}');
    if (_maxItems != null && _format.isList) {
      buffer.writeln(
        'Return exactly $_maxItems ${_maxItems == 1 ? 'item' : 'items'}. '
        'No more, no less.',
      );
    }

    // Examples
    if (_examples.isNotEmpty) {
      buffer.writeln('\nExamples of what I expect:');
      for (final e in _examples) {
        buffer.writeln('Input: ${e.input}');
        buffer.writeln('Output: ${e.output}');
      }
    }

    // Language — resolve auto at build time using the user's message
    final resolvedLanguage =
        _language == ResponseLanguage.auto && userMessage != null
            ? MessageAnalyzer.detectLanguage(userMessage)
            : _language;

    if (resolvedLanguage != ResponseLanguage.auto &&
        resolvedLanguage.instruction.isNotEmpty) {
      buffer.writeln('\n${resolvedLanguage.instruction}');
    }

    // Stop signal
    final stopWord = _resolveStopSignal();
    if (stopWord != null) {
      buffer.writeln('\nWrite $stopWord at the very end of your response.');
    }

    // No padding
    buffer.writeln(
      '\nDo not include greetings, apologies, disclaimers, '
      'or unnecessary explanations.',
    );

    return buffer.toString().trim();
  }

  /// Returns the stop sequences to pass to [GeminiConfig.stopSequences].
  ///
  /// Use alongside [build] so the model actually halts at the signal:
  ///
  /// ```dart
  /// final builder = PromptBuilder().role('game assistant').maxItems(3);
  ///
  /// GeminiConfig(
  ///   systemPrompt: builder.build(),
  ///   stopSequences: builder.buildStopSequences(),
  /// )
  /// ```
  List<String>? buildStopSequences() {
    final stopWord = _resolveStopSignal();
    return stopWord == null ? null : [stopWord];
  }


  String? _resolveStopSignal() => switch (_stopSignal) {
        StopSignalMode.none   => null,
        StopSignalMode.manual => _customStopSignal,
        StopSignalMode.auto   => _format.isList && _maxItems != null
                                  ? '[END]'
                                  : null,
      };
}
