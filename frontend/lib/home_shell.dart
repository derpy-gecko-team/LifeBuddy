import 'dart:math';

import 'package:flutter/material.dart';
import 'bazaar/state/bazaar_controller.dart';
import 'buddy/data/mock_buddy_repository.dart';
import 'buddy/data/models.dart';
import 'theme/app_colors.dart';
import 'guildhall/data/api_quest_repository.dart';
import 'guildhall/data/mock_quest_repository.dart';
import 'guildhall/state/guild_hall_remote.dart';
import 'pages/bazaar_page.dart';
import 'pages/buddy_page.dart';
import 'pages/guild_hall_page.dart';
import 'pages/map_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.bazaar, this.initialTab});

  final BazaarController? bazaar;

  /// The tab to open on: `map`, `guildhall`, `bazaar` or `buddy`. Anything
  /// else, or nothing, opens on the map.
  final String? initialTab;

  static const tabs = ['map', 'guildhall', 'bazaar', 'buddy'];

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = max(0, HomeShell.tabs.indexOf(widget.initialTab ?? ''));

  static const _mapIndex = 0;
  static const _guildHallIndex = 1;
  static const _buddyIndex = 3;

  // One set of quests for the whole app. The Guild Hall shows them and the
  // Buddy posts and fulfils them, so what Pip says it did is really there.
  // Both are mocks until the app talks to the server; there, the quests live
  // on the server and each tab simply fetches them.
  final _quests = MockQuestRepository();
  final _guildHall = GuildHallRemote();

  // New quests the hero has not been to the Guild Hall to see yet.
  int _unseenQuests = 0;

  void _onQuestsChanged(List<QuestUpdate> changed) {
    _guildHall.refresh();
    final posted = changed.where((quest) => !quest.fulfilled).length;
    if (posted == 0) return;
    // The Buddy page sends a notice flying to this tab; count it as it lands.
    Future<void>.delayed(const Duration(milliseconds: 2300), () {
      if (mounted && _index != _guildHallIndex) setState(() => _unseenQuests += posted);
    });
  }

  void _show(int index) => setState(() {
    _index = index;
    if (index == _guildHallIndex) _unseenQuests = 0;
  });

  @override
  void dispose() {
    _guildHall.dispose();
    super.dispose();
  }

  late final _pages = <Widget>[
    const MapPage(),
    GuildHallPage(repository: ApiQuestRepository(fallback: _quests), remote: _guildHall, onOpenBuddy: () => setState(() => _index = _buddyIndex)),
    BazaarPage(controller: widget.bazaar),
    BuddyPage(
      repository: MockBuddyRepository(quests: _quests),
      onQuestsChanged: _onQuestsChanged,
      onOpenQuest: (questId) {
        _show(_guildHallIndex);
        _guildHall.openQuest(questId);
      },
      onOpenMap: () => setState(() => _index = _mapIndex),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // The shell does not know the keyboard exists. The keyboard's inset is
    // dropped, and so is its side effect: while it is up, the system takes
    // the bottom safe-area padding away, which would shrink the tab bar and
    // stretch every tab by that much, then snap back. [viewPadding] is the
    // same padding with the keyboard left out of it, so nothing in any tab
    // moves, is rebuilt or is laid out again; the keyboard simply slides
    // over the foot of the screen.
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(viewInsets: EdgeInsets.zero, padding: media.viewPadding),
      child: Scaffold(
        // The keyboard slides over the page instead of squeezing it. All four
        // tabs stay alive in the IndexedStack, so a resize would lay every one
        // of them out again, and repaint the Guild Hall and Bazaar walls, on
        // each frame of the keyboard's animation.
        resizeToAvoidBottomInset: false,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _show,
          destinations: [
            const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(
              // How many quests the Buddy has posted since the hero last looked.
              icon: Badge(
                isLabelVisible: _unseenQuests > 0,
                label: Text('$_unseenQuests'),
                backgroundColor: AppColors.wax,
                textColor: AppColors.parchmentLight,
                child: const Icon(Icons.castle_outlined),
              ),
              selectedIcon: const Icon(Icons.castle),
              label: 'Guild Hall',
            ),
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Bazaar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'Buddy',
            ),
          ],
        ),
      ),
    );
  }
}
