import 'package:material_ui/material_ui.dart';
import 'pages/bazaar_page.dart';
import 'pages/buddy_page.dart';
import 'pages/guild_hall_page.dart';
import 'pages/map_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _buddyIndex = 3;

  late final _pages = <Widget>[
    const MapPage(),
    GuildHallPage(onOpenBuddy: () => setState(() => _index = _buddyIndex)),
    const BazaarPage(),
    const BuddyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
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
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Buddy',
          ),
        ],
      ),
    );
  }
}
