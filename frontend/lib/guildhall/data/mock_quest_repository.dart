import '../theme/guild_assets.dart';
import 'models.dart';
import 'quest_repository.dart';

class MockQuestRepository implements QuestRepository {
  MockQuestRepository({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _data = _seed(_clock());
  }

  static const abandonCost = 10;
  static const _latency = Duration(milliseconds: 250);

  final DateTime Function() _clock;
  late GuildHallData _data;

  @override
  Future<GuildHallData> fetchGuildHall() async {
    await Future<void>.delayed(_latency);
    return _data;
  }

  @override
  Future<Journey> fetchJourney(String journeyId) async {
    await Future<void>.delayed(_latency);
    return _data.journeys.firstWhere(
      (j) => j.id == journeyId,
      orElse: () => throw QuestActionException('Unknown journey $journeyId'),
    );
  }

  @override
  Future<GuildHallData> swearOath(String questId) async {
    final quest = _quest(questId);
    if (quest.status != QuestStatus.open) {
      throw QuestActionException('Only open quests can be sworn.');
    }
    _replace(quest.copyWith(status: QuestStatus.sworn));
    return _data;
  }

  @override
  Future<GuildHallData> abandonOath(String questId) async {
    final quest = _quest(questId);
    if (quest.status != QuestStatus.sworn) {
      throw QuestActionException('Only sworn quests can be abandoned.');
    }
    _replace(quest.copyWith(status: QuestStatus.open));
    final hero = _data.hero;
    _setHero(hero.copyWith(xp: (hero.xp - abandonCost).clamp(0, hero.xp)));
    return _data;
  }

  @override
  Future<GuildHallData> setTrialDone(
    String questId,
    String trialId, {
    required bool done,
  }) async {
    final quest = _quest(questId);
    switch (quest.status) {
      case QuestStatus.sworn:
        break;
      case QuestStatus.fulfilled:
        throw QuestActionException('This quest is already fulfilled.');
      case QuestStatus.sealed:
        throw QuestActionException('This quest is sealed.');
      case QuestStatus.open:
        throw QuestActionException('Swear the oath before attempting its trials.');
    }
    _replace(quest.copyWith(trials: [
      for (final t in quest.trials) t.id == trialId ? t.copyWith(done: done) : t,
    ]));
    return _data;
  }

  @override
  Future<GuildHallData> claimBounty(String questId) async {
    final quest = _quest(questId);
    if (quest.status != QuestStatus.sworn) {
      throw QuestActionException('Only sworn quests can be claimed.');
    }
    if (quest.trialsDone < quest.trials.length) {
      throw QuestActionException('Finish every trial before claiming the bounty.');
    }
    _replace(quest.copyWith(status: QuestStatus.fulfilled));
    _awardXp(quest.xp);
    _unsealDependentsOf(quest.id);
    final line = _data.journeys.firstWhere((l) => l.id == quest.journeyId);
    if (line.isComplete) _awardXp(line.bountyXp);
    return _data;
  }

  Quest _quest(String id) => _data.allQuests.firstWhere(
        (q) => q.id == id,
        orElse: () => throw QuestActionException('Unknown quest $id'),
      );

  void _replace(Quest updated) {
    _data = GuildHallData(
      hero: _data.hero,
      newToday: _data.newToday,
      journeys: [
        for (final line in _data.journeys)
          line.id == updated.journeyId
              ? line.copyWith(quests: [
                  for (final q in line.quests) q.id == updated.id ? updated : q,
                ])
              : line,
      ],
    );
  }

  void _setHero(HeroProgress hero) {
    _data = GuildHallData(
      hero: hero,
      journeys: _data.journeys,
      newToday: _data.newToday,
    );
  }

  void _awardXp(int amount) {
    var hero = _data.hero;
    var xp = hero.xp + amount;
    var level = hero.level;
    while (xp >= hero.xpToNext) {
      xp -= hero.xpToNext;
      level++;
    }
    hero = hero.copyWith(xp: xp, level: level);
    _setHero(hero);
  }

  void _unsealDependentsOf(String questId) {
    for (final q in _data.allQuests.toList()) {
      if (q.status == QuestStatus.sealed && q.prerequisiteId == questId) {
        _replace(q.copyWith(status: QuestStatus.open, clearSealedReason: true));
      }
    }
  }

  static GuildHallData _seed(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int days, int hour, [int minute = 0]) =>
        today.add(Duration(days: days, hours: hour, minutes: minute));

    return GuildHallData(
      newToday: 3,
      hero: const HeroProgress(
        rankTitle: 'Journeyman',
        level: 7,
        xp: 340,
        xpToNext: 500,
        coins: 1240,
      ),
      journeys: [
        Journey(
          id: 'iron-body',
          name: 'The Iron Body',
          emblemAsset: GuildAssets.emblemIronBody,
          quote: '“Steel is forged one blow at a time. So is the body that '
              'carries it.” — the Guildmaster',
          bountyXp: 250,
          bountyTitle: 'Ironclad',
          quests: [
            Quest(
              id: 'ten-thousand-steps',
              journeyId: 'iron-body',
              title: 'Walk the Ten Thousand Steps',
              flavor: 'March the city walls until your boots ache.',
              description: 'The city walls are long and your legs are '
                  'restless. Walk until the step counter reads ten '
                  'thousand, then rest by the fire.',
              iconAsset: GuildAssets.questBoot,
              xp: 60,
              peril: Peril.minor,
              status: QuestStatus.sworn,
              deadline: at(0, 19),
              trials: const [
                Trial(id: 't1', title: 'Morning march — 4,000 steps', done: true),
                Trial(id: 't2', title: 'Evening march — 6,000 steps'),
              ],
            ),
            Quest(
              id: 'drink-spring',
              journeyId: 'iron-body',
              title: 'Drink from the Spring',
              flavor: 'Eight cups of water before the moon rises.',
              description: 'A hero who forgets to drink falls before any '
                  'blade reaches them. Visit the spring through the day.',
              iconAsset: GuildAssets.questPotion,
              xp: 25,
              peril: Peril.minor,
              status: QuestStatus.open,
              paper: PaperTone.sage,
              trials: const [
                Trial(id: 't1', title: 'Four cups before noon'),
                Trial(id: 't2', title: 'Four cups before moonrise'),
              ],
            ),
            Quest(
              id: 'barracks',
              journeyId: 'iron-body',
              title: 'Train at the Barracks',
              flavor: 'Three sessions with the drill sergeant this week.',
              description: 'The sergeant does not care for excuses. Show up '
                  'three times this week and lift what you are told.',
              iconAsset: GuildAssets.questSword,
              xp: 90,
              peril: Peril.dire,
              status: QuestStatus.open,
              deadline: at(5, 20),
              paper: PaperTone.vellum,
              trials: const [
                Trial(id: 't1', title: 'First drill'),
                Trial(id: 't2', title: 'Second drill'),
                Trial(id: 't3', title: 'Third drill'),
              ],
            ),
            Quest(
              id: 'dawn-stretch',
              journeyId: 'iron-body',
              title: 'Greet the Dawn',
              flavor: 'Ten minutes of stretching at first light.',
              description: 'Loosen the joints before the day tightens them.',
              iconAsset: GuildAssets.questScroll,
              xp: 20,
              peril: Peril.minor,
              status: QuestStatus.fulfilled,
              paper: PaperTone.sage,
              trials: const [
                Trial(id: 't1', title: 'Stretch for ten minutes', done: true),
              ],
            ),
          ],
        ),
        Journey(
          id: 'scholar-tower',
          name: 'The Scholar’s Tower',
          emblemAsset: GuildAssets.emblemScholarTower,
          quote: '“Knowledge is a dungeon with no final floor. Clear these '
              'chambers and the Tower shall know your name.” — the Guildmaster',
          bountyXp: 300,
          bountyTitle: 'Keeper of Tomes',
          quests: [
            Quest(
              id: 'lab-report',
              journeyId: 'scholar-tower',
              title: 'Forge the Lab Report',
              flavor: 'The professor’s raven awaits it.',
              description: 'Measurements gathered, conclusions pending. '
                  'Hammer the findings into a report fit for the professor.',
              iconAsset: GuildAssets.questScroll,
              xp: 80,
              peril: Peril.dire,
              status: QuestStatus.sworn,
              deadline: at(0, 23, 59),
              trials: const [
                Trial(id: 't1', title: 'Write the method section', done: true),
                Trial(id: 't2', title: 'Plot the results'),
                Trial(id: 't3', title: 'Send it by raven'),
              ],
            ),
            Quest(
              id: 'algorithm-duel',
              journeyId: 'scholar-tower',
              title: 'Duel the Algorithm',
              flavor: 'Defeat three dynamic-programming beasts.',
              description: 'They hide in overlapping subproblems. Memoise '
                  'their weaknesses and strike three of them down.',
              iconAsset: GuildAssets.questSword,
              xp: 120,
              peril: Peril.legendary,
              status: QuestStatus.open,
              paper: PaperTone.sage,
              deadline: at(3, 18),
              trials: const [
                Trial(id: 't1', title: 'Slay the knapsack'),
                Trial(id: 't2', title: 'Slay the longest subsequence'),
                Trial(id: 't3', title: 'Slay the edit distance'),
              ],
            ),
            Quest(
              id: 'lecture-scrolls',
              journeyId: 'scholar-tower',
              title: 'Copy the Lecture Scrolls',
              flavor: 'Transcribe last week’s lessons.',
              description: 'The scribes will not do it for you.',
              iconAsset: GuildAssets.questScroll,
              xp: 40,
              peril: Peril.minor,
              status: QuestStatus.fulfilled,
              paper: PaperTone.vellum,
              trials: const [
                Trial(id: 't1', title: 'Copy lectures I – III', done: true),
              ],
            ),
            Quest(
              id: 'morning-lecture',
              journeyId: 'scholar-tower',
              title: 'Attend the Morning Lecture',
              flavor: 'Arrive before the bell tolls eight.',
              description: 'Sit near the front. Stay awake.',
              iconAsset: GuildAssets.questBoot,
              xp: 30,
              peril: Peril.minor,
              status: QuestStatus.fulfilled,
              paper: PaperTone.sage,
              trials: const [
                Trial(id: 't1', title: 'Be seated by eight', done: true),
              ],
            ),
            Quest(
              id: 'exam-wyrm',
              journeyId: 'scholar-tower',
              title: 'The Exam Wyrm',
              flavor: 'It breathes deadlines.',
              description: 'The final exam of the semester has woken. It '
                  'breathes deadlines and feeds on unread notes. Weaken it '
                  'with the trials below before you face it.',
              iconAsset: GuildAssets.bossDragon,
              xp: 500,
              peril: Peril.legendary,
              status: QuestStatus.open,
              isBoss: true,
              titleReward: 'Wyrmslayer',
              deadline: at(68, 9),
              trials: const [
                Trial(id: 't1', title: 'Solve three past exams'),
                Trial(id: 't2', title: 'Review lecture notes I – VI'),
                Trial(id: 't3', title: 'Sleep eight hours before the duel'),
              ],
            ),
          ],
        ),
        Journey(
          id: 'clean-hearth',
          name: 'The Clean Hearth',
          emblemAsset: GuildAssets.rankShield,
          quote: '“A hero’s home is their first keep. Let no dust beast '
              'claim it.” — the Guildmaster',
          bountyXp: 150,
          bountyTitle: 'Warden of the Hearth',
          quests: [
            Quest(
              id: 'laundry-caves',
              journeyId: 'clean-hearth',
              title: 'Brave the Laundry Caves',
              flavor: 'The pile grows hungrier by the day.',
              description: 'Descend into the basement, feed the machines '
                  'their coin and return with clean garments.',
              iconAsset: GuildAssets.questPotion,
              xp: 30,
              peril: Peril.minor,
              status: QuestStatus.open,
              deadline: at(1, 20),
              trials: const [
                Trial(id: 't1', title: 'Wash'),
                Trial(id: 't2', title: 'Dry'),
                Trial(id: 't3', title: 'Fold and stow'),
              ],
            ),
            Quest(
              id: 'dust-beasts',
              journeyId: 'clean-hearth',
              title: 'Tame the Dust Beasts',
              flavor: 'They lurk beneath the bed.',
              description: 'Sweep every chamber of the keep.',
              iconAsset: GuildAssets.questSword,
              xp: 45,
              peril: Peril.dire,
              status: QuestStatus.sealed,
              paper: PaperTone.sage,
              prerequisiteId: 'laundry-caves',
              sealedReason: 'Brave the Laundry Caves first.',
              trials: const [
                Trial(id: 't1', title: 'Sweep the floors'),
                Trial(id: 't2', title: 'Dust the shelves'),
              ],
            ),
            Quest(
              id: 'tooth-healer',
              journeyId: 'clean-hearth',
              title: 'Visit the Tooth Healer',
              flavor: 'Book the dentist before the ache returns.',
              description: 'Send word to the healer and keep the appointment.',
              iconAsset: GuildAssets.questScroll,
              xp: 70,
              peril: Peril.dire,
              status: QuestStatus.sealed,
              sealedReason: 'Your free quests for this week are used up. '
                  'The seal breaks on Monday.',
              paper: PaperTone.vellum,
              trials: const [
                Trial(id: 't1', title: 'Book an appointment'),
                Trial(id: 't2', title: 'Attend it'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
