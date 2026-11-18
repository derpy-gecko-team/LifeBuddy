import '../../guildhall/data/mock_quest_repository.dart';
import '../../guildhall/data/models.dart';
import 'buddy_repository.dart';
import 'models.dart';

/// Stands in for the server's guide (`POST /api/guide/interact`) until the
/// app talks to it.
///
/// It does what the real one is meant to: turn what the hero wants into
/// quests, and what the hero has done into fulfilled ones, on the same board
/// the Guild Hall shows. What it lacks is the understanding. Where the
/// server asks a language model, this looks for a few turns of phrase
/// ("I want to…", "I finished…"), which is enough to try the whole loop.
class MockBuddyRepository implements BuddyRepository {
  MockBuddyRepository({MockQuestRepository? quests, this.latency = const Duration(milliseconds: 1100)})
    : _quests = quests ?? MockQuestRepository();

  final MockQuestRepository _quests;
  final Duration latency;

  int _turn = 0;

  @override
  Future<BuddyReply> interact(String userText) {
    final text = userText.trim();
    if (text.isEmpty) throw BuddyException('Say something to your Buddy first.');
    if (text.length > BuddyRepository.maxMessageLength) {
      throw BuddyException('That is too long for one letter. Split it in two.');
    }
    return Future<BuddyReply>.delayed(latency, () => _answer(text));
  }

  static final _deed = RegExp(
    r"(\b(finished|completed|i did|i'?ve done|i have done|done with|i'?m done|i am done|i went|i'?ve been|i have been|"
    r"i made it|ticked off|i ran|i read|i cleaned|i watered)\b|^done\b)",
    caseSensitive: false,
  );

  static final _wish = RegExp(
    r"\b(?:i (?:really )?(?:want|need|have|ought|wish|plan|would like|would love)(?: to)?|i'?d (?:like|love) to|"
    r"i (?:should|must|wanna|gotta|will)|i'?ll|i'?m going to|i am going to|i'?m gonna|"
    r"remind me to|help me(?: to)?|let'?s|make me)\s+(.+)",
    caseSensitive: false,
  );

  static final _hello = RegExp(r'^(hi|hello|hey|yo|good (morning|evening|day)|well met)\b', caseSensitive: false);

  BuddyReply _answer(String text) {
    _turn++;
    if (_deed.hasMatch(text)) return _fulfil(text);
    final wish = _wish.firstMatch(text);
    if (wish != null) return _post(_titleFrom(wish.group(1)!), text);
    if (_hello.hasMatch(text)) {
      return const BuddyReply(message: 'Yes, yes, hello. Now: something you want to do, or something you have done?');
    }
    return BuddyReply(
      message: const [
        'Mm. Is that a wish, a deed, or just noise? Start with “I want to…” and I will make a quest of it.',
        'Charming. Tell me what you want to do, or what you have finished, and I will see to the board.',
        'I am a cat, not a diary. “I need to…” gets you a quest. “I finished…” gets you a bounty.',
      ][_turn % 3],
    );
  }

  // --- "I want to …": a new quest on the board ------------------------------

  BuddyReply _post(String title, String askedAs) {
    for (final quest in _quests.quests) {
      if (quest.status != QuestStatus.fulfilled && quest.title.toLowerCase() == title.toLowerCase()) {
        return BuddyReply(
          message: 'That is already on the board. Staring at it will not finish it.',
          updatedQuests: [_report(quest)],
        );
      }
    }
    final quest = _quests.postFromBuddy(title: title, journeyId: _journeyFor(askedAs), askedAs: askedAs);
    return BuddyReply(
      message: [
        '“$title.” Bold. It is on the board; go and swear to it before you change your mind.',
        'Done. “$title” is pinned up at the Guild Hall. I expect to hear how it went.',
        'A quest, then: “$title.” Posted. Try not to make me regret the ink.',
      ][_turn % 3],
      updatedQuests: [_report(quest)],
    );
  }

  /// "go to the dentist tomorrow, I keep putting it off." -> "Go to the dentist tomorrow"
  static String _titleFrom(String wish) {
    var title = wish.split(RegExp(r'[.!?;\n]|, | because | but | so that ')).first.trim();
    title = title.replaceFirst(RegExp(r'^(to|and)\s+', caseSensitive: false), '');
    if (title.length > 46) {
      title = title.substring(0, 46);
      final space = title.lastIndexOf(' ');
      if (space > 20) title = title.substring(0, space);
    }
    if (title.isEmpty) return 'Do the thing';
    return title[0].toUpperCase() + title.substring(1);
  }

  static String _journeyFor(String text) {
    bool about(String words) => RegExp('\\b($words)', caseSensitive: false).hasMatch(text);
    if (about('fit|gym|run|jog|walk|work ?out|exercis|train|stretch|swim|lift|sleep|water|eat|diet')) {
      return 'iron-body';
    }
    if (about('read|stud|learn|exam|book|lectur|homework|course|essay|thesis|project|code|practi[cs]e')) {
      return 'scholar-tower';
    }
    return 'clean-hearth'; // errands and everything else
  }

  // --- "I finished …": a quest fulfilled ------------------------------------

  static const _small = {
    'the',
    'and',
    'for',
    'with',
    'from',
    'that',
    'this',
    'have',
    'has',
    'had',
    'did',
    'done',
    'went',
    'been',
    'just',
    'today',
    'finally',
    'finished',
    'completed',
    'quest',
    'quests',
    'made',
    'ticked',
    'off',
    'all',
    'some',
    'your',
    'you',
  };

  static Set<String> _stems(String text) => {
    for (final word in text.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
      if (word.length >= 3 && !_small.contains(word)) word.length > 5 ? word.substring(0, 5) : word,
  };

  BuddyReply _fulfil(String text) {
    final said = _stems(text);
    Quest? best;
    var bestScore = 0;
    for (final quest in _quests.quests) {
      if (quest.status != QuestStatus.open && quest.status != QuestStatus.sworn) continue;
      final about = _stems('${quest.title} ${quest.flavor} ${quest.trials.map((t) => t.title).join(' ')}');
      // A word in the title counts double: "the laundry" should find the
      // laundry quest before one that merely mentions washing.
      final inTitle = _stems(quest.title);
      final score = said.intersection(about).length + said.intersection(inTitle).length;
      // Sworn quests win ties: those are the ones the hero is working on.
      if (score > bestScore || (score == bestScore && score > 0 && quest.status == QuestStatus.sworn)) {
        best = quest;
        bestScore = score;
      }
    }
    if (best == null) {
      return const BuddyReply(message: 'Finished what, exactly? I keep a ledger, not a crystal ball. Name the quest.');
    }
    final done = _quests.fulfilFromBuddy(best.id);
    if (done == null) {
      return const BuddyReply(message: 'That one is not yours to finish yet.');
    }
    return BuddyReply(
      message: [
        '“${done.title}”, fulfilled. ${done.xp} XP to your name. Do not let it go to your head.',
        'Well, well. “${done.title}” is struck off the board. ${done.xp} XP, as promised.',
        'I have marked “${done.title}” as done. ${done.xp} XP. I may even be impressed.',
      ][_turn % 3],
      updatedQuests: [_report(done)],
    );
  }

  static QuestUpdate _report(Quest quest) => QuestUpdate(
    id: quest.id,
    title: quest.title,
    xp: quest.xp,
    status: switch (quest.status) {
      QuestStatus.fulfilled => 'COMPLETED',
      QuestStatus.sworn => 'IN_PROGRESS',
      QuestStatus.open => 'OPEN',
      QuestStatus.sealed => 'SEALED',
    },
  );
}
