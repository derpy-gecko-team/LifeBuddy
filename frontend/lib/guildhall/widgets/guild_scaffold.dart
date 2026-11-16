import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/guild_theme.dart';
import 'guild_icons.dart';
import 'pressable.dart';
import 'painted_wall.dart';

class GuildScaffold extends StatefulWidget {
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
  State<GuildScaffold> createState() => _GuildScaffoldState();
}

class _GuildScaffoldState extends State<GuildScaffold> {
  final _scrolled = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) _scrolled.value = n.metrics.pixels;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: GuildColors.indigo,
        body: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: Stack(
            children: [
              Positioned.fill(child: PaintedWall(variant: widget.wall, scroll: _scrolled)),
              SafeArea(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: PointerDeviceKind.values.toSet(),
                  ),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: Column(
                      children: [
                        Expanded(child: widget.body),
                        ?widget.bottom,
                      ],
                    ),
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
