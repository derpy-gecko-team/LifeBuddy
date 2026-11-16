import 'package:material_ui/material_ui.dart';
import 'package:lifebuddy/pages/login_page.dart';
import 'package:lifebuddy/theme/app_theme.dart';

void main() => runApp(const LifeBuddyApp());

class LifeBuddyApp extends StatelessWidget {
  const LifeBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light() as ThemeData?,
      home: const LoginPage(),
    );
  }
}