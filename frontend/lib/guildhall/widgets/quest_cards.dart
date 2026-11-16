import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import 'deadline_format.dart';
import 'motion.dart';
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
    final color = quest.isUrgent(now) ? GuildColors.brickDeep : GuildColors.inkSoft;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Image.asset(GuildAssets.iconHourglass, height: 16)),
        const SizedBox(width: GuildSpace.xs),
        Text(deadlineLabel(deadline, now), style: GuildText.body(GuildType.sm, color: color)),
      ],
    );
  }
}

class QuestCard extends StatefulWidget {
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
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  int _pinnedBack = 0;

  Future<void> _open() async {
    await widget.onOpen(widget.quest.id, origin: globalRectOf(context), tilt: widget.tilt);
    if (mounted) setState(() => _pinnedBack++);
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final now = widget.now;
    final tilt = widget.tilt;
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
              child: Text('Wanted', style: GuildText.label(GuildType.xs, color: GuildColors.brickDeep, spacing: 2)),
            ),
          ExcludeSemantics(
            child: Image.asset(quest.iconAsset, height: quest.isBoss ? 84 : 58, fit: BoxFit.contain),
          ),
          const SizedBox(height: GuildSpace.md),
          Text(
            quest.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GuildText.title(GuildTitle.lg),
          ),
          const SizedBox(height: GuildSpace.sm),
          Expanded(
            child: Text(
              quest.flavor,
              maxLines: quest.isBoss || sealed ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: GuildText.body(GuildType.sm),
            ),
          ),
          if (sealed) const SizedBox(height: GuildSpace.lg) else const DashedLine(),
          const SizedBox(height: GuildSpace.sm),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, child: _DeadlineOrPeril(quest: quest, now: now)),
                ),
              ),
              const SizedBox(width: GuildSpace.sm),
              Text('+${quest.xp} XP', style: GuildText.label(GuildType.sm, color: GuildColors.bronze)),
            ],
          ),
        ],
      ),
    );

    return GuildPressable(
      semanticLabel: _semanticsFor(quest, now),
      onTap: _open,
      pressedScale: 1.04,
      haptic: true,
      builder: (context, pressed) => PinnedSwing(
        rest: tilt,
        held: pressed,
        nudges: _pinnedBack,
        child: SizedBox(
          width: QuestCard.widthFor(context, quest),
          height: QuestCard.heightFor(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: paper),
              SealBreak(
                sealed: sealed,
                builder: (breaking) => [
                  Positioned(left: 2, right: 2, bottom: 50, child: PartingRibbon(breaking: breaking)),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 35,
                    child: Center(child: FallingSeal(breaking: breaking, size: 44)),
                  ),
                ],
              ),
              if (quest.status == QuestStatus.fulfilled)
                const Positioned(top: 22, right: 8, child: InkStamp('Fulfilled')),
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
          const SizedBox(width: GuildSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, style: GuildText.title(GuildTitle.lg)),
                const SizedBox(height: GuildSpace.xs),
                Text(quest.flavor, style: GuildText.body(GuildType.sm)),
                if (sealed && quest.sealedReason != null) ...[
                  const SizedBox(height: GuildSpace.xs),
                  Text(quest.sealedReason!, style: GuildText.aside(GuildType.sm, color: GuildColors.indigoDeep)),
                ],
                if (quest.status == QuestStatus.sworn) ...[
                  const SizedBox(height: GuildSpace.xs),
                  Text(
                    'Sworn, ${quest.trialsDone} of ${quest.trials.length} trials done',
                    style: GuildText.body(GuildType.sm),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: GuildSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${quest.xp} XP', style: GuildText.label(GuildType.sm, color: GuildColors.bronze)),
              const SizedBox(height: GuildSpace.sm),
              if (fulfilled) const InkStamp('Fulfilled') else _DeadlineOrPeril(quest: quest, now: now),
            ],
          ),
        ],
      ),
    );

    return GuildPressable(
      semanticLabel: _semanticsFor(quest, now),
      onTap: () => onOpen(quest.id, origin: globalRectOf(context)),
      pressedScale: 0.98,
      haptic: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          paper,
          SealBreak(
            sealed: sealed,
            builder: (breaking) => [
              Positioned(
                left: 18 + _medallion / 2 - 7,
                top: 4,
                bottom: 12,
                child: PartingRibbon(breaking: breaking, axis: Axis.vertical),
              ),
              Positioned(
                left: 18 + (_medallion - 52) / 2,
                top: 0,
                bottom: 6,
                child: Center(child: FallingSeal(breaking: breaking, size: 52)),
              ),
            ],
          ),
          if (badge != null) Positioned(top: -14, right: -8, child: RoundBadge(asset: badge, size: 44)),
          if (quest.paper == PaperTone.sage && !sealed)
            const Positioned(top: 10, left: 12, child: Fastener(kind: FastenerKind.pin)),
        ],
      ),
    );
  }
}
