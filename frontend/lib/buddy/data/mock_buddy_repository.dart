import 'buddy_repository.dart';
import 'models.dart';

/// Stands in for the backend until the app talks to `/api/guide/interact`.
class MockBuddyRepository implements BuddyRepository {
  MockBuddyRepository({this.latency = const Duration(milliseconds: 1100)});

  final Duration latency;

  int _turn = 0;
  int _nextQuestId = 100;

  static const _smallTalk = [
    'Noted in my ledger. What would you like to take on next?',
    'A fine thing to tell me. Shall I turn it into a quest for the board?',
    'I hear you. Tell me a little more and I will see what the guild can do.',
  ];

  @override
  Future<BuddyReply> interact(String userText) {
    final text = userText.trim();
    if (text.isEmpty) throw BuddyException('Say something to your Buddy first.');
    if (text.length > BuddyRepository.maxMessageLength) {
      throw BuddyException('That is too long for one letter. Split it in two.');
    }
    return Future<BuddyReply>.delayed(latency, () => _answer(text.toLowerCase()));
  }

  BuddyReply _answer(String text) {
    bool mentions(List<String> words) => words.any(text.contains);

    if (mentions(['finished', 'done', 'completed', 'did my', 'i did'])) {
      return BuddyReply(
        message: 'Well fought! I have marked it in the ledger. Claim your bounty at the Guild Hall.',
        updatedQuests: [QuestUpdate(id: '${_nextQuestId++}', title: 'Today’s deed', status: 'COMPLETED')],
        newMapTile: const MapTileUpdate(tileId: '1', tileType: 'FOREST', q: 1, r: 0),
      );
    }
    if (mentions(['fit', 'gym', 'run', 'workout', 'exercise', 'train'])) {
      return _post(
        'A strong body serves every quest. I have pinned a first step to the board. Start small, hero.',
        'Morning run: three laps of the yard',
      );
    }
    if (mentions(['read', 'study', 'learn', 'exam', 'book'])) {
      return _post(
        'The scholar’s road it is. One page at a time. Look for the new notice on the board.',
        'Read one chapter before nightfall',
      );
    }
    if (mentions(['plan', 'week', 'organi', 'tidy', 'clean'])) {
      return _post(
        'Order first, glory after. I have written the first task down for you.',
        'Lay out the week on one page',
      );
    }
    if (mentions(['hello', 'hi ', 'hey', 'good morning', 'well met']) || text == 'hi') {
      return const BuddyReply(message: 'Well met! What shall we set out to do today?');
    }
    return BuddyReply(message: _smallTalk[_turn++ % _smallTalk.length]);
  }

  BuddyReply _post(String message, String questTitle) => BuddyReply(
    message: message,
    updatedQuests: [QuestUpdate(id: '${_nextQuestId++}', title: questTitle, status: 'ACTIVE')],
  );
}
