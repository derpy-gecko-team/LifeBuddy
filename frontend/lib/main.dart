import 'package:flutter/material.dart';
import 'package:lifebuddy/home_shell.dart';
import 'package:lifebuddy/pages/login_page.dart';
import 'package:lifebuddy/theme/app_theme.dart';

void main() => runApp(const LifeBuddyApp());

/// Developer shortcut: skip the login and open straight on one tab.
///
///     flutter run --dart-define=START_TAB=buddy
///
/// Empty unless that flag is passed, so a normal build still starts at the login.
const _startTab = String.fromEnvironment('START_TAB');

class LifeBuddyApp extends StatelessWidget {
  const LifeBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _startTab.isEmpty ? const LoginPage() : const HomeShell(initialTab: _startTab),
    );
  }
}