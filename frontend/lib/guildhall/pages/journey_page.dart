import 'package:material_ui/material_ui.dart';

import '../state/guild_hall_controller.dart';
import '../theme/guild_theme.dart';
import '../widgets/guild_scaffold.dart';
import '../widgets/notice_route.dart';
import '../widgets/ornaments.dart';
import '../widgets/quest_cards.dart';
import '../widgets/journey_banner.dart';
import '../widgets/sketch.dart';
import '../widgets/painted_wall.dart';
import 'guild_board_page.dart';

class JourneyPage extends StatefulWidget {
  const JourneyPage({
    super.key,
    required this.controller,
    required this.journeyId,
    required this.onOpenQuest,
  });

  final GuildHallController controller;
  final String journeyId;
  final OpenQuest onOpenQuest;

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  final _collapsed = ValueNotifier<bool>(false);
  final _bannerKey = GlobalKey();

  @override
  void dispose() {
    _collapsed.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final bannerHeight = _bannerKey.currentContext?.size?.height ?? 320;
    _collapsed.value = n.metrics.pixels > bannerHeight - 40;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GuildScaffold(
      wall: WallVariant.journey,
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final line = widget.controller.journeyById(widget.journeyId);
          if (line == null) return const SizedBox.shrink();
          final now = DateTime.now();
          final quests = [...line.quests]..sort(compareForJourney);

          return Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _collapsed,
                builder: (context, collapsed, _) => AnimatedContainer(
                  duration: GuildMotion.quick,
                  curve: Curves.easeOut,
                  margin: EdgeInsets.fromLTRB(collapsed ? GuildSpace.md : 0, GuildSpace.hair, collapsed ? GuildSpace.md : 0, 0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: collapsed ? 1 : 0,
                          duration: GuildMotion.quick,
                          child: SketchBox(
                            color: GuildColors.brickDeep,
                            borderColor: GuildColors.brickShade,
                            seed: stableSeed(line.id),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(GuildSpace.xs, GuildSpace.hair, GuildSpace.lg, GuildSpace.hair),
                        child: Row(
                          children: [
                            GuildBackLink(
                              label: 'Guildhall',
                              showLabel: !collapsed,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            if (collapsed) ...[
                              Expanded(
                                child: Text(
                                  line.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GuildText.title(GuildTitle.lg, color: GuildColors.cream),
                                ),
                              ),
                              const SizedBox(width: GuildSpace.sm),
                              SealProgress(total: line.quests.length, done: line.fulfilledCount, size: 16),
                            ] else
                              const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        sliver: SliverToBoxAdapter(
                          child: RepaintBoundary(
                            key: _bannerKey,
                            child: JourneyBanner(journey: line),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.xxl, GuildSpace.gutter, 0),
                        sliver: SliverToBoxAdapter(
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 12,
                            children: [
                              Semantics(
                                header: true,
                                child: Text('Quests', style: GuildText.title(GuildTitle.lg, color: GuildColors.cream)),
                              ),
                              Text('Open quests first, soonest deadline on top', style: GuildText.aside(GuildType.sm)),
                            ],
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: quests.length,
                        findChildIndexCallback: (key) {
                          final index = quests.indexWhere((q) => ValueKey(q.id) == key);
                          return index < 0 ? null : index;
                        },
                        itemBuilder: (context, i) => Padding(
                          key: ValueKey(quests[i].id),
                          padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.xxl, GuildSpace.gutter, 0),
                          child: QuestRow(quest: quests[i], now: now, onOpen: widget.onOpenQuest),
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
