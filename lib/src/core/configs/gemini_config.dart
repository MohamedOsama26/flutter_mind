part of 'ai_config.dart';

/// Configuration for Google Gemini text generation requests.
///
/// Controls every aspect of how [GeminiEngine] generates responses — which
/// model to use, how creative the output is, how long it can be, whether it
/// thinks before answering, and more.
///
/// Set once on the engine as a default, then optionally override individual
/// fields per call. You never need to repeat config across calls.
///
/// ```dart
/// // Set defaults once
/// final gemini = GeminiEngine(
///   apiKey: 'AIza...',
///   config: GeminiConfig(
///     model: GeminiModel.flash25,
///     systemPrompt: 'You are a game suggestion assistant.',
///     temperature: 0.7,
///   ),
/// );
///
/// // No config needed for regular calls
/// final response = await gemini.send(userMessage: 'suggest a game');
///
/// // Override only what changes for this one call
/// final response = await gemini.send(
///   userMessage: 'solve this equation',
///   config: GeminiConfig(
///     model: GeminiModel.pro25,
///     thinkingLevel: ThinkingLevel.deep,
///     temperature: 0.1,
///   ),
/// );
/// ```
///
/// ## Parameter reference
///
/// | Parameter         | What it controls               | Most apps need it?   |
/// |-------------------|--------------------------------|----------------------|
/// | [model]           | Which Gemini model to use      | ✅ Always            |
/// | [systemPrompt]    | AI persona and instructions    | ✅ Always            |
/// | [temperature]     | Creativity level               | ✅ Always            |
/// | [maxOutputTokens] | Max response length            | ✅ Recommended       |
/// | [stopSequences]   | When to stop early             | ⚠️ Sometimes        |
/// | [thinkingLevel]   | Reasoning depth before answer  | ⚠️ Sometimes        |
/// | [responseMimeType]| Force JSON or plain text       | ⚠️ Sometimes        |
/// | [responseSchema]  | JSON structure the model follows| ⚠️ Sometimes       |
/// | [topP]            | Creativity control (advanced)  | ❌ Leave default     |
/// | [topK]            | Creativity control (advanced)  | ❌ Leave default     |
/// | [candidateCount]  | Number of responses to generate| ❌ Rarely            |
/// | [seed]            | Reproducible output for testing| ❌ Testing only      |
/// | [presencePenalty] | Topic variety in long responses| ❌ Rarely            |
/// | [frequencyPenalty]| Word variety in long responses | ❌ Rarely            |
///
/// **API reference:** https://ai.google.dev/api/generate-content#generationconfig
final class GeminiConfig extends AiConfig {
  /// Creates a Gemini generation configuration.
  ///
  /// All parameters are optional — any unset field falls back to the engine's
  /// [GeminiEngine._defaultConfig], which itself falls back to smart defaults.
  ///
  /// The only exception is [model] — it is required to ensure you always know
  /// which Gemini model is being used.
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
    this.thinkingLevel,
    this.responseMimeType,
    this.responseSchema,
    this.candidateCount,
    this.seed,
    this.presencePenalty,
    this.frequencyPenalty,
  }) : assert(
          model is GeminiModel || model is CustomModel,
          'GeminiConfig.model must be a GeminiModel or CustomModel',
        );

  /// Top-K sampling — an advanced creativity control specific to Gemini.
  ///
  /// At each generation step the model picks from only the top K most probable
  /// tokens. Lower K = more focused and predictable output. Higher K = wider
  /// vocabulary, more varied output.
  ///
  /// **Most apps should leave this unset.** Use [temperature] to control
  /// creativity — it is simpler and covers most use cases. Only reach for
  /// [topK] if you have a specific reason to constrain the token pool.
  ///
  /// Do not set both [topK] and [topP] at the same time.
  ///
  /// Range: 1 – 64 | Default: 64
  final int? topK;

  /// How deeply the model reasons before writing its response.
  ///
  /// Gemini can silently "think through" a problem before answering. The model
  /// spends thinking tokens internally — you never see them in the response
  /// unless you read [AiResponse.thinkingText]. More thinking = better answers
  /// on hard problems, but slower and more expensive.
  ///
  /// Use the presets from [ThinkingLevel] for most cases:
  ///
  /// ```dart
  /// thinkingLevel: ThinkingLevel.none      // no thinking — fastest, cheapest
  /// thinkingLevel: ThinkingLevel.light     // quick reasoning, minimal cost
  /// thinkingLevel: ThinkingLevel.moderate  // balanced — good for coding, math
  /// thinkingLevel: ThinkingLevel.deep      // complex problems, slower
  /// thinkingLevel: ThinkingLevel.max       // hardest problems, most expensive
  /// ```
  ///
  /// Or use [CustomThinkingBudget] for a precise token count:
  ///
  /// ```dart
  /// thinkingLevel: CustomThinkingBudget(tokens: 1000)
  /// ```
  ///
  /// Only effective on models that support thinking:
  /// [GeminiModel.pro25], [GeminiModel.flash25], etc.
  ///
  /// See [ThinkingBudget] for the full comparison table.
  final ThinkingBudget? thinkingLevel;

  /// Forces the model to respond in a specific format.
  ///
  /// The most useful value is `'application/json'` — the model always returns
  /// valid, parseable JSON. Perfect for apps that need to read structured data
  /// from the AI response rather than free text.
  ///
  /// Supported values:
  /// - `'text/plain'` — default, free-form text
  /// - `'application/json'` — always valid JSON
  /// - `'text/x.enum'` — constrain to a specific set of enum values
  ///
  /// When using JSON, pair with [responseSchema] to lock down the exact shape
  /// of the object the model returns:
  ///
  /// ```dart
  /// GeminiConfig(
  ///   model: GeminiModel.flash25,
  ///   responseMimeType: 'application/json',
  ///   responseSchema: {
  ///     'type': 'object',
  ///     'properties': {
  ///       'name': {'type': 'string'},
  ///       'score': {'type': 'integer'},
  ///     },
  ///     'required': ['name', 'score'],
  ///   },
  /// )
  /// ```
  ///
  /// Only effective on models with [Capability.structuredOutputs].
  final String? responseMimeType;

  /// The exact JSON structure the model must follow in its response.
  ///
  /// Only used when [responseMimeType] is `'application/json'`. The model
  /// cannot deviate from this shape — it is guaranteed to return an object
  /// that matches the schema.
  ///
  /// Follows OpenAPI 3.0 schema format. Example — always return a user object:
  ///
  /// ```dart
  /// responseSchema: {
  ///   'type': 'object',
  ///   'properties': {
  ///     'name':  {'type': 'string'},
  ///     'age':   {'type': 'integer'},
  ///     'email': {'type': 'string'},
  ///   },
  ///   'required': ['name', 'age'],
  /// }
  /// ```
  ///
  /// The model will always respond with `{"name": "...", "age": ..., ...}` —
  /// never missing fields, never in a different shape.
  final Map<String, dynamic>? responseSchema;

  /// How many different responses to generate for the same message.
  ///
  /// The model runs [candidateCount] independent completions and returns all
  /// of them. Each candidate costs the same as a full request — setting this
  /// to 3 triples your token usage.
  ///
  /// **Most apps never need this.** It is occasionally useful for:
  /// - Showing the user multiple options to choose from
  /// - A/B testing prompt variations
  /// - Creative tasks where variety matters
  ///
  /// Range: 1 – 8 | Default: 1
  final int? candidateCount;

  /// A number that makes the model's output repeatable.
  ///
  /// Same [seed] + same [GeminiConfig] + same message = same response every
  /// time. Without a seed, the model varies slightly across calls even with
  /// identical input.
  ///
  /// **Only useful for testing.** In production, leave this unset so responses
  /// feel natural and varied.
  ///
  /// Example:
  /// ```dart
  /// // In your test — always get the same answer
  /// GeminiConfig(model: GeminiModel.flash25, seed: 42)
  /// ```
  final int? seed;

  /// Penalises the model for introducing topics it has already covered.
  ///
  /// A positive value pushes the model to bring up new subjects rather than
  /// circling back to ones it already mentioned. Useful for long responses
  /// where you want broad coverage rather than repetition of the same ideas.
  ///
  /// A negative value does the opposite — the model stays on the same topics.
  ///
  /// **Most apps do not need this.** Only relevant for long-form content
  /// generation where topic variety matters.
  ///
  /// Range: -2.0 – 2.0 | Default: 0.0
  final double? presencePenalty;

  /// Penalises the model for repeating the same words it has already used.
  ///
  /// A positive value reduces word repetition — the model reaches for synonyms
  /// and varied phrasing. Useful for long creative responses where you do not
  /// want the same word appearing over and over.
  ///
  /// A negative value allows more repetition.
  ///
  /// **Most apps do not need this.** Only relevant for long creative or
  /// essay-style generation.
  ///
  /// Range: -2.0 – 2.0 | Default: 0.0
  final double? frequencyPenalty;

  /// Returns a copy of this config with the given fields replaced.
  ///
  /// Any field you pass overrides the current value.
  /// Any field you omit keeps its current value.
  ///
  /// ```dart
  /// final base = GeminiConfig(model: GeminiModel.flash25, temperature: 0.7);
  /// final creative = base.copyWith(temperature: 1.5);
  /// final json = base.copyWith(responseMimeType: 'application/json');
  /// ```
  GeminiConfig copyWith({
    AiModel? model,
    Prompt? systemPrompt,
    double? temperature,
    int? maxOutputTokens,
    List<String>? stopSequences,
    double? topP,
    int? topK,
    ThinkingBudget? thinkingLevel,
    String? responseMimeType,
    Map<String, dynamic>? responseSchema,
    int? candidateCount,
    int? seed,
    double? presencePenalty,
    double? frequencyPenalty,
  }) {
    return GeminiConfig(
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      stopSequences: stopSequences ?? this.stopSequences,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      thinkingLevel: thinkingLevel ?? this.thinkingLevel,
      responseMimeType: responseMimeType ?? this.responseMimeType,
      responseSchema: responseSchema ?? this.responseSchema,
      candidateCount: candidateCount ?? this.candidateCount,
      seed: seed ?? this.seed,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
    );
  }
}
