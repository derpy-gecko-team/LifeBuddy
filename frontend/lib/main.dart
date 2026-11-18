import 'package:material_ui/material_ui.dart';
import 'package:lifebuddy/home_shell.dart';
import 'package:lifebuddy/pages/login_page.dart';
import 'package:lifebuddy/theme/app_theme.dart';

import 'bazaar/data/mock_bazaar_repository.dart';
import 'bazaar/state/bazaar_controller.dart';
import 'buddy/active_buddy.dart';
import 'guildhall/theme/guild_theme.dart';
import 'pages/bazaar_page.dart';

void main() => runApp(const LifeBuddyApp());

/// Developer shortcut: skip the login and open straight on one tab.
///
///     flutter run --dart-define=START_TAB=buddy
///
/// Empty unless that flag is passed, so a normal build still starts at the login.
const _startTab = String.fromEnvironment('START_TAB');

class LifeBuddyApp extends StatefulWidget {
  const LifeBuddyApp({super.key});

  @override
  State<LifeBuddyApp> createState() => _LifeBuddyAppState();
}

class _LifeBuddyAppState extends State<LifeBuddyApp> {
  late final BazaarController _bazaar = BazaarController(
    MockBazaarRepository(),
    beforeFirstLoad: GuildText.preload,
  )..load();

  @override
  void dispose() {
    _bazaar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Above the root navigator, so every screen (and the login) sees the same Bazaar and guide.
      builder: (context, child) => BazaarScope(
        controller: _bazaar,
        child: ListenableBuilder(
          listenable: _bazaar,
          builder: (context, child) => ActiveBuddy(
            look: BuddyLook.forWare(_bazaar.activeBuddyId),
            child: child!,
          ),
          child: child,
        ),
      ),
      home: _startTab.isEmpty ? const LoginPage() : const HomeShell(initialTab: _startTab),
    );
  }
}
