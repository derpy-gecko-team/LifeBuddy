enum QuestStatus {
  open,

  sworn,

  sealed,

  fulfilled,
}

enum Peril {
  minor(1, 'Minor'),
  dire(2, 'Dire'),
  legendary(3, 'Legendary');

  const Peril(this.skulls, this.label);
  final int skulls;
  final String label;
}

enum PaperTone { parchment, sage, vellum }

class Trial {
  const Trial({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  Trial copyWith({bool? done}) =>
      Trial(id: id, title: title, done: done ?? this.done);
}

class Quest {
  const Quest({
    required this.id,
    required this.journeyId,
    required this.title,
    required this.flavor,
    required this.description,
    required this.iconAsset,
    required this.xp,
    required this.peril,
    required this.status,
    required this.trials,
    this.deadline,
    this.isBoss = false,
    this.titleReward,
    this.sealedReason,
    this.prerequisiteId,
    this.paper = PaperTone.parchment,
  });

  final String id;
  final String journeyId;
  final String title;

  final String flavor;

  final String description;
  final String iconAsset;
  final int xp;
  final Peril peril;
  final QuestStatus status;
  final List<Trial> trials;
  final DateTime? deadline;

  final bool isBoss;

  final String? titleReward;
  final String? sealedReason;

  final String? prerequisiteId;
  final PaperTone paper;

  int get trialsDone => trials.where((t) => t.done).length;

  bool isUrgent(DateTime now) =>
      deadline != null &&
      status != QuestStatus.fulfilled &&
      deadline!.difference(now).inHours < 24;

  Quest copyWith({
    QuestStatus? status,
    List<Trial>? trials,
    String? sealedReason,
    bool clearSealedReason = false,
  }) =>
      Quest(
        id: id,
        journeyId: journeyId,
        title: title,
        flavor: flavor,
        description: description,
        iconAsset: iconAsset,
        xp: xp,
        peril: peril,
        status: status ?? this.status,
        trials: trials ?? this.trials,
        deadline: deadline,
        isBoss: isBoss,
        titleReward: titleReward,
        sealedReason:
            clearSealedReason ? null : (sealedReason ?? this.sealedReason),
        prerequisiteId: prerequisiteId,
        paper: paper,
      );
}

class Journey {
  const Journey({
    required this.id,
    required this.name,
    required this.emblemAsset,
    required this.quote,
    required this.bountyXp,
    required this.quests,
    this.bountyTitle,
  });

  final String id;

  final String name;
  final String emblemAsset;
  final String quote;
  final int bountyXp;
  final String? bountyTitle;
  final List<Quest> quests;

  int get fulfilledCount =>
      quests.where((q) => q.status == QuestStatus.fulfilled).length;

  double get progress => quests.isEmpty ? 0 : fulfilledCount / quests.length;

  bool get isComplete => quests.isNotEmpty && fulfilledCount == quests.length;

  Journey copyWith({List<Quest>? quests}) => Journey(
        id: id,
        name: name,
        emblemAsset: emblemAsset,
        quote: quote,
        bountyXp: bountyXp,
        bountyTitle: bountyTitle,
        quests: quests ?? this.quests,
      );
}

class HeroProgress {
  const HeroProgress({
    required this.rankTitle,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.coins,
  });

  final String rankTitle;
  final int level;
  final int xp;
  final int xpToNext;
  final int coins;

  double get progress => xpToNext == 0 ? 0 : (xp / xpToNext).clamp(0, 1);

  HeroProgress copyWith({int? level, int? xp, int? coins}) => HeroProgress(
        rankTitle: rankTitle,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        xpToNext: xpToNext,
        coins: coins ?? this.coins,
      );
}

class GuildHallData {
  const GuildHallData({
    required this.hero,
    required this.journeys,
    required this.newToday,
  });

  final HeroProgress hero;
  final List<Journey> journeys;

  final int newToday;

  Iterable<Quest> get allQuests => journeys.expand((l) => l.quests);
}
