import 'dart:math';

import 'package:flutter/material.dart';
import 'pages/bazaar_page.dart';
import 'pages/buddy_page.dart';
import 'pages/guild_hall_page.dart';
import 'pages/map_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab});

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

  late final _pages = <Widget>[
    const MapPage(),
    GuildHallPage(onOpenBuddy: () => setState(() => _index = _buddyIndex)),
    const BazaarPage(),
    BuddyPage(
      onOpenGuildHall: () => setState(() => _index = _guildHallIndex),
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
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(
              icon: Icon(Icons.castle_outlined),
              selectedIcon: Icon(Icons.castle),
              label: 'Guild Hall',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Bazaar',
            ),
            NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Buddy'),
          ],
        ),
      ),
    );
  }
}
