part of 'ai_config.dart';

/// Configuration for Google Gemini text generation requests.
///
/// Controls how [GeminiEngine] generates responses. Set once on the engine
/// as a default, then optionally override per call.
///
/// ```dart
/// // Set as default on engine
/// final gemini = GeminiEngine(
///   apiKey: 'key',
///   defaultConfig: GeminiConfig(
///     model: GeminiModel.flash25,
///     temperature: 0.7,
///   ),
/// );
///
/// // Override per call
/// gemini.send(
///   userMessage: 'solve this',
///   config: GeminiConfig(
///     model: GeminiModel.pro25,
///     temperature: 0.1,
///     thinkingBudget: 2000,
///   ),
/// );
/// ```
///
/// **API reference:** https://ai.google.dev/api/generate-content#generationconfig
final class GeminiConfig extends AiConfig {
  /// Creates a Gemini generation configuration.
  ///
  /// All parameters are optional — any unset parameter uses the model default.
  ///
  /// Throws [AssertionError] in debug mode if [model] is not a
  /// [GeminiModel] or [CustomModel].
  const GeminiConfig({
    required super.model,
    super.systemPrompt,
    super.temperature,
    super.maxOutputTokens,
    super.stopSequences,
    super.topP,
    this.topK,
    this.thinkingBudget,
    this.responseMimeType,
    this.responseSchema,
    this.candidateCount,
    this.seed,
    this.presencePenalty,
    this.frequencyPenalty,
  }):assert(
    model is GeminiModel || model is CustomModel,
    'GeminiConfig.model must be a GeminiModel or CustomModel',
  );

  /// Top-K sampling — limits the token pool the model picks from.
  ///
  /// The model samples from the K most probable tokens at each step.
  /// Lower = more focused and deterministic, higher = more creative.
  ///
  /// Range: 1 – 64
  /// Default: 64
  final int? topK;

  /// Random seed for deterministic output.
  ///
  /// Setting the same seed with the same config produces the same response.
  /// Useful for testing and reproducible results.
  ///
  /// If not set, output is non-deterministic.
  final int? seed;

  /// Penalizes tokens that have already appeared in the response.
  ///
  /// Positive values reduce repetition by making repeated tokens less likely.
  /// Negative values increase repetition.
  ///
  /// Range: -2.0 – 2.0
  /// Default: 0.0
  final double? presencePenalty;

  /// Penalizes tokens based on how frequently they appear in the response.
  ///
  /// Positive values reduce word repetition — good for long responses.
  /// Negative values allow more repetition.
  ///
  /// Range: -2.0 – 2.0
  /// Default: 0.0
  final double? frequencyPenalty;

  /// Number of response candidates to generate.
  ///
  /// The model generates this many responses and returns all of them.
  /// Higher values cost proportionally more tokens.
  ///
  /// Most use cases only need 1.
  /// Range: 1 – 8
  /// Default: 1
  final int? candidateCount;

  /// Token budget for internal model reasoning (thinking models only).
  ///
  /// Controls how many tokens the model spends thinking before responding.
  /// Higher values allow deeper reasoning but cost more tokens and take longer.
  ///
  /// Only effective on models with [Capability.thinking]:
  /// [GeminiModel.pro25], [GeminiModel.flash25], [GeminiModel.pro31Preview], etc.
  ///
  /// Set to 0 to disable thinking entirely.
  ///
  /// Range: 0 – model's output token limit
  final int? thinkingBudget;

  /// Forces the response to a specific MIME type.
  ///
  /// Use `'application/json'` to get structured JSON output.
  /// Use `'text/plain'` for plain text (default).
  /// Use `'text/x.enum'` to constrain output to enum values.
  ///
  /// Only effective on models with [Capability.structuredOutputs].
  ///
  /// When using JSON, pair with [responseSchema] for typed output.
  ///
  /// Example:
  /// ```dart
  /// GeminiConfig(
  ///   model: GeminiModel.flash25,
  ///   responseMimeType: 'application/json',
  ///   responseSchema: {'type': 'object', 'properties': {...}},
  /// )
  /// ```
  final String? responseMimeType;

  /// JSON schema that constrains the structure of the response.
  ///
  /// Only used when [responseMimeType] is `'application/json'`.
  /// Follows OpenAPI 3.0 schema format.
  ///
  /// The model will only return responses that match this schema.
  ///
  /// Example:
  /// ```dart
  /// responseSchema: {
  ///   'type': 'object',
  ///   'properties': {
  ///     'name': {'type': 'string'},
  ///     'age': {'type': 'integer'},
  ///   },
  ///   'required': ['name', 'age'],
  /// }
  /// ```
  final Map<String, dynamic>? responseSchema;
}
