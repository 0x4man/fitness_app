enum MessageRole { user, assistant }

/// A single message in the AI Coach chat conversation. Kept in memory
/// only (not persisted to Firestore) — the conversation resets each
/// time the chat screen is reopened.
class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
