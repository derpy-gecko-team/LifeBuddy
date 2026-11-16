import 'package:flutter/material.dart';

import '../buddy/data/buddy_repository.dart';
import '../buddy/data/mock_buddy_repository.dart';
import '../buddy/pages/hearth_page.dart';
import '../buddy/state/buddy_controller.dart';
import '../buddy/theme/buddy_theme.dart';

class BuddyPage extends StatefulWidget {
  const BuddyPage({super.key, this.repository, this.onOpenGuildHall, this.onOpenMap});

  final BuddyRepository? repository;

  final VoidCallback? onOpenGuildHall;
  final VoidCallback? onOpenMap;

  @override
  State<BuddyPage> createState() => _BuddyPageState();
}

class _BuddyPageState extends State<BuddyPage> {
  late final BuddyController _controller = BuddyController(widget.repository ?? MockBuddyRepository());

  /// The hand-drawn fonts, so Pip's first line is not seen in a fallback face.
  late final Future<void> _fonts = BuddyText.preload();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _fonts,
      builder: (context, fonts) {
        if (fonts.connectionState != ConnectionState.done) {
          return const ColoredBox(color: BuddyColors.night, child: SizedBox.expand());
        }
        return HearthPage(
          controller: _controller,
          onOpenGuildHall: widget.onOpenGuildHall,
          onOpenMap: widget.onOpenMap,
        );
      },
    );
  }
}
