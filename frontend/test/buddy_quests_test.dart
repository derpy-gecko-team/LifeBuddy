import 'package:flutter_test/flutter_test.dart';
import 'package:lifebuddy/buddy/data/mock_buddy_repository.dart';
import 'package:lifebuddy/buddy/state/buddy_controller.dart';
import 'package:lifebuddy/guildhall/data/mock_quest_repository.dart';
import 'package:lifebuddy/guildhall/data/models.dart';
import 'package:lifebuddy/guildhall/state/guild_hall_remote.dart';

/// The Buddy and the Guild Hall share one board: what is said to the one
/// shows on the other.
void main() {
  late MockQuestRepository board;
  late MockBuddyRepository buddy;

  setUp(() {
    board = MockQuestRepository();
    buddy = MockBuddyRepository(quests: board, latency: Duration.zero);
  });

  Future<Quest> onTheBoard(String id) async => (await board.fetchGuildHall()).allQuests.firstWhere((q) => q.id == id);

  test('a wish becomes an open quest on the Guild Hall board', () async {
    final before = await board.fetchGuildHall();
    final reply = await buddy.interact('I want to go for a run every morning, I keep skipping it.');

    final posted = reply.updatedQuests.single;
    expect(posted.title, 'Go for a run every morning');
    expect(posted.fulfilled, isFalse);
    expect(posted.linkLabel, 'On the board: Go for a run every morning');

    final quest = await onTheBoard(posted.id);
    expect(quest.status, QuestStatus.open);
    expect(quest.journeyId, 'iron-body');
    expect((await board.fetchGuildHall()).newToday, before.newToday + 1);
  });

  test('wishes are filed under the journey they belong to', () async {
    final study = await buddy.interact('I need to study for the algebra exam');
    final errand = await buddy.interact('remind me to call the plumber');

    expect((await onTheBoard(study.updatedQuests.single.id)).journeyId, 'scholar-tower');
    final call = await onTheBoard(errand.updatedQuests.single.id);
    expect(call.journeyId, 'clean-hearth');
    expect(call.title, 'Call the plumber');
  });

  test('the same wish twice is not posted twice', () async {
    final first = await buddy.interact('I want to learn the lute');
    final again = await buddy.interact('i want to learn the lute!');

    expect(again.updatedQuests.single.id, first.updatedQuests.single.id);
    expect((await board.fetchGuildHall()).allQuests.where((q) => q.title == 'Learn the lute'), hasLength(1));
  });

  test('a deed fulfils the quest it is about and pays its bounty', () async {
    final before = (await board.fetchGuildHall()).hero;
    final reply = await buddy.interact('I finished the laundry');

    final done = reply.updatedQuests.single;
    expect(done.id, 'laundry-caves');
    expect(done.fulfilled, isTrue);
    expect(done.linkLabel, 'Fulfilled: Brave the Laundry Caves');

    final quest = await onTheBoard('laundry-caves');
    expect(quest.status, QuestStatus.fulfilled);
    expect(quest.trialsDone, quest.trials.length);
    final after = (await board.fetchGuildHall()).hero;
    expect(after.xp + (after.level - before.level) * before.xpToNext, before.xp + quest.xp);
  });

  test('a quest the Buddy posted can be reported done in the hero’s own words', () async {
    final posted = await buddy.interact('I have to water the tomatoes');
    final reply = await buddy.interact('done, I watered the tomatoes');

    expect(reply.updatedQuests.single.id, posted.updatedQuests.single.id);
    expect((await onTheBoard(posted.updatedQuests.single.id)).status, QuestStatus.fulfilled);
  });

  test('a deed that matches nothing changes nothing, and a sealed quest stays sealed', () async {
    final vague = await buddy.interact('I finished a quest today');
    expect(vague.updatedQuests, isEmpty);

    // "Visit the Tooth Healer" is sealed behind another quest.
    final sealed = await buddy.interact('I went to the tooth healer');
    expect(sealed.updatedQuests, isEmpty);
    expect((await onTheBoard('tooth-healer')).status, QuestStatus.sealed);
  });

  test('the Guild Hall is told when a conversation changes the board', () async {
    var told = 0;
    final controller = BuddyController(buddy, onQuestsChanged: (changed) => told += changed.length);

    await controller.send('hello');
    expect(told, 0);
    await controller.send('I want to sweep the yard');
    expect(told, 1);
  });

  test('the remote hands over the quest to open once', () {
    final remote = GuildHallRemote();
    var woken = 0;
    remote.addListener(() => woken++);

    remote.refresh();
    expect(remote.takeQuestToOpen(), isNull);
    remote.openQuest('buddy-1');
    expect(woken, 2);
    expect(remote.takeQuestToOpen(), 'buddy-1');
    expect(remote.takeQuestToOpen(), isNull);
  });
}
