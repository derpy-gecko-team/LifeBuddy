import 'package:flutter/material.dart';

import '../data/mock_quest_repository.dart';
import '../data/models.dart';
import '../data/quest_repository.dart';
import '../state/guild_hall_controller.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import '../widgets/claim_ceremony.dart';
import '../widgets/deadline_format.dart';
import '../widgets/guild_feedback.dart';
import '../widgets/guild_icons.dart';
import '../widgets/guild_scaffold.dart';
import '../widgets/motion.dart';
import '../widgets/notice_route.dart';
import '../widgets/ornaments.dart';
import '../widgets/pressable.dart';
import '../widgets/quest_cards.dart';
import '../widgets/sketch.dart';
import '../widgets/painted_wall.dart';
import '../widgets/torn_paper.dart';

class QuestDetailPage extends StatelessWidget {
  const QuestDetailPage({
    super.key,
    required this.controller,
    required this.questId,
    this.onOpenBuddy,
  });

  final GuildHallController controller;
  final String questId;
  final VoidCallback? onOpenBuddy;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final quest = controller.questById(questId);
        final line = quest == null ? null : controller.questlineById(quest.questlineId);
        if (quest == null || line == null) {
          return const GuildScaffold(wall: WallVariant.quest, body: SizedBox.shrink());
        }
        final index = line.quests.indexWhere((q) => q.id == quest.id) + 1;
        final now = DateTime.now();

        return GuildScaffold(
          wall: WallVariant.quest,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 20, 0),
                child: Row(
                  children: [
                    Flexible(
                      child: GuildBackLink(label: line.name, onTap: () => Navigator.of(context).pop()),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quest $index of ${line.quests.length}',
                      style: GuildText.label(GuildType.xs, color: GuildColors.cream),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 46, 22, 24),
                  child: RepaintBoundary(
                    child: _QuestPoster(quest: quest, now: now, controller: controller),
                  ),
                ),
              ),
            ],
          ),
          bottom: _ActionBar(quest: quest, controller: controller, onOpenBuddy: onOpenBuddy),
        );
      },
    );
  }
}

Future<void> _guarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } on QuestActionException catch (e) {
    if (context.mounted) showGuildToast(context, e.message);
  }
}

class _QuestPoster extends StatefulWidget {
  const _QuestPoster({required this.quest, required this.now, required this.controller});

  final Quest quest;
  final DateTime now;
  final GuildHallController controller;

  @override
  State<_QuestPoster> createState() => _QuestPosterState();
}

class _QuestPosterState extends State<_QuestPoster> {
  bool _justFulfilled = false;
  bool _justSworn = false;

  final _trialsEnd = GlobalKey();

  @override
  void didUpdateWidget(_QuestPoster old) {
    super.didUpdateWidget(old);
    if (old.quest.status != QuestStatus.fulfilled && widget.quest.status == QuestStatus.fulfilled) {
      _justFulfilled = true;
    }
    final swornNow = old.quest.status == QuestStatus.open && widget.quest.status == QuestStatus.sworn;
    if (swornNow) {
      _justSworn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTrials());
    } else if (widget.quest.status != QuestStatus.sworn) {
      _justSworn = false;
    }
  }

  /// Brings the trials into view, if they are not already, so the oath is
  /// seen being stamped beside them.
  void _showTrials() {
    final target = _trialsEnd.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 300),
      curve: GuildMotion.easeOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  Future<void> _toggleTrial(Trial trial) async {
    final quest = widget.quest;
    if (quest.status == QuestStatus.open) {
      showGuildToast(context, 'Swear the oath first, then tick its trials.');
      return;
    }
    if (quest.status != QuestStatus.sworn) return;
    await _guarded(context, () => widget.controller.setTrialDone(quest.id, trial.id, !trial.done));
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final now = widget.now;
    final badge = questBadgeAsset(quest, now);
    final deadline = quest.deadline;
    final fulfilled = quest.status == QuestStatus.fulfilled;
    final urgent = quest.isUrgent(now);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TornPaper(
          color: GuildColors.parchment,
          seed: stableSeed(quest.id),
          tear: 5,
          tearBottom: 18,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
          child: _DoubleRule(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
              child: Column(
                children: [
                  if (quest.isBoss) ...[
                    Text(
                      'Wanted by the Guild',
                      textAlign: TextAlign.center,
                      style: GuildText.label(GuildType.sm, color: GuildColors.brickDeep, spacing: 1.6),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Semantics(
                    header: true,
                    child: LetteredTitle(
                      quest.title,
                      size: quest.title.length > 22 ? GuildType.xl : GuildType.xxl,
                      color: GuildColors.brick,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (quest.isBoss)
                    ExcludeSemantics(child: Image.asset(quest.iconAsset, height: 200, fit: BoxFit.contain))
                  else
                    _Woodcut(asset: quest.iconAsset),
                  const SizedBox(height: 16),
                  Text(quest.description, textAlign: TextAlign.center, style: GuildText.body(GuildType.md)),
                  const SizedBox(height: 18),
                  _BuddyNote(text: quest.flavor),
                  if (quest.status == QuestStatus.sealed) ...[
                    const SizedBox(height: 18),
                    _SealedNotice(reason: quest.sealedReason),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Flexible(
                        child: Semantics(
                          header: true,
                          child: Text(
                            quest.isBoss ? 'Trials to weaken it' : 'Trials',
                            style: GuildText.label(GuildType.sm, color: GuildColors.ink),
                          ),
                        ),
                      ),
                      if (quest.status == QuestStatus.sworn) ...[
                        const SizedBox(width: 12),
                        StampIn(
                          animate: _justSworn,
                          delay: const Duration(milliseconds: 280),
                          child: const InkStamp('Sworn'),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${quest.trialsDone} of ${quest.trials.length}',
                        style: GuildText.aside(GuildType.sm, color: GuildColors.inkSoft),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final trial in quest.trials)
                    _TrialTile(
                      trial: trial,
                      enabled: quest.status == QuestStatus.sworn,
                      onTap: () => _toggleTrial(trial),
                    ),
                  SizedBox(key: _trialsEnd, height: 14),
                  const DashedLine(),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Bounty',
                          align: CrossAxisAlignment.start,
                          children: [
                            Text('+${quest.xp} XP', style: GuildText.label(GuildType.md, color: GuildColors.bronze)),
                            if (quest.titleReward != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ExcludeSemantics(child: Image.asset(GuildAssets.iconCrown, height: 16)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text('“${quest.titleReward}”', style: GuildText.body(GuildType.sm)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'Peril',
                          children: [
                            PerilSkulls(peril: quest.peril, size: 20),
                            ExcludeSemantics(child: Text(quest.peril.label, style: GuildText.body(GuildType.sm))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'Deadline',
                          align: CrossAxisAlignment.end,
                          children: deadline == null
                              ? [Text('None', style: GuildText.body(GuildType.md, color: GuildColors.ink))]
                              : [
                                  Text(
                                    deadlineDate(deadline),
                                    style: GuildText.label(
                                      GuildType.md,
                                      color: urgent ? GuildColors.brickDeep : GuildColors.ink,
                                    ),
                                  ),
                                  Text(deadlineRelative(deadline, now), style: GuildText.body(GuildType.sm)),
                                ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          top: -60,
          left: 0,
          right: 0,
          child: Center(child: GuildArt(GuildAssets.daggerPin, height: 92)),
        ),
        if (badge != null) Positioned(top: 4, right: -8, child: RoundBadge(asset: badge, size: 64)),
        if (fulfilled) ...[
          const Positioned(top: 22, right: 14, child: InkStamp('Fulfilled', fontSize: GuildType.sm)),
          Positioned(
            left: 0,
            right: 0,
            bottom: -20,
            child: Center(
              child: ExcludeSemantics(child: StampedSeal(animate: _justFulfilled, size: 66)),
            ),
          ),
        ],
      ],
    );
  }
}

class _DoubleRule extends StatelessWidget {
  const _DoubleRule({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The frame of the login page: one heavy pencil rule, a fine one inside.
    return Container(
      decoration: BoxDecoration(border: Border.all(color: GuildColors.tan, width: 3)),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: GuildColors.tan, width: 1.2)),
        child: child,
      ),
    );
  }
}

class _Woodcut extends StatelessWidget {
  const _Woodcut({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _WoodcutPainter(),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Center(child: Image.asset(asset, height: 100, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

class _WoodcutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = GuildColors.parchmentDark.withValues(alpha: 0.6));

    canvas.save();
    canvas.clipRect(rect);
    final hatch = Paint()
      ..color = GuildColors.pencil.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    final lines = Path();
    for (var x = -size.height; x < size.width; x += 7) {
      lines.moveTo(x, size.height);
      lines.lineTo(x + size.height, 0);
    }
    canvas.drawPath(lines, hatch..style = PaintingStyle.stroke);
    canvas.drawOval(
      Rect.fromCenter(center: rect.center, width: size.width * 0.62, height: size.height * 0.92),
      Paint()..color = GuildColors.parchment,
    );
    canvas.restore();

    canvas.drawRect(
      rect,
      Paint()
        ..color = GuildColors.tan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawRect(
      rect.deflate(5),
      Paint()
        ..color = GuildColors.tan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BuddyNote extends StatelessWidget {
  const _BuddyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.025,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          TornPaper(
            color: GuildColors.mist,
            foldColor: GuildColors.mistDark,
            foldCorner: true,
            seed: 9,
            tear: 3,
            tearBottom: 7,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('“$text”', style: GuildText.hand(GuildType.lg)),
                const SizedBox(height: 4),
                Text(
                  'Posted by your Buddy',
                  textAlign: TextAlign.right,
                  style: GuildText.aside(GuildType.sm, color: GuildColors.inkSoft),
                ),
              ],
            ),
          ),
          const Positioned(top: -6, child: Fastener(kind: FastenerKind.pin)),
        ],
      ),
    );
  }
}

class _SealedNotice extends StatelessWidget {
  const _SealedNotice({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const WaxSeal(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            reason ?? 'This quest is sealed for now.',
            style: GuildText.aside(GuildType.md, color: GuildColors.indigoDeep),
          ),
        ),
      ],
    );
  }
}

class _TrialTile extends StatelessWidget {
  const _TrialTile({required this.trial, required this.enabled, required this.onTap});

  final Trial trial;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: trial.done,
      enabled: enabled,
      label: trial.title,
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        pressedScale: 0.98,
        haptic: enabled,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              InkCheckbox(checked: trial.done, enabled: enabled),
              const SizedBox(width: 14),
              Expanded(
                child: StruckText(
                  trial.title,
                  style: GuildText.hand(
                    GuildType.lg,
                    color: trial.done ? GuildColors.inkSoft : GuildColors.ink,
                  ),
                  struck: trial.done,
                  lineColor: GuildColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.children,
    this.align = CrossAxisAlignment.center,
  });

  final String label;
  final List<Widget> children;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: GuildText.label(GuildType.xs, color: GuildColors.inkSoft, spacing: 1.2)),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.quest, required this.controller, this.onOpenBuddy});

  final Quest quest;
  final GuildHallController controller;
  final VoidCallback? onOpenBuddy;

  Future<void> _abandon(BuildContext context) async {
    final confirmed = await showGuildConfirm(
      context,
      title: 'Abandon this oath?',
      message: 'Breaking an oath costs ${MockQuestRepository.abandonCost} XP. '
          'The trials you ticked stay ticked.',
      cancelLabel: 'Keep the oath',
      confirmLabel: 'Abandon the oath',
    );
    if (!confirmed || !context.mounted) return;
    await _guarded(context, () => controller.abandonOath(quest.id));
    if (context.mounted && controller.questById(quest.id)?.status == QuestStatus.open) {
      showGuildToast(context, 'Oath abandoned. −${MockQuestRepository.abandonCost} XP.');
    }
  }

  Future<void> _swear(BuildContext context) async {
    await _guarded(context, () => controller.swearOath(quest.id));
    if (context.mounted && controller.questById(quest.id)?.status == QuestStatus.sworn) {
      showGuildToast(context, 'Oath sworn. Tick each trial as you finish it.');
    }
  }

  Future<void> _claim(BuildContext context) async {
    final before = controller.data?.hero;
    final from = globalRectOf(context)?.center;
    await _guarded(context, () => controller.claimBounty(quest.id));
    final after = controller.data?.hero;
    if (!context.mounted || before == null || after == null) return;
    if (controller.questById(quest.id)?.status != QuestStatus.fulfilled) return;
    final gained = (after.level - before.level) * before.xpToNext + after.xp - before.xp;
    playClaimCeremony(
      context,
      before: before,
      after: after,
      xpGained: gained,
      titleEarned: quest.titleReward,
      from: from,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTrialsDone = quest.trialsDone == quest.trials.length;

    final Widget main;
    final Widget below;
    switch (quest.status) {
      case QuestStatus.open:
        main = GuildButton(label: 'Swear the oath', onPressed: () => _swear(context));
        below = _Footnote(
          'Swearing adds this quest to your sworn list. '
          'Abandoning it later costs ${MockQuestRepository.abandonCost} XP.',
        );
      case QuestStatus.sworn when allTrialsDone:
        main = GuildButton(
          label: 'Claim the bounty',
          kind: GuildButtonKind.reward,
          onPressed: () => _claim(context),
        );
        below = const _Footnote('Every trial is done. You can still untick one until you claim.');
      case QuestStatus.sworn:
        main = _TrialProgress(done: quest.trialsDone, total: quest.trials.length);
        below = _AbandonLink(onTap: () => _abandon(context));
      case QuestStatus.sealed:
        main = const GuildButton(label: 'Sealed', glyph: GuildGlyph.lock, onPressed: null);
        below = const _Footnote('You can swear this quest once its seal breaks.');
      case QuestStatus.fulfilled:
        main = const GuildButton(label: 'Bounty claimed', glyph: GuildGlyph.check, onPressed: null);
        below = _Footnote('You earned +${quest.xp} XP for this quest.');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (onOpenBuddy != null) ...[
                Semantics(
                  button: true,
                  label: 'Ask your Buddy about this quest',
                  excludeSemantics: true,
                  child: GuildPressable(
                    onTap: onOpenBuddy,
                    haptic: true,
                    child: const SketchBox(
                      color: GuildColors.indigoDeep,
                      borderColor: GuildColors.chalkLine,
                      shadow: null,
                      seed: 3,
                      child: SizedBox(
                        width: 60,
                        height: 56,
                        child: Center(child: GuildIcon(GuildGlyph.envelope, size: 30)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: main),
            ],
          ),
          const SizedBox(height: 4),
          below,
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Center(
        child: Text(text, textAlign: TextAlign.center, style: GuildText.aside(GuildType.sm)),
      ),
    );
  }
}

class _AbandonLink extends StatelessWidget {
  const _AbandonLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abandon this oath',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 160),
          child: Center(
            child: Text(
              'Abandon this oath',
              style: GuildText.body(GuildType.sm, color: GuildColors.dangerText).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: GuildColors.dangerText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrialProgress extends StatelessWidget {
  const _TrialProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final label = '$done of $total trials done';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: SketchBox(
          color: GuildColors.indigoDeep,
          borderColor: GuildColors.chalkLine,
          shadow: null,
          seed: 5,
          padding: const EdgeInsets.all(2.5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: total == 0 ? 0 : done / total),
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : GuildMotion.quick,
                  curve: Curves.easeOut,
                  builder: (context, v, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: const ColoredBox(color: GuildColors.indigoLight),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(label, textAlign: TextAlign.center, style: GuildText.label(GuildType.md)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
