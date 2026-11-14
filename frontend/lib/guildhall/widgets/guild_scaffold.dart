import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/guild_theme.dart';
import 'guild_icons.dart';
import 'pressable.dart';
import 'stone_wall.dart';

class GuildScaffold extends StatelessWidget {
  const GuildScaffold({
    super.key,
    required this.body,
    this.bottom,
    this.wall = WallVariant.board,
  });

  final Widget body;

  final Widget? bottom;
  final WallVariant wall;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: GuildColors.mortar,
        body: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: Stack(
            children: [
              Positioned.fill(child: StoneWall(variant: wall)),
              SafeArea(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: PointerDeviceKind.values.toSet(),
                  ),
                  child: Column(
                    children: [
                      Expanded(child: body),
                      ?bottom,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuildBackLink extends StatelessWidget {
  const GuildBackLink({super.key, required this.label, required this.onTap, this.showLabel = true});

  final String label;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back to $label',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GuildIcon(GuildGlyph.chevronLeft, size: 22),
                if (showLabel) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: GuildText.hand(GuildType.lg, color: GuildColors.cream),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
