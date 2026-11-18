import 'package:material_ui/material_ui.dart';

import '../buddy/data/buddy_ears.dart';
import '../buddy/data/buddy_repository.dart';
import '../buddy/data/mock_buddy_repository.dart';
import '../buddy/data/models.dart';
import '../buddy/data/phone_ears.dart';
import '../buddy/pages/hearth_page.dart';
import '../buddy/state/buddy_controller.dart';
import '../buddy/theme/buddy_theme.dart';

class BuddyPage extends StatefulWidget {
  const BuddyPage({super.key, this.repository, this.ears, this.onOpenQuest, this.onOpenMap, this.onQuestsChanged});

  final BuddyRepository? repository;

  /// How the Buddy hears the hero. The phone's speech recogniser unless given.
  final BuddyEars? ears;

  final void Function(String questId)? onOpenQuest;
  final VoidCallback? onOpenMap;

  /// The Buddy posted or fulfilled a quest: time for the Guild Hall to look again.
  final void Function(List<QuestUpdate> changed)? onQuestsChanged;

  @override
  State<BuddyPage> createState() => _BuddyPageState();
}

class _BuddyPageState extends State<BuddyPage> {
  late final BuddyController _controller = BuddyController(
    widget.repository ?? MockBuddyRepository(),
    onQuestsChanged: (changed) => widget.onQuestsChanged?.call(changed),
  );
  late final BuddyEars _ears = widget.ears ?? PhoneEars();

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
          ears: _ears,
          onOpenQuest: widget.onOpenQuest,
          onOpenMap: widget.onOpenMap,
        );
      },
    );
  }
}
