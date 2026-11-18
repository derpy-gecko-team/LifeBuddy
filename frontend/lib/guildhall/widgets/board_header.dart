import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
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
                  const SizedBox(width: GuildSpace.sm),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        child: LetteredTitle(
                          'The Guildhall',
                          size: GuildTitle.display,
                          drawIn: drawTitle,
                          onDrawn: onTitleDrawn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GuildSpace.sm),
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
                const SizedBox(width: GuildSpace.md),
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
                            style: GuildText.title(GuildTitle.lg),
                          ),
                          Text(
                            '${hero.xp} / ${hero.xpToNext} XP',
                            style: GuildText.label(GuildType.xs, color: GuildColors.inkSoft),
                          ),
                        ],
                      ),
                      const SizedBox(height: GuildSpace.sm),
                      ExcludeSemantics(
                        child: GuildProgressBar.onPaper(value: hero.progress),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onOpenBuddy != null) ...[
          const SizedBox(width: GuildSpace.md),
          GuildPressable(
            semanticLabel: 'Talk to your Buddy',
            onTap: onOpenBuddy,
            haptic: true,
            pressedScale: 0.92,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.translationValues(0, 6, 0)..rotateZ(0.035),
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  BuddyPortrait(width: 52),
                  Positioned(
                    right: -6,
                    bottom: -2,
                    child: RoundBadge(asset: GuildAssets.buddyEnvelope, size: 28),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class JourneyPlaque extends StatelessWidget {
  const JourneyPlaque({super.key, required this.journey, required this.onTap});

  final Journey journey;
  final ValueChanged<Rect?> onTap;

  @override
  Widget build(BuildContext context) {
    return GuildPressable(
      semanticLabel: '${journey.name}, ${journey.fulfilledCount} of '
          '${journey.quests.length} quests fulfilled. Open journey.',
      onTap: () => onTap(globalRectOf(context)),
      pressedScale: 0.98,
      child: SketchBox(
        color: GuildColors.indigoDeep,
        borderColor: GuildColors.chalkLine,
        borderWidth: 1.6,
        bevel: 10,
        shadow: GuildShadow.raised,
        seed: stableSeed(journey.id),
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
                  child: JourneyEmblem(journey: journey, size: 35),
                ),
                const SizedBox(width: GuildSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(journey.name, style: GuildText.title(GuildTitle.lg, color: GuildColors.cream)),
                      const SizedBox(height: GuildSpace.hair),
                      Text(
                        '${journey.fulfilledCount} of ${journey.quests.length} quests fulfilled',
                        style: GuildText.aside(GuildType.sm),
                      ),
                      const SizedBox(height: GuildSpace.sm),
                      SealProgress(total: journey.quests.length, done: journey.fulfilledCount),
                    ],
                  ),
                ),
                const SizedBox(width: GuildSpace.sm),
                const GuildIcon(GuildGlyph.chevronRight, size: 22, color: GuildColors.goldBright),
              ],
            ),
          ],
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
              const SizedBox(width: GuildSpace.sm),
              Semantics(
                header: true,
                child: Text('Due soon', style: GuildText.title(GuildTitle.lg)),
              ),
            ],
          ),
          const SizedBox(height: GuildSpace.xs),
          for (final (i, quest) in quests.indexed) ...[
            if (i > 0) const DashedLine(),
            Builder(
              builder: (rowContext) => GuildPressable(
                semanticLabel: '${quest.title}, ${deadlineLabel(quest.deadline!, now)}, ${quest.xp} XP',
                onTap: () => onOpenQuest(quest.id, rowContext),
                pressedScale: 0.98,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          quest.title,
                          style: GuildText.title(GuildTitle.md),
                        ),
                      ),
                      const SizedBox(width: GuildSpace.sm),
                      Text(
                        deadlineLabel(quest.deadline!, now),
                        style: GuildText.body(GuildType.sm),
                      ),
                      const SizedBox(width: GuildSpace.sm),
                      const GuildIcon(GuildGlyph.chevronRight, size: 18, color: GuildColors.ink),
                    ],
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
