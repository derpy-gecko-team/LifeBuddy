import 'package:flutter/material.dart';

import '../guildhall/data/mock_quest_repository.dart';
import '../guildhall/data/quest_repository.dart';
import '../guildhall/pages/guild_board_page.dart';
import '../guildhall/pages/quest_detail_page.dart';
import '../guildhall/pages/journey_page.dart';
import '../guildhall/state/guild_hall_controller.dart';
import '../guildhall/state/guild_hall_remote.dart';
import '../guildhall/theme/guild_theme.dart';
import '../guildhall/widgets/notice_route.dart';

class GuildHallPage extends StatefulWidget {
  const GuildHallPage({super.key, this.onOpenBuddy, this.repository, this.remote});

  final VoidCallback? onOpenBuddy;

  final QuestRepository? repository;

  /// Lets the rest of the app tell the hall its quests changed, or ask it
  /// to open one (the Buddy does both).
  final GuildHallRemote? remote;

  @override
  State<GuildHallPage> createState() => _GuildHallPageState();
}

class _GuildHallPageState extends State<GuildHallPage> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _heroController = HeroController(
    createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
  );
  late final GuildHallController _controller =
      GuildHallController(widget.repository ?? MockQuestRepository(), beforeFirstLoad: GuildText.preload)
        ..load();

  @override
  void initState() {
    super.initState();
    widget.remote?.addListener(_onRemote);
  }

  @override
  void dispose() {
    widget.remote?.removeListener(_onRemote);
    _heroController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRemote() async {
    final questId = widget.remote!.takeQuestToOpen();
    await _controller.load();
    if (!mounted || questId == null || _controller.questById(questId) == null) return;
    await _openQuest(questId);
  }

  void _openJourney(String journeyId, {Rect? origin}) {
    _navigatorKey.currentState!.push(PlaqueRoute<void>(
      origin: origin,
      builder: (_) => JourneyPage(
        controller: _controller,
        journeyId: journeyId,
        onOpenQuest: _openQuest,
      ),
    ));
  }

  Future<void> _openQuest(String questId, {Rect? origin, double tilt = 0}) {
    return Navigator.of(context, rootNavigator: true).push(NoticeRoute<void>(
      origin: origin,
      tilt: tilt,
      builder: (routeContext) => QuestDetailPage(
        controller: _controller,
        questId: questId,
        onOpenBuddy: widget.onOpenBuddy == null
            ? null
            : () {
                Navigator.of(routeContext).pop();
                widget.onOpenBuddy!();
              },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: _navigatorKey,
        observers: [_heroController],
        onGenerateInitialRoutes: (_, _) => [
          MaterialPageRoute<void>(
            builder: (_) => GuildBoardPage(
              controller: _controller,
              onOpenJourney: _openJourney,
              onOpenQuest: _openQuest,
              onOpenBuddy: widget.onOpenBuddy,
            ),
          ),
        ],
      ),
    );
  }
}
