import 'package:flutter_mind/src/core/models/ai_model.dart';
import 'package:flutter_mind/src/core/models/capability.dart';
import 'package:flutter_mind/src/core/models/thinking_budget.dart';
import 'package:flutter_mind/src/core/parser/prompt_config.dart';

part 'gemini_config.dart';
part 'open_ai_config.dart';
part 'claude_config.dart';
part 'custom_config.dart';
part 'local_config.dart';

/// Base configuration for all AI generation requests in flutter_mind.
///
/// Contains parameters supported by most providers.
/// Provider-specific parameters live in their own config class:
/// - [GeminiConfig] — Google Gemini
/// - [OpenAiConfig] — OpenAI GPT
/// - [ClaudeConfig] — Anthropic Claude
/// - [CustomConfig] — Custom models on any provider
/// - [LocalConfig] — Any local model
///
/// ```dart
/// // Use provider-specific config
/// final gemini = GeminiEngine(
///   apiKey: 'key',
///   config: GeminiConfig(
///     model: GeminiModel.flash25,
///     temperature: 0.7,
///   ),
/// );
/// ```
sealed class AiConfig {
  const AiConfig({
    this.model,
    this.systemPrompt,
    this.temperature,
    this.maxOutputTokens,
    this.stopSequences,
    this.topP,
  });

  /// The AI model to use for this request.
  ///
  /// Must match the engine type — e.g. [GeminiModel] for [GeminiEngine].
  /// Use [CustomModel] for any model not listed as a known constant.
  ///
  /// `null` in a per-call override means "inherit the engine's default model."
  final AiModel? model;

  /// System-level instructions that shape the model's behavior and persona.
  ///
  /// Set once per engine — defines how the model responds to all messages.
  /// Not visible to the end user.
  ///
  /// Example: `Prompt(role: 'game suggestion assistant for Egyptian Arabic speakers')`
  final Prompt? systemPrompt;

  /// Controls randomness of the output.
  ///
  /// Lower = more focused and deterministic.
  /// Higher = more creative and varied.
  ///
  /// Range: 0.0 – 2.0 (varies by provider)
  /// Default: 1.0
  ///
  /// Tip: adjust either [temperature] or [topP], not both.
  final double? temperature;

  /// Maximum number of tokens the model can generate in one response.
  ///
  /// One token ≈ 4 characters. Limiting this saves credits on long responses.
  ///
  /// If the model hits this limit it stops mid-response — set high enough
  /// for your use case.
  final int? maxOutputTokens;

  /// Sequences that signal the model to stop generating.
  ///
  /// When the model produces any of these strings it stops immediately,
  /// not including the stop sequence in the output.
  ///
  /// Example: `['END', '###']`
  final List<String>? stopSequences;

  /// Nucleus sampling threshold — controls output diversity.
  ///
  /// The model considers only tokens whose cumulative probability
  /// exceeds this value. Lower = more focused, higher = more random.
  ///
  /// Range: 0.0 – 1.0
  /// Default: 0.95
  ///
  /// Tip: adjust either [temperature] or [topP], not both.
  final double? topP;
}