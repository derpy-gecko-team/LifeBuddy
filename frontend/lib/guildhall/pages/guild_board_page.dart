import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/guild_hall_controller.dart';
import '../theme/guild_theme.dart';
import '../widgets/board_header.dart';
import '../widgets/guild_feedback.dart';
import '../widgets/guild_scaffold.dart';
import '../widgets/notice_route.dart';
import '../widgets/ornaments.dart';
import '../widgets/quest_cards.dart';
import '../widgets/tag_rail.dart';

int compareForBoard(Quest a, Quest b) {
  int rank(QuestStatus s) => switch (s) {
        QuestStatus.sworn => 0,
        QuestStatus.open => 1,
        QuestStatus.sealed => 2,
        QuestStatus.fulfilled => 3,
      };
  final byStatus = rank(a.status).compareTo(rank(b.status));
  if (byStatus != 0) return byStatus;
  return compareByDeadline(a, b);
}

int compareForJourney(Quest a, Quest b) {
  int rank(QuestStatus s) => switch (s) {
        QuestStatus.open || QuestStatus.sworn => 0,
        QuestStatus.sealed => 1,
        QuestStatus.fulfilled => 2,
      };
  final byStatus = rank(a.status).compareTo(rank(b.status));
  return byStatus != 0 ? byStatus : compareByDeadline(a, b);
}

int compareByDeadline(Quest a, Quest b) {
  if (a.deadline == null && b.deadline == null) return 0;
  if (a.deadline == null) return 1;
  if (b.deadline == null) return -1;
  return a.deadline!.compareTo(b.deadline!);
}

class GuildBoardPage extends StatefulWidget {
  const GuildBoardPage({
    super.key,
    required this.controller,
    required this.onOpenJourney,
    required this.onOpenQuest,
    this.onOpenBuddy,
  });

  final GuildHallController controller;
  final OpenJourney onOpenJourney;
  final OpenQuest onOpenQuest;
  final VoidCallback? onOpenBuddy;

  @override
  State<GuildBoardPage> createState() => _GuildBoardPageState();
}

class _GuildBoardPageState extends State<GuildBoardPage> {
  final _scrollOffset = ValueNotifier<double>(0);

  final _topKey = GlobalKey();

  final _railPinned = ValueNotifier<bool>(false);

  bool _titleDrawn = false;

  static const _glowSize = 480.0;

  @override
  void dispose() {
    _railPinned.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      _scrollOffset.value = n.metrics.pixels;
      final topHeight = _topKey.currentContext?.size?.height ?? 200;
      _railPinned.value = n.metrics.pixels > topHeight - 2;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GuildScaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final data = controller.data;
          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: controller.error != null
                    ? GuildNote(
                        title: 'The quests did not arrive',
                        message: 'Your quests could not be loaded. Check your connection and try again.',
                        action: GuildButton(label: 'Try again', onPressed: controller.load),
                      )
                    : const GuildNote(title: 'Unrolling today’s quests', busy: true),
              ),
            );
          }

          final now = DateTime.now();
          final filter = controller.filter;
          final sections = [
            for (final line in data.journeys)
              (line: line, quests: line.quests.where(filter.matches).toList()..sort(compareForBoard)),
          ].where((s) => s.quests.isNotEmpty).toList();

          final dueToday = filter == QuestFilter.all
              ? (data.allQuests
                  .where((q) =>
                      (q.status == QuestStatus.sworn || q.status == QuestStatus.open) && q.isUrgent(now))
                  .toList()
                ..sort(compareByDeadline))
              : const <Quest>[];

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -_glowSize / 2 + 54,
                top: -_glowSize / 2 + 70,
                child: ValueListenableBuilder<double>(
                  valueListenable: _scrollOffset,
                  builder: (context, offset, child) => offset > _glowSize
                      ? const SizedBox.shrink()
                      : Transform.translate(offset: Offset(0, -offset), child: child),
                  child: const TorchGlow(size: _glowSize),
                ),
              ),
              NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: RefreshIndicator(
                  color: GuildColors.gold,
                  backgroundColor: GuildColors.indigoDeep,
                  onRefresh: controller.load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          key: _topKey,
                          padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.md, GuildSpace.gutter, GuildSpace.sm),
                          child: Column(
                            children: [
                              RepaintBoundary(
                                child: BoardHeader(
                                  newToday: data.newToday,
                                  drawTitle: !_titleDrawn,
                                  onTitleDrawn: () => _titleDrawn = true,
                                ),
                              ),
                              const SizedBox(height: GuildSpace.md),
                              RepaintBoundary(
                                child: RankSign(hero: data.hero, onOpenBuddy: widget.onOpenBuddy),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: PinnedTagRail(
                          tags: [
                            for (final f in QuestFilter.values)
                              TagRailItem(
                                label: f.label,
                                count: f == QuestFilter.all ? null : controller.countFor(f),
                                selected: controller.filter == f,
                                onTap: () => controller.setFilter(f),
                              ),
                          ],
                          extent: PinnedTagRail.extentFor(context),
                          pinned: _railPinned,
                        ),
                      ),
                      if (dueToday.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.md, GuildSpace.gutter, 0),
                          sliver: SliverToBoxAdapter(
                            child: RepaintBoundary(
                              child: DueTodayStrip(
                                quests: dueToday,
                                now: now,
                                onOpenQuest: (id, rowContext) =>
                                    widget.onOpenQuest(id, origin: globalRectOf(rowContext)),
                              ),
                            ),
                          ),
                        ),
                      if (sections.isEmpty)
                        SliverToBoxAdapter(child: _EmptyBoard(controller: controller, onOpenBuddy: widget.onOpenBuddy))
                      else
                        for (final s in sections)
                          SliverToBoxAdapter(
                            key: ValueKey(s.line.id),
                            child: _JourneySection(
                              journey: s.line,
                              quests: s.quests,
                              now: now,
                              onOpenJourney: (origin) => widget.onOpenJourney(s.line.id, origin: origin),
                              onOpenQuest: widget.onOpenQuest,
                            ),
                          ),
                      const SliverToBoxAdapter(child: SizedBox(height: GuildSpace.huge)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JourneySection extends StatelessWidget {
  const _JourneySection({
    required this.journey,
    required this.quests,
    required this.now,
    required this.onOpenJourney,
    required this.onOpenQuest,
  });

  final Journey journey;
  final List<Quest> quests;
  final DateTime now;
  final ValueChanged<Rect?> onOpenJourney;
  final OpenQuest onOpenQuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.xxl, GuildSpace.gutter, 0),
          child: RepaintBoundary(
            child: JourneyPlaque(journey: journey, onTap: onOpenJourney),
          ),
        ),
        SizedBox(
          height: QuestCard.heightFor(context) + GuildSpace.huge + GuildSpace.xl,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.huge, GuildSpace.gutter, GuildSpace.lg),
            itemCount: quests.length,
            findItemIndexCallback: (key) {
              final index = quests.indexWhere((q) => ValueKey(q.id) == key);
              return index < 0 ? null : index;
            },
            separatorBuilder: (_, _) => const SizedBox(width: GuildSpace.xl),
            itemBuilder: (context, i) => QuestCard(
              key: ValueKey(quests[i].id),
              quest: quests[i],
              now: now,
              tilt: i.isEven ? -0.035 : 0.03,
              onOpen: onOpenQuest,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.controller, this.onOpenBuddy});

  final GuildHallController controller;
  final VoidCallback? onOpenBuddy;

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    final (title, message) = switch (filter) {
      QuestFilter.sworn => ('No sworn quests', 'Open a quest and swear its oath to start working on it.'),
      QuestFilter.sealed => ('Nothing is sealed', 'Every quest on the board is open to you.'),
      QuestFilter.fulfilled => ('No quests fulfilled yet', 'Finish a quest’s trials and claim its bounty to see it here.'),
      QuestFilter.all => ('The board is empty', 'Tell your Buddy what you want to do and it will post quests here.'),
    };
    final Widget? action = filter == QuestFilter.all
        ? (onOpenBuddy == null ? null : GuildButton(label: 'Talk to your Buddy', onPressed: onOpenBuddy))
        : GuildButton(
            label: 'Show all quests',
            kind: GuildButtonKind.quiet,
            onPressed: () => controller.setFilter(QuestFilter.all),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.huge, GuildSpace.gutter, 0),
      child: Center(child: GuildNote(title: title, message: message, action: action)),
    );
  }
}
