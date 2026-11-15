import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/guild_hall_controller.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import 'deadline_format.dart';
import 'guild_icons.dart';
import 'notice_route.dart';
import 'ornaments.dart';
import 'pressable.dart';
import 'sketch.dart';
import 'torn_paper.dart';
import 'hanging_slip.dart';
import 'motion.dart';

String toRoman(int n) {
  const map = {
    1000: 'M', 900: 'CM', 500: 'D', 400: 'CD', 100: 'C', 90: 'XC',
    50: 'L', 40: 'XL', 10: 'X', 9: 'IX', 5: 'V', 4: 'IV', 1: 'I',
  };
  final out = StringBuffer();
  var rest = n;
  for (final e in map.entries) {
    while (rest >= e.key) {
      out.write(e.value);
      rest -= e.key;
    }
  }
  return out.toString();
}

class BoardHeader extends StatelessWidget {
  const BoardHeader({super.key, required this.newToday, this.drawTitle = false, this.onTitleDrawn});

  final int newToday;

  /// Draws the stroke under the title in, the first time the hall is shown.
  final bool drawTitle;
  final VoidCallback? onTitleDrawn;

  @override
  Widget build(BuildContext context) {
    final subtitle = newToday == 0
        ? 'No new quests today. Tell your Buddy what you want to do next.'
        : '$newToday new ${newToday == 1 ? 'quest was' : 'quests were'} pinned at dawn.';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          right: -8,
          top: -6,
          child: GuildArt(GuildAssets.torch, height: 124),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 76),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const GuildArt(GuildAssets.crestSword, height: 52),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        child: LetteredTitle(
                          'The Guildhall',
                          size: GuildType.display,
                          drawIn: drawTitle,
                          onDrawn: onTitleDrawn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: GuildText.aside(GuildType.md)),
            ],
          ),
        ),
      ],
    );
  }
}

class RankSign extends StatelessWidget {
  const RankSign({super.key, required this.hero, this.onOpenBuddy});

  final HeroProgress hero;
  final VoidCallback? onOpenBuddy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: HangingSlip(
            child: Row(
              children: [
                ExcludeSemantics(child: Image.asset(GuildAssets.rankShield, height: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 8,
                        children: [
                          Text(
                            '${hero.rankTitle} ${toRoman(hero.level)}',
                            style: GuildText.title(GuildType.lg),
                          ),
                          Text(
                            '${hero.xp} / ${hero.xpToNext} XP',
                            style: GuildText.label(GuildType.xs, color: GuildColors.inkSoft),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ExcludeSemantics(
                        child: GuildProgressBar(
                          value: hero.progress,
                          height: 8,
                          track: GuildColors.parchmentDark,
                          fill: GuildColors.brick,
                          edge: GuildColors.pencil,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onOpenBuddy != null) ...[
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Talk to your Buddy',
            excludeSemantics: true,
            child: GuildPressable(
              onTap: onOpenBuddy,
              haptic: true,
              pressedScale: 0.92,
              child: const RoundBadge(asset: GuildAssets.buddyEnvelope, size: 60),
            ),
          ),
        ],
      ],
    );
  }
}

class QuestTagRail extends StatelessWidget {
  const QuestTagRail({super.key, required this.controller});

  final GuildHallController controller;

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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in QuestFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _Tag(
                    label: f.label,
                    count: f == QuestFilter.all ? null : controller.countFor(f),
                    selected: controller.filter == f,
                    onTap: () => controller.setFilter(f),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.selected, required this.onTap, this.count});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? GuildColors.brickDeep : GuildColors.cream;
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : '$label, $count',
      excludeSemantics: true,
      child: GuildPressable(
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
                          const SizedBox(width: 8),
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
    sketch.paintFill(canvas, selected ? GuildColors.parchment : GuildColors.indigoDeep, shadow: const Offset(2, 3));
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

class QuestlinePlaque extends StatelessWidget {
  const QuestlinePlaque({super.key, required this.questline, required this.onTap});

  final Questline questline;
  final ValueChanged<Rect?> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${questline.name}, ${questline.fulfilledCount} of '
          '${questline.quests.length} quests fulfilled. Open questline.',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: () => onTap(globalRectOf(context)),
        pressedScale: 0.98,
        child: SketchBox(
          color: GuildColors.indigoDeep,
          borderColor: GuildColors.chalkLine,
          borderWidth: 1.6,
          bevel: 10,
          shadow: const Offset(2, 4),
          seed: stableSeed(questline.id),
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(left: -7, top: -5, child: ChalkStar(seed: 1)),
              const Positioned(right: -3, top: -5, child: ChalkStar(seed: 2)),
              const Positioned(left: -7, bottom: -5, child: ChalkStar(seed: 3)),
              const Positioned(right: -3, bottom: -5, child: ChalkStar(seed: 4)),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GuildColors.indigo,
                      shape: BoxShape.circle,
                      border: Border.all(color: GuildColors.chalk, width: 1.8),
                    ),
                    child: QuestlineEmblem(questline: questline, size: 35),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(questline.name, style: GuildText.title(GuildType.lg, color: GuildColors.cream)),
                        const SizedBox(height: 2),
                        Text(
                          '${questline.fulfilledCount} of ${questline.quests.length} quests fulfilled',
                          style: GuildText.aside(GuildType.sm),
                        ),
                        const SizedBox(height: 8),
                        SealProgress(total: questline.quests.length, done: questline.fulfilledCount),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const GuildIcon(GuildGlyph.chevronRight, size: 22, color: GuildColors.goldBright),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DueTodayStrip extends StatelessWidget {
  const DueTodayStrip({super.key, required this.quests, required this.now, required this.onOpenQuest});

  final List<Quest> quests;
  final DateTime now;
  final void Function(String questId, BuildContext rowContext) onOpenQuest;

  @override
  Widget build(BuildContext context) {
    return TornPaper(
      color: GuildColors.vellum,
      seed: 3,
      tear: 4,
      tearBottom: 10,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GuildIcon(GuildGlyph.flame, size: 20, color: GuildColors.brickDeep),
              const SizedBox(width: 8),
              Semantics(
                header: true,
                child: Text('Due today', style: GuildText.title(GuildType.lg)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final (i, quest) in quests.indexed) ...[
            if (i > 0) const DashedLine(),
            Builder(
              builder: (rowContext) => Semantics(
                button: true,
                label: '${quest.title}, ${deadlineLabel(quest.deadline!, now)}, ${quest.xp} XP',
                excludeSemantics: true,
                child: GuildPressable(
                  onTap: () => onOpenQuest(quest.id, rowContext),
                  pressedScale: 0.98,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            quest.title,
                            style: GuildText.title(GuildType.md),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          deadlineLabel(quest.deadline!, now),
                          style: GuildText.aside(GuildType.sm, color: GuildColors.inkSoft),
                        ),
                        const SizedBox(width: 6),
                        const GuildIcon(GuildGlyph.chevronRight, size: 18, color: GuildColors.ink),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
