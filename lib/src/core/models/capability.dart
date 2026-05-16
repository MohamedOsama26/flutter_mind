/// A feature that an AI model may or may not support.
///
/// Used by flutter_mind to describe what each model can do.
/// Check a model's capabilities before using advanced features:
///
/// ```dart
/// if (GeminiModel.flash25.supports(Capability.thinking)) {
///   // safe to set thinkingLevel
/// }
///
/// if (GeminiModel.flash25.supports(Capability.structuredOutputs)) {
///   // safe to set responseMimeType = 'application/json'
/// }
/// ```
enum Capability {
  /// Model can generate audio output (text-to-speech).
  audioGeneration,

  /// Model supports the Batch API for sending large numbers of requests
  /// asynchronously at a lower cost.
  batchAPI,

  /// Model supports prompt caching — reusing previously processed input
  /// to reduce cost and latency on repeated requests.
  caching,

  /// Model can write and execute code internally and return the result.
  ///
  /// The model runs code in a sandboxed environment and includes
  /// the output in its response.
  codeExecution,

  /// Model can control a computer — click, type, scroll, take screenshots.
  ///
  /// Used for agentic workflows where the AI operates a UI on your behalf.
  computerUse,

  /// Model can search through uploaded files and return relevant content.
  fileSearch,

  /// Model supports flex inference — a lower-cost serving tier with
  /// variable latency, suitable for non-time-sensitive workloads.
  flexInference,

  /// Model supports function calling — the model can call functions
  /// you define and return structured arguments for your code to execute.
  ///
  /// Also known as "tool use."
  functionCalling,

  /// Model supports grounding responses with Google Maps data —
  /// location-aware answers with real-world place information.
  groundingWithGoogleMaps,

  /// Model can generate images as output.
  imageGeneration,

  /// Model supports the Live API — real-time bidirectional audio/video
  /// streaming directly with the model.
  liveAPI,

  /// Model supports priority inference — a higher-cost serving tier
  /// with guaranteed lower latency.
  priorityInference,

  /// Model can ground its responses using Google Search —
  /// answers are backed by real, up-to-date web results.
  searchGrounding,

  /// Model can return structured output (e.g. always-valid JSON)
  /// constrained by a schema you provide.
  ///
  /// Required for [GeminiConfig.responseMimeType] and [GeminiConfig.responseSchema].
  structuredOutputs,

  /// Model supports internal reasoning (thinking) before responding.
  ///
  /// Required for [GeminiConfig.thinkingLevel] to have any effect.
  thinking,

  /// Model can fetch and read content from URLs you provide in the prompt,
  /// using it as context when generating the response.
  urlContext,
}
