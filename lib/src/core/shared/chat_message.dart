/// A single turn in a multi-turn conversation.
///
/// Use [ChatMessage.user] for messages from the end user and
/// [ChatMessage.model] for previous responses from the AI.
///
/// Pass a list of [ChatMessage]s as `history` in [AiEngine.send] or
/// [AiEngine.stream] to give the model context about what was said before.
///
/// ## Example — continuing a conversation
///
/// ```dart
/// final history = <ChatMessage>[];
///
/// // First turn
/// final r1 = await gemini.send(userMessage: 'My name is Mohamed.');
/// history.add(ChatMessage.user('My name is Mohamed.'));
/// history.add(ChatMessage.model(r1.text));
///
/// // Second turn — model now knows the user's name
/// final r2 = await gemini.send(
///   userMessage: 'What is my name?',
///   history: history,
/// );
/// print(r2.text); // → "Your name is Mohamed."
/// ```
///
/// History is always optional — omit it for stateless single-turn requests.
class ChatMessage {
  /// Creates a message from the end user.
  const ChatMessage.user(this.text) : role = 'user';

  /// Creates a message from the AI model (a previous response).
  const ChatMessage.model(this.text) : role = 'model';

  /// Who sent this message — either `'user'` or `'model'`.
  final String role;

  /// The text content of this message.
  final String text;

  @override
  String toString() => 'ChatMessage($role: "$text")';
}
