import 'package:flutter/foundation.dart';

import '../data/buddy_repository.dart';
import '../data/models.dart';

/// Holds the conversation with the Buddy. The backend keeps no chat history
/// yet, so the conversation lives here for as long as the app is open.
class BuddyController extends ChangeNotifier {
  BuddyController(this._repository, {this.onQuestsChanged});

  final BuddyRepository _repository;

  /// Called when an answer says quests were posted or fulfilled, so whoever
  /// shows quests (the Guild Hall) can fetch them again.
  final void Function(List<QuestUpdate> changed)? onQuestsChanged;

  final _messages = <ChatMessage>[];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _replying = false;

  /// True while the Buddy is writing its answer. One letter at a time.
  bool get replying => _replying;

  /// What the Buddy said last, if it has said anything yet.
  ChatMessage? get latestFromBuddy {
    for (final message in _messages.reversed) {
      if (message.fromBuddy) return message;
    }
    return null;
  }

  /// The hero's last message, if it did not get through.
  ChatMessage? get undelivered =>
      _messages.isNotEmpty && _messages.last.status == DeliveryStatus.failed ? _messages.last : null;

  int _nextId = 0;
  bool _disposed = false;

  bool canSend(String text) => !_replying && text.trim().isNotEmpty;

  /// Sends [text] and waits for the answer. A message that does not get
  /// through stays in the conversation as [DeliveryStatus.failed]; see [retry].
  Future<void> send(String text) async {
    if (!canSend(text)) return;
    final message = ChatMessage(
      id: 'm${_nextId++}',
      author: ChatAuthor.hero,
      text: text.trim(),
      sentAt: DateTime.now(),
      status: DeliveryStatus.sending,
    );
    _messages.add(message);
    await _deliver(message);
  }

  Future<void> retry(String messageId) async {
    if (_replying) return;
    final index = _messages.indexWhere((m) => m.id == messageId && m.status == DeliveryStatus.failed);
    if (index < 0) return;
    // Back to the end of the conversation, so the answer lands right under it.
    final message = _messages.removeAt(index).copyWith(status: DeliveryStatus.sending);
    _messages.add(message);
    await _deliver(message);
  }

  Future<void> _deliver(ChatMessage message) async {
    _replying = true;
    notifyListeners();
    try {
      final reply = await _repository.interact(message.text);
      _mark(message.id, DeliveryStatus.sent);
      _messages.add(
        ChatMessage(
          id: 'm${_nextId++}',
          author: ChatAuthor.buddy,
          text: reply.message,
          sentAt: DateTime.now(),
          updatedQuests: reply.updatedQuests,
          newMapTile: reply.newMapTile,
        ),
      );
      if (reply.updatedQuests.isNotEmpty) onQuestsChanged?.call(reply.updatedQuests);
    } catch (_) {
      _mark(message.id, DeliveryStatus.failed);
    } finally {
      _replying = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _mark(String id, DeliveryStatus status) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index >= 0) _messages[index] = _messages[index].copyWith(status: status);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
