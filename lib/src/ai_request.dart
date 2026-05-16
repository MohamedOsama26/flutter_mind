import 'package:flutter_mind/src/core/configs/ai_config.dart';
import 'package:flutter_mind/src/core/models/chat_message.dart';

/// Represents a single request sent to an AI engine.
///
/// Built internally before every [AiEngine.send] or [AiEngine.stream] call.
/// Developers never create this directly.
class AiRequest {
  const AiRequest({
    required this.userMessage,
    required this.config,
    this.history,
    this.maxHistoryMessages = 20,
  });

  /// The final user message sent to the model.
  final String userMessage;

  /// The resolved configuration for this request.
  final AiConfig config;

  /// Previous conversation turns, oldest first.
  ///
  /// `null` means this is a stateless single-turn request.
  final List<ChatMessage>? history;

  /// Maximum number of history messages to include in the request.
  final int maxHistoryMessages;

  @override
  String toString() => 'AiRequest(model: ${config.model.value}, '
      'messageLength: ${userMessage.length}, '
      'historyLength: ${history?.length ?? 0})';
}
