part of '../../shared/ai_config.dart';

/// Configuration for OpenAI text generation requests via the Responses API.
///
/// Controls which model to use, how creative the output is, reasoning effort,
/// and more. Set once on the engine as a default, then optionally override
/// individual fields per call.
///
/// ```dart
/// // Set defaults once
/// final openai = OpenAiEngine(
///   apiKey: 'sk-...',
///   config: OpenAiConfig(
///     model: OpenAiModel.gpt55,
///     systemPrompt: Prompt(role: 'helpful assistant'),
///     temperature: 0.7,
///   ),
/// );
///
/// // No config needed for regular calls
/// final response = await openai.send(userMessage: 'suggest a game');
///
/// // Override only what changes for this one call
/// final response = await openai.send(
///   userMessage: 'solve this equation',
///   config: OpenAiConfig(
///     model: OpenAiModel.gpt55,
///     reasoningEffort: ReasoningEffort.high,
///     temperature: 0.1,
///   ),
/// );
/// ```
///
/// ## Parameter reference
///
/// | Parameter         | What it controls                        | Most apps need it?   |
/// |-------------------|-----------------------------------------|----------------------|
/// | [model]           | Which OpenAI model to use               | ✅ Always            |
/// | [systemPrompt]    | AI persona and instructions             | ✅ Always            |
/// | [temperature]     | Creativity level (0.0–2.0)              | ✅ Always            |
/// | [maxOutputTokens] | Max response length in tokens           | ✅ Recommended       |
/// | [reasoningEffort] | Reasoning depth before answering        | ⚠️ Sometimes        |
/// | [stopSequences]   | Strings that stop generation early      | ⚠️ Sometimes        |
/// | [topP]            | Creativity control (advanced)           | ❌ Leave default     |
/// | [seed]            | Reproducible output for testing         | ❌ Testing only      |
///
/// **API reference:** https://platform.openai.com/docs/api-reference/responses
final class OpenAiConfig extends AiConfig {
  /// Creates an OpenAI generation configuration.
  ///
  /// All parameters are optional. Unset fields fall back to the engine's
  /// default config, or to OpenAI's own defaults when neither specifies them.
  const OpenAiConfig({
    super.model,
    super.systemPrompt,
    super.temperature,
    super.maxOutputTokens,
    super.stopSequences,
    super.topP,
    this.reasoningEffort,
    this.responseFormat,
    this.topLogprobs,
    this.parallelToolCalls,
    this.seed,
  });

  /// Controls how much the model reasons before answering.
  ///
  /// Higher effort = better answers on hard problems, slower and more expensive.
  /// Only supported on reasoning-capable models (gpt-5.5, gpt-5.4, etc.).
  ///
  /// Leave `null` to let the model decide automatically.
  final ReasoningEffort? reasoningEffort;

  /// Controls the format of the model's text output.
  ///
  /// Use [OpenAiResponseFormat.text] for plain text (default).
  /// Use [OpenAiResponseFormat.jsonObject] when you need valid JSON but
  /// don't want to define the exact schema.
  /// Use [OpenAiResponseFormat.jsonSchema] when you need a guaranteed
  /// structure — the model's output will match your schema exactly.
  ///
  /// ```dart
  /// // Guarantee valid JSON
  /// OpenAiConfig(responseFormat: OpenAiResponseFormat.jsonObject())
  ///
  /// // Guarantee a specific structure
  /// OpenAiConfig(
  ///   responseFormat: OpenAiResponseFormat.jsonSchema(
  ///     name: 'movie',
  ///     schema: {
  ///       'type': 'object',
  ///       'properties': {
  ///         'title': {'type': 'string'},
  ///         'year':  {'type': 'integer'},
  ///       },
  ///       'required': ['title', 'year'],
  ///     },
  ///   ),
  /// )
  /// ```
  final OpenAiResponseFormat? responseFormat;

  /// Number of most-likely tokens (with log probabilities) to return
  /// alongside each output token.
  ///
  /// Range: 0–20. `null` disables logprobs entirely (the default).
  ///
  /// Useful for confidence scoring, beam search, or debugging model behavior.
  /// Adds data to the raw response; not surfaced in [AiResponse.text].
  final int? topLogprobs;

  /// Whether the model may execute tool calls in parallel.
  ///
  /// When `true` (the default when tools are available) the model can call
  /// multiple tools simultaneously. Set to `false` to force sequential calls,
  /// which is safer when tools have side effects that depend on each other.
  ///
  /// Has no effect until tools are added to the request.
  final bool? parallelToolCalls;

  /// Fixed seed for reproducible output.
  ///
  /// Useful for testing. When set, the model will attempt to return the same
  /// response for the same input. Not guaranteed — temperature still adds noise.
  final int? seed;

  /// Creates a copy of this config with updated fields.
  OpenAiConfig copyWith({
    AiModel? model,
    Prompt? systemPrompt,
    double? temperature,
    int? maxOutputTokens,
    List<String>? stopSequences,
    double? topP,
    ReasoningEffort? reasoningEffort,
    OpenAiResponseFormat? responseFormat,
    int? topLogprobs,
    bool? parallelToolCalls,
    int? seed,
  }) {
    return OpenAiConfig(
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      stopSequences: stopSequences ?? this.stopSequences,
      topP: topP ?? this.topP,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      responseFormat: responseFormat ?? this.responseFormat,
      topLogprobs: topLogprobs ?? this.topLogprobs,
      parallelToolCalls: parallelToolCalls ?? this.parallelToolCalls,
      seed: seed ?? this.seed,
    );
  }
}

/// Controls how deeply the model reasons before producing its response.
///
/// Only supported on reasoning-capable models (gpt-5.5, gpt-5.4, etc.).
///
/// ```dart
/// OpenAiConfig(
///   model: OpenAiModel.gpt55,
///   reasoningEffort: ReasoningEffort.high,
/// )
/// ```
enum ReasoningEffort {
  /// Minimal reasoning — fastest and cheapest.
  low,

  /// Balanced reasoning — good for most tasks.
  medium,

  /// Maximum reasoning — best for hard problems, coding, math.
  high,
}

/// Controls the format of the model's text output.
///
/// Use the named constructors to pick a format:
///
/// ```dart
/// // Plain text (default — no need to set this explicitly)
/// OpenAiResponseFormat.text()
///
/// // Valid JSON, any structure
/// OpenAiResponseFormat.jsonObject()
///
/// // Valid JSON matching an exact schema
/// OpenAiResponseFormat.jsonSchema(
///   name: 'movie',
///   schema: {
///     'type': 'object',
///     'properties': {
///       'title': {'type': 'string'},
///       'year':  {'type': 'integer'},
///     },
///     'required': ['title', 'year'],
///   },
/// )
/// ```
final class OpenAiResponseFormat {
  const OpenAiResponseFormat._({
    required this.type,
    this.schemaName,
    this.schema,
    this.strict,
  });

  /// Plain text output (the default).
  const OpenAiResponseFormat.text()
    : this._(type: 'text');

  /// Forces the model to return valid JSON, any structure.
  ///
  /// The model still needs to be told via the system prompt or user message
  /// to produce JSON — otherwise it may return an error.
  const OpenAiResponseFormat.jsonObject()
    : this._(type: 'json_object');

  /// Forces the model to return JSON that matches [schema] exactly.
  ///
  /// [name] is a label for the schema (shown in API logs).
  /// [schema] is a JSON Schema object describing the expected structure.
  /// [strict] — when `true` (default) the model guarantees schema compliance.
  ///
  /// ```dart
  /// OpenAiResponseFormat.jsonSchema(
  ///   name: 'sentiment',
  ///   schema: {
  ///     'type': 'object',
  ///     'properties': {
  ///       'label': {'type': 'string', 'enum': ['positive','negative','neutral']},
  ///       'score': {'type': 'number'},
  ///     },
  ///     'required': ['label', 'score'],
  ///   },
  /// )
  /// ```
  const OpenAiResponseFormat.jsonSchema({
    required String name,
    required Map<String, dynamic> schema,
    bool strict = true,
  }) : this._(
         type: 'json_schema',
         schemaName: name,
         schema: schema,
         strict: strict,
       );

  final String type;
  final String? schemaName;
  final Map<String, dynamic>? schema;
  final bool? strict;

  /// Converts this format to the `text.format` object the Responses API expects.
  Map<String, dynamic> toJson() {
    if (type == 'json_schema') {
      return {
        'type': 'json_schema',
        'json_schema': {
          'name': schemaName,
          'schema': schema,
          if (strict != null) 'strict': strict,
        },
      };
    }
    return {'type': type};
  }
}