import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import 'ornaments.dart';

class QuestlineBanner extends StatelessWidget {
  const QuestlineBanner({super.key, required this.questline});

  final Questline questline;

  static const _notch = 40.0;

  @override
  Widget build(BuildContext context) {
    final bounty = questline.bountyTitle == null
        ? 'Finish them all: +${questline.bountyXp} XP'
        : 'Finish them all: +${questline.bountyXp} XP and the title “${questline.bountyTitle}”';

    return Column(
      children: [
        const _Rod(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: CustomPaint(
            painter: _BannerPainter(notch: _notch),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, _notch + 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      DashedBorder(
                        circle: true,
                        color: GuildColors.cream.withValues(alpha: 0.85),
                        strokeWidth: 2,
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(questline.emblemAsset, width: 42, height: 42, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            questline.name,
                            style: GuildText.title(GuildType.xxl, color: GuildColors.cream),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(questline.quote, style: GuildText.aside(GuildType.md)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${questline.fulfilledCount} of ${questline.quests.length} quests fulfilled',
                          style: GuildText.label(GuildType.sm),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SealProgress(total: questline.quests.length, done: questline.fulfilledCount, size: 20),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DashedBorder(
                    color: GuildColors.cream.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        ExcludeSemantics(child: Image.asset(GuildAssets.coinPouch, height: 26)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(bounty, style: GuildText.body(GuildType.md, color: GuildColors.cream))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Rod extends StatelessWidget {
  const _Rod();

  @override
  Widget build(BuildContext context) {
    Widget knob() => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: GuildColors.gold,
            shape: BoxShape.circle,
            border: Border.all(color: GuildColors.ink, width: 3),
          ),
        );

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(child: CustomPaint(painter: _CordPainter())),
          Positioned(
            left: 8,
            right: 8,
            bottom: 5,
            child: Container(
              height: 12,
              decoration: BoxDecoration(color: GuildColors.ink, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Positioned(left: 0, bottom: 0, child: knob()),
          Positioned(right: 0, bottom: 0, child: knob()),
        ],
      ),
    );
  }
}

class _CordPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nail = Offset(size.width / 2, 7);
    final cord = Paint()
      ..color = const Color(0xFF9BAA90)
      ..strokeWidth = 3;
    canvas.drawLine(nail, Offset(size.width * 0.24, size.height - 12), cord);
    canvas.drawLine(nail, Offset(size.width * 0.76, size.height - 12), cord);
    canvas.drawCircle(nail, 7, Paint()..color = GuildColors.ink);
    canvas.drawCircle(nail, 4, Paint()..color = GuildColors.stoneLight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BannerPainter extends CustomPainter {
  _BannerPainter({required this.notch});

  final double notch;

  Path _shape(Rect r, double notch) => Path()
    ..moveTo(r.left, r.top)
    ..lineTo(r.right, r.top)
    ..lineTo(r.right, r.bottom)
    ..lineTo(r.center.dx, r.bottom - notch)
    ..lineTo(r.left, r.bottom)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = _shape(rect, notch);

    canvas.drawPath(shape.shift(const Offset(5, 7)), Paint()..color = GuildColors.shadow);
    canvas.drawPath(shape, Paint()..color = GuildColors.crimsonDeep);
    canvas.drawPath(
      shape,
      Paint()
        ..color = GuildColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    drawDashedPath(
      canvas,
      _shape(rect.deflate(11), notch - 4),
      Paint()
        ..color = GuildColors.cream.withValues(alpha: 0.7)
        ..strokeWidth = 2,
      dash: 7,
      gap: 6,
    );
  }

  @override
  bool shouldRepaint(_BannerPainter old) => old.notch != notch;
}
