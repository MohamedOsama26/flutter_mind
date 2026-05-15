import 'package:flutter_mind/src/core/configs/ai_config.dart';

/// Represents a single request sent to an AI engine.
///
/// Built internally by [FlutterMindClient] before every [AiEngine.send]
/// or [AiEngine.stream] call. Developers never create this directly.
///
/// Contains the resolved configuration and the user message
/// after all processing (validation, beforeSend hook) is complete.
class AiRequest {
  const AiRequest({
    required this.userMessage,
    required this.config,
  });

  /// The final user message sent to the model.
  ///
  /// This is the processed message after:
  /// - Input validation
  /// - beforeSend hook injection (if any)
  final String userMessage;

  /// The resolved configuration for this request.
  ///
  /// Either the engine's [defaultConfig] or a per-call override
  /// merged with the default.
  final AiConfig config;

  @override
  String toString() => 'AiRequest(model: ${config.model.value}, '
      'messageLength: ${userMessage.length})';
}