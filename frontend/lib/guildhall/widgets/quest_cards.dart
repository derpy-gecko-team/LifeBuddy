import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import 'deadline_format.dart';
import 'notice_route.dart';
import 'ornaments.dart';
import 'pressable.dart';
import 'torn_paper.dart';

String? questBadgeAsset(Quest quest, DateTime now) {
  if (quest.status == QuestStatus.fulfilled || quest.status == QuestStatus.sealed) return null;
  if (quest.isBoss) return GuildAssets.badgeSkull;
  if (quest.isUrgent(now)) return GuildAssets.badgeFlame;
  return null;
}

String _semanticsFor(Quest q, DateTime now) {
  return [
    if (q.isBoss) 'Boss quest',
    q.title,
    q.flavor,
    '${q.xp} XP',
    switch (q.status) {
      QuestStatus.open => 'open',
      QuestStatus.sworn => 'sworn, ${q.trialsDone} of ${q.trials.length} trials done',
      QuestStatus.sealed => 'sealed. ${q.sealedReason ?? ''}',
      QuestStatus.fulfilled => 'fulfilled',
    },
    if (q.deadline != null && q.status != QuestStatus.fulfilled) 'due ${deadlineLabel(q.deadline!, now)}',
  ].join('. ');
}

class _DeadlineOrPeril extends StatelessWidget {
  const _DeadlineOrPeril({required this.quest, required this.now});

  final Quest quest;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final deadline = quest.deadline;
    if (deadline == null || quest.status == QuestStatus.fulfilled) {
      return PerilSkulls(peril: quest.peril);
    }
    final color = quest.isUrgent(now) ? GuildColors.crimsonDeep : GuildColors.inkSoft;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Image.asset(GuildAssets.iconHourglass, height: 16)),
        const SizedBox(width: 5),
        Text(deadlineLabel(deadline, now), style: GuildText.body(GuildType.sm, color: color)),
      ],
    );
  }
}

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.now,
    required this.onOpen,
    this.tilt = 0,
  });

  final Quest quest;
  final DateTime now;
  final OpenQuest onOpen;

  final double tilt;

  static double _textFactor(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(100) / 100).clamp(1.0, 1.5);

  static double widthFor(BuildContext context, Quest quest) =>
      (quest.isBoss ? 214.0 : 178.0) * (1 + (_textFactor(context) - 1) * 0.5);

  static double heightFor(BuildContext context) => 296.0 * _textFactor(context);

  @override
  Widget build(BuildContext context) {
    final seed = stableSeed(quest.id);
    final badge = questBadgeAsset(quest, now);
    final sealed = quest.status == QuestStatus.sealed;

    final paper = TornPaper.forTone(
      tone: quest.paper,
      seed: seed,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quest.isBoss)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Wanted', style: GuildText.label(GuildType.xs, color: GuildColors.crimsonDeep, spacing: 2)),
            ),
          ExcludeSemantics(
            child: Image.asset(quest.iconAsset, height: quest.isBoss ? 84 : 58, fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          Text(
            quest.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GuildText.title(GuildType.lg),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              quest.flavor,
              maxLines: quest.isBoss || sealed ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: GuildText.body(GuildType.sm),
            ),
          ),
          if (sealed) const SizedBox(height: 15) else const DashedLine(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, child: _DeadlineOrPeril(quest: quest, now: now)),
                ),
              ),
              const SizedBox(width: 8),
              Text('+${quest.xp} XP', style: GuildText.label(GuildType.sm, color: GuildColors.bronze)),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: _semanticsFor(quest, now),
      excludeSemantics: true,
      child: GuildPressable(
        onTap: () => onOpen(quest.id, origin: globalRectOf(context), tilt: tilt),
        pressedScale: 1.04,
        haptic: true,
        builder: (context, pressed) => AnimatedRotation(
          turns: pressed ? 0 : tilt / (2 * pi),
          duration: GuildMotion.press,
          curve: Curves.easeOut,
          child: SizedBox(
            width: widthFor(context, quest),
            height: heightFor(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: paper),
                if (sealed) ...[
                  const Positioned(left: 2, right: 2, bottom: 50, child: SealRibbon()),
                  const Positioned(left: 0, right: 0, bottom: 35, child: Center(child: WaxSeal(size: 44))),
                ],
                if (quest.status == QuestStatus.fulfilled)
                  const Positioned(top: 22, right: 8, child: FulfilledStamp()),
                Positioned(
                  top: -9,
                  left: 0,
                  right: 0,
                  child: Center(child: Fastener(kind: FastenerKind.values[seed % FastenerKind.values.length])),
                ),
                if (badge != null) Positioned(top: -12, right: -10, child: RoundBadge(asset: badge, size: 48)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuestRow extends StatelessWidget {
  const QuestRow({super.key, required this.quest, required this.now, required this.onOpen});

  final Quest quest;
  final DateTime now;
  final OpenQuest onOpen;

  static const _medallion = 66.0;

  @override
  Widget build(BuildContext context) {
    final badge = questBadgeAsset(quest, now);
    final sealed = quest.status == QuestStatus.sealed;
    final fulfilled = quest.status == QuestStatus.fulfilled;

    final paper = TornPaper.forTone(
      tone: quest.paper,
      seed: stableSeed(quest.id),
      tear: 5,
      tearBottom: 16,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 26),
      child: Row(
        children: [
          if (sealed)
            const SizedBox(width: _medallion, height: _medallion)
          else
            DashedBorder(
              circle: true,
              padding: const EdgeInsets.all(10),
              child: SizedBox.square(
                dimension: _medallion - 20,
                child: ExcludeSemantics(child: Image.asset(quest.iconAsset, fit: BoxFit.contain)),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, style: GuildText.title(GuildType.lg)),
                const SizedBox(height: 3),
                Text(quest.flavor, style: GuildText.body(GuildType.sm)),
                if (sealed && quest.sealedReason != null) ...[
                  const SizedBox(height: 4),
                  Text(quest.sealedReason!, style: GuildText.aside(GuildType.sm, color: GuildColors.verdigrisDark)),
                ],
                if (quest.status == QuestStatus.sworn) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sworn, ${quest.trialsDone} of ${quest.trials.length} trials done',
                    style: GuildText.aside(GuildType.sm, color: GuildColors.inkSoft),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${quest.xp} XP', style: GuildText.label(GuildType.sm, color: GuildColors.bronze)),
              const SizedBox(height: 8),
              if (fulfilled) const FulfilledStamp() else _DeadlineOrPeril(quest: quest, now: now),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: _semanticsFor(quest, now),
      excludeSemantics: true,
      child: GuildPressable(
        onTap: () => onOpen(quest.id, origin: globalRectOf(context)),
        pressedScale: 0.98,
        haptic: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            paper,
            if (sealed) ...[
              const Positioned(
                left: 18 + _medallion / 2 - 7,
                top: 4,
                bottom: 12,
                child: SealRibbon(axis: Axis.vertical),
              ),
              const Positioned(
                left: 18 + (_medallion - 52) / 2,
                top: 0,
                bottom: 6,
                child: Center(child: WaxSeal(size: 52)),
              ),
            ],
            if (badge != null) Positioned(top: -20, left: 70, child: RoundBadge(asset: badge, size: 44)),
            if (quest.paper == PaperTone.sage && !sealed)
              const Positioned(top: 10, left: 12, child: Fastener(kind: FastenerKind.pin)),
          ],
        ),
      ),
    );
  }
}

enum FastenerKind { tape, pin, nail }

class Fastener extends StatelessWidget {
  const Fastener({super.key, required this.kind});

  final FastenerKind kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case FastenerKind.tape:
        return Transform.rotate(
          angle: -0.06,
          child: Container(
            width: 62,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF5A6A70),
              border: Border.all(color: GuildColors.ink, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      case FastenerKind.pin:
        return Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: GuildColors.ink,
            boxShadow: [BoxShadow(color: Colors.black38, offset: Offset(1, 2))],
          ),
          alignment: const Alignment(-0.3, -0.3),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white38),
          ),
        );
      case FastenerKind.nail:
        return Transform.rotate(
          angle: 0.5,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3F42),
              border: Border.all(color: GuildColors.ink, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(1, 2))],
            ),
          ),
        );
    }
  }
}
