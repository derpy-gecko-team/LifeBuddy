import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/guild_theme.dart';
import 'motion.dart';
import 'pressable.dart';
import 'sketch.dart';

class TagRailItem {
  const TagRailItem({required this.label, required this.selected, required this.onTap, this.count});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;
}

class TagRail extends StatelessWidget {
  const TagRail({super.key, required this.tags});

  final List<TagRailItem> tags;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 4,
          child: Container(height: 2, color: GuildColors.chalkLine),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: GuildSpace.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tag in tags)
                Padding(
                  padding: const EdgeInsets.only(right: GuildSpace.sm),
                  child: HangingTag(label: tag.label, count: tag.count, selected: tag.selected, onTap: tag.onTap),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PinnedTagRail extends SliverPersistentHeaderDelegate {
  PinnedTagRail({required this.tags, required this.extent, required this.pinned});

  final List<TagRailItem> tags;
  final double extent;
  final ValueListenable<bool> pinned;

  static double extentFor(BuildContext context) => 62 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 1.6;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: pinned,
          builder: (context, isPinned, child) => AnimatedOpacity(
            opacity: isPinned ? 1 : 0,
            duration: GuildMotion.quick,
            child: child,
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: GuildColors.indigo,
              border: Border(bottom: BorderSide(color: GuildColors.chalkLine, width: 1.5)),
            ),
          ),
        ),
        Align(alignment: Alignment.topCenter, child: TagRail(tags: tags)),
      ],
    );
  }

  @override
  bool shouldRebuild(PinnedTagRail old) => true;
}

class HangingTag extends StatelessWidget {
  const HangingTag({super.key, required this.label, required this.selected, required this.onTap, this.count});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? GuildColors.brickDeep : GuildColors.cream;
    return GuildPressable(
      selected: selected,
      semanticLabel: count == null ? label : '$label, $count',
      onTap: onTap,
      haptic: true,
      child: HangingSway(
        nudged: selected,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 2, height: 12, margin: const EdgeInsets.only(top: 6), color: GuildColors.chalkLine),
            CustomPaint(
              painter: _TagPainter(selected: selected, seed: stableSeed(label)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 42),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: GuildText.label(GuildType.sm, color: fg)),
                      if (count != null) ...[
                        const SizedBox(width: GuildSpace.sm),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: selected ? GuildColors.brickDeep : GuildColors.shadow,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            '$count',
                            textAlign: TextAlign.center,
                            style: GuildText.label(GuildType.xs, color: GuildColors.cream, spacing: 0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPainter extends CustomPainter {
  _TagPainter({required this.selected, required this.seed});
  final bool selected;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    const cut = 9.0;
    final sketch = Sketch.of([
      const Offset(cut, 0),
      Offset(size.width - cut, 0),
      Offset(size.width, cut),
      Offset(size.width, size.height),
      Offset(0, size.height),
      const Offset(0, cut),
    ], seed);
    sketch.paintFill(canvas, selected ? GuildColors.parchment : GuildColors.indigoDeep, shadow: GuildShadow.box);
    sketch.paintShading(
      canvas,
      ink: selected ? GuildColors.pencil : GuildColors.cream,
      strength: selected ? 1.2 : 0.45,
    );
    sketch.paintBorder(canvas, color: selected ? GuildColors.pencil : GuildColors.chalkLine, width: 1.5);
    canvas.drawCircle(
      Offset(size.width / 2, 5),
      2.2,
      Paint()..color = selected ? GuildColors.indigoDeep : GuildColors.chalk,
    );
  }

  @override
  bool shouldRepaint(_TagPainter old) => old.selected != selected || old.seed != seed;
}
