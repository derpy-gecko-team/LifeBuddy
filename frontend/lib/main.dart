import 'package:flutter/material.dart';

import 'home_shell.dart';

void main() {
  runApp(const LifeBuddyApp());
}

class LifeBuddyApp extends StatelessWidget {
  const LifeBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'LifeBuddy', home: const HomeShell());
  }
}
