import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/guild_hall_controller.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import 'deadline_format.dart';
import 'guild_icons.dart';
import 'ornaments.dart';
import 'pressable.dart';
import 'torn_paper.dart';
import 'wood_sign.dart';

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
  const BoardHeader({super.key, required this.newToday});

  final int newToday;

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
                        child: Text(
                          'The Guildhall',
                          style: GuildText.title(GuildType.display, color: GuildColors.cream),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
          child: WoodSign(
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
                            style: GuildText.label(GuildType.md),
                          ),
                          Text(
                            '${hero.xp} / ${hero.xpToNext} XP',
                            style: GuildText.label(GuildType.xs, color: GuildColors.goldBright),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ExcludeSemantics(child: GuildProgressBar(value: hero.progress, height: 8)),
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
          child: Container(
            height: 5,
            decoration: const BoxDecoration(
              color: GuildColors.ink,
              boxShadow: [BoxShadow(color: Colors.black45, offset: Offset(0, 2))],
            ),
          ),
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
    final fg = selected ? GuildColors.ink : GuildColors.cream;
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : '$label, $count',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        haptic: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 2.5, height: 12, margin: const EdgeInsets.only(top: 6), color: const Color(0xFF9A8B6A)),
            CustomPaint(
              painter: _TagPainter(selected: selected),
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
                            color: selected ? GuildColors.ink : GuildColors.shadow,
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
  _TagPainter({required this.selected});
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    const cut = 9.0;
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
    canvas.drawPath(path.shift(const Offset(2, 3)), Paint()..color = GuildColors.shadow);
    canvas.drawPath(path, Paint()..color = selected ? GuildColors.cream : GuildColors.leather);
    canvas.drawPath(
      path,
      Paint()
        ..color = selected ? GuildColors.ink : GuildColors.panelBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(size.width / 2, 5), 2.5, Paint()..color = GuildColors.shadow);
  }

  @override
  bool shouldRepaint(_TagPainter old) => old.selected != selected;
}

class QuestlinePlaque extends StatelessWidget {
  const QuestlinePlaque({super.key, required this.questline, required this.onTap});

  final Questline questline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${questline.name}, ${questline.fulfilledCount} of '
          '${questline.quests.length} quests fulfilled. Open questline.',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: const ShapeDecoration(
            color: GuildColors.panel,
            shape: BeveledRectangleBorder(
              side: BorderSide(color: GuildColors.panelBorder, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            shadows: [BoxShadow(color: GuildColors.shadow, offset: Offset(3, 5))],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(left: -4, top: -2, child: _Rivet()),
              const Positioned(right: 0, top: -2, child: _Rivet()),
              const Positioned(left: -4, bottom: -2, child: _Rivet()),
              const Positioned(right: 0, bottom: -2, child: _Rivet()),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GuildColors.leather,
                      shape: BoxShape.circle,
                      border: Border.all(color: GuildColors.gold, width: 2.5),
                    ),
                    child: Image.asset(questline.emblemAsset, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(questline.name, style: GuildText.label(GuildType.lg, spacing: 0.6)),
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

class _Rivet extends StatelessWidget {
  const _Rivet();

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: GuildColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: GuildColors.cream.withValues(alpha: 0.4), width: 1.2),
        ),
      );
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
              const GuildIcon(GuildGlyph.flame, size: 20, color: GuildColors.crimsonDeep),
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
                            style: GuildText.title(GuildType.lg),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          deadlineLabel(quest.deadline!, now),
                          style: GuildText.aside(GuildType.sm, color: GuildColors.crimsonDeep),
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
