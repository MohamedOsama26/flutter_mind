part of 'ai_model.dart';

/// Known Google Gemini text generation models.
///
/// All models accept multimodal inputs (Text, Image, Video, Audio, PDF)
/// and return Text output only.
///
/// For image generation use `GeminiImageModel` (flutter_mind_vision).
/// For live audio use `GeminiLiveModel` (flutter_mind_audio).
/// For text-to-speech use `GeminiTtsModel` (flutter_mind_audio).
///
/// For any model not listed here use [CustomModel]:
/// ```dart
/// GeminiEngine(
///   apiKey: 'key',
///   model: CustomModel('gemini-4.0-ultra'),
/// )
/// ```
final class GeminiModel extends AiModel {
  const GeminiModel._(
    this.value, {
    this.capabilities = const <Capability>{},
  });

  @override
  final String value;

  @override
  final Set<Capability> capabilities;


  /// Gemini 2.5 Flash — best price-performance balance. ✅ Stable
  ///
  /// **Inputs:** Text, Image, Video, Audio
  /// **Output:** Text only
  ///
  /// **Tokens:** 1,048,576 input / 65,536 output
  ///
  /// **Supports:** Function calling, Structured outputs, Thinking,
  /// Search grounding, Code execution, URL context, File search
  ///
  /// **Does not support:** Image generation, Live API, Audio generation
  ///
  /// **Knowledge cutoff:** January 2025
  ///
  /// Best for: high-volume tasks, reasoning, agentic workflows.
  ///
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-2.5-flash
  static const flash25 = GeminiModel._(
    'gemini-2.5-flash',
    capabilities: {
      Capability.functionCalling,
      Capability.structuredOutputs,
      Capability.thinking,
      Capability.searchGrounding,
      Capability.codeExecution,
      Capability.urlContext,
      Capability.fileSearch,
    },
  );

  /// Gemini 2.5 Flash-Lite — fastest and most affordable model. ✅ Stable
  ///
  /// **Inputs:** Text, Image, Video, Audio, PDF
  /// **Output:** Text only
  ///
  /// **Tokens:** 1,048,576 input / 65,536 output
  ///
  /// **Supports:** Function calling, Structured outputs, Thinking,
  /// Search grounding, Code execution, URL context, File search
  ///
  /// **Does not support:** Image generation, Live API, Audio generation
  ///
  /// **Knowledge cutoff:** January 2025
  ///
  /// Best for: classification, simple extraction, extreme low-latency apps.
  ///
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-2.5-flash-lite
  static const flash25Lite = GeminiModel._(
    'gemini-2.5-flash-lite',
    capabilities: {
      Capability.functionCalling,
      Capability.structuredOutputs,
      Capability.thinking,
      Capability.searchGrounding,
      Capability.codeExecution,
      Capability.urlContext,
      Capability.fileSearch,
    },
  );

  /// Gemini 2.5 Pro — most advanced reasoning model. ✅ Stable
  ///
  /// **Inputs:** Text, Image, Video, Audio, PDF
  /// **Output:** Text only
  ///
  /// **Tokens:** 1,048,576 input / 65,536 output
  ///
  /// **Supports:** Function calling, Structured outputs, Thinking,
  /// Search grounding, Code execution, URL context, File search
  ///
  /// **Does not support:** Image generation, Live API, Audio generation
  ///
  /// **Knowledge cutoff:** January 2025
  ///
  /// Best for: complex reasoning, math, code, large document analysis.
  ///
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-2.5-pro
  static const pro25 = GeminiModel._(
    'gemini-2.5-pro',
    capabilities: {
      Capability.functionCalling,
      Capability.structuredOutputs,
      Capability.thinking,
      Capability.searchGrounding,
      Capability.codeExecution,
      Capability.urlContext,
      Capability.fileSearch,
    },
  );

  /// Gemini 3 Flash Preview — frontier-class performance at low cost. ⚠️ Preview
  ///
  /// **Inputs:** Text, Image, Video, Audio, PDF
  /// **Output:** Text only
  ///
  /// **Tokens:** 1,048,576 input / 65,536 output
  ///
  /// **Supports:** Function calling, Structured outputs, Thinking,
  /// Search grounding, Code execution, URL context, Computer use, File search
  ///
  /// **Does not support:** Image generation, Live API, Audio generation
  ///
  /// **Knowledge cutoff:** January 2025
  ///
  /// ⚠️ Preview — may have breaking changes. Not recommended for production.
  ///
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-3-flash-preview
  static const flash3Preview = GeminiModel._(
    'gemini-3-flash-preview',
    capabilities: {
      Capability.functionCalling,
      Capability.structuredOutputs,
      Capability.thinking,
      Capability.searchGrounding,
      Capability.codeExecution,
      Capability.urlContext,
      Capability.computerUse,
      Capability.fileSearch,
    },
  );

  /// Gemini 3.1 Flash-Lite — stable low-latency Gemini 3 model. ✅ Stable
  ///
  /// **Inputs:** Text, Image, Video, Audio, PDF
  /// **Output:** Text only
  ///
  /// **Tokens:** 1,048,576 input / 65,536 output
  ///
  /// **Supports:** Function calling, Structured outputs, Thinking,
  /// Search grounding, Code execution, URL context, File search
  ///
  /// **Does not support:** Image generation, Live API, Audio generation,
  /// Computer use
  ///
  /// **Knowledge cutoff:** January 2025
  ///
  /// Best for: translation, transcription, lightweight agentic tasks,
  /// document summarization, high-volume data extraction.
  ///
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite
  static const flash31Lite = GeminiModel._(
    'gemini-3.1-flash-lite',
    capabilities: {
      Capability.functionCalling,
      Capability.structuredOutputs,
      Capability.thinking,
      Capability.searchGrounding,
      Capability.codeExecution,
      Capability.urlContext,
      Capability.fileSearch,
    },
  );

  /// Gemini 3.1 Flash-Lite Preview — preview version of Flash-Lite. ⚠️ Preview
  ///
  /// **Inputs:** Text, Image, Video, Audio, PDF
  /// **Output:** Text only
  ///
  /// **Tokens:** 1,048,576 input / 65,536 output
  ///
  /// **Supports:** Function calling, Structured outputs, Thinking,
  /// Search grounding, Code execution, URL context, File search
  ///
  /// **Does not support:** Image generation, Live API, Audio generation
  ///
  /// **Knowledge cutoff:** January 2025
  ///
  /// ⚠️ Preview — may have breaking changes. Prefer [flash31Lite] for production.
  ///
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite-preview
  static const flash31LitePreview = GeminiModel._(
    'gemini-3.1-flash-lite-preview',
    capabilities: {
      Capability.functionCalling,
      Capability.structuredOutputs,
      Capability.thinking,
      Capability.searchGrounding,
      Capability.codeExecution,
      Capability.urlContext,
      Capability.fileSearch,
    },
  );

  /// Gemini 3.1 Pro Preview — most powerful Gemini model. ⚠️ Preview
  ///
  /// **Inputs:** Text, Image, Video, Audio, PDF
  /// **Output:** Text only
  ///
  /// **Tokens:** 1,048,576 input / 65,536 output
  ///
  /// **Supports:** Function calling, Structured outputs, Thinking,
  /// Search grounding, Code execution, URL context, File search
  ///
  /// **Does not support:** Image generation, Live API, Audio generation
  ///
  /// **Knowledge cutoff:** January 2025
  ///
  /// For agentic workflows mixing bash and custom tools,
  /// prefer [pro31PreviewCustomTools].
  ///
  /// ⚠️ Preview — may have breaking changes. Not recommended for production.
  ///
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-3.1-pro-preview
  static const pro31Preview = GeminiModel._(
    'gemini-3.1-pro-preview',
    capabilities: {
      Capability.functionCalling,
      Capability.structuredOutputs,
      Capability.thinking,
      Capability.searchGrounding,
      Capability.codeExecution,
      Capability.urlContext,
      Capability.fileSearch,
    },
  );

  /// Gemini 3.1 Pro Preview (Custom Tools) — optimized for agentic workflows. ⚠️ Preview
  ///
  /// **Inputs:** Text, Image, Video, Audio, PDF
  /// **Output:** Text only
  ///
  /// **Tokens:** 1,048,576 input / 65,536 output
  ///
  /// Same capabilities as [pro31Preview] but tuned to prioritize
  /// custom tools (e.g. `view_file`, `search_code`) mixed with bash.
  ///
  /// ⚠️ May show quality fluctuations in non-agentic use cases.
  /// Prefer [pro31Preview] for general use.
  ///
  /// ⚠️ Preview — may have breaking changes. Not recommended for production.
  ///
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-3.1-pro-preview
  static const pro31PreviewCustomTools = GeminiModel._(
    'gemini-3.1-pro-preview-customtools',
    capabilities: {
      Capability.functionCalling,
      Capability.structuredOutputs,
      Capability.thinking,
      Capability.searchGrounding,
      Capability.codeExecution,
      Capability.urlContext,
      Capability.fileSearch,
    },
  );
}