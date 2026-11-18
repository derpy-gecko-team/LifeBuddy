import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import 'ornaments.dart';
import 'sketch.dart';

class JourneyBanner extends StatelessWidget {
  const JourneyBanner({super.key, required this.journey});

  final Journey journey;

  static const _notch = 40.0;

  @override
  Widget build(BuildContext context) {
    final bounty = journey.bountyTitle == null
        ? 'Finish them all: +${journey.bountyXp} XP'
        : 'Finish them all: +${journey.bountyXp} XP and the title “${journey.bountyTitle}”';

    return Column(
      children: [
        const _Rod(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: CustomPaint(
            painter: _BannerPainter(notch: _notch, seed: stableSeed(journey.id)),
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
                        child: JourneyEmblem(journey: journey, size: 42),
                      ),
                      const SizedBox(width: GuildSpace.md),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            header: true,
                            child: LetteredTitle(journey.name, size: GuildTitle.xl),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GuildSpace.md),
                  Text(journey.quote, style: GuildText.aside(GuildType.md)),
                  const SizedBox(height: GuildSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${journey.fulfilledCount} of ${journey.quests.length} quests fulfilled',
                          style: GuildText.label(GuildType.sm),
                        ),
                      ),
                      const SizedBox(width: GuildSpace.sm),
                      SealProgress(total: journey.quests.length, done: journey.fulfilledCount, size: 20),
                    ],
                  ),
                  const SizedBox(height: GuildSpace.lg),
                  DashedBorder(
                    color: GuildColors.cream.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        ExcludeSemantics(child: Image.asset(GuildAssets.coinPouch, height: 26)),
                        const SizedBox(width: GuildSpace.sm),
                        Expanded(child: Text(bounty, style: GuildText.aside(GuildType.md))),
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
            border: Border.all(color: GuildColors.bronze, width: 1.5),
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
              decoration: BoxDecoration(color: GuildColors.shadow, borderRadius: BorderRadius.circular(3)),
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
      ..color = GuildColors.chalk
      ..strokeWidth = 2;
    canvas.drawLine(nail, Offset(size.width * 0.24, size.height - 12), cord);
    canvas.drawLine(nail, Offset(size.width * 0.76, size.height - 12), cord);
    canvas.drawCircle(nail, 6, Paint()..color = GuildColors.chalk);
    canvas.drawCircle(nail, 3, Paint()..color = GuildColors.indigoDeep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

typedef _Cloth = ({Path folds, Path sheen, Path rodShade, Path stitch});

class _BannerPainter extends CustomPainter {
  _BannerPainter({required this.notch, required this.seed});

  final double notch;
  final int seed;

  static final _cloths = <(int, Size, double), _Cloth>{};

  static List<Offset> _outline(Rect r, double notch) => [
        r.topLeft,
        r.topRight,
        r.bottomRight,
        Offset(r.center.dx, r.bottom - notch),
        r.bottomLeft,
      ];

  _Cloth _cloth(Size size) {
    final key = (seed, size, notch);
    final cached = _cloths[key];
    if (cached != null) return cached;
    if (_cloths.length > 16) _cloths.remove(_cloths.keys.first);

    final pen = Random(seed * 71 + 5);
    final folds = Path();
    final sheen = Path();
    final count = max(2, (size.width / 120).round());
    for (var i = 0; i < count; i++) {
      final x = size.width * (i + 0.65 + (pen.nextDouble() - 0.5) * 0.4) / (count + 0.3);
      final bottom = size.height * (0.5 + pen.nextDouble() * 0.35);
      var y = 4 + pen.nextDouble() * 8;
      var drift = 0.0;
      folds.moveTo(x, y);
      sheen.moveTo(x + 4, y);
      while (y < bottom) {
        y += 24 + pen.nextDouble() * 14;
        final next = (pen.nextDouble() - 0.5) * 7;
        folds.quadraticBezierTo(x + drift, y - 14, x + next / 2, y);
        sheen.quadraticBezierTo(x + 4 + drift, y - 14, x + 4 + next / 2, y);
        drift = next;
      }
    }

    final rodShade = Path();
    for (var x = 5.0; x < size.width - 4; x += 4 + pen.nextDouble() * 3) {
      final length = 4 + pen.nextDouble() * (pen.nextDouble() < 0.2 ? 16 : 8);
      rodShade
        ..moveTo(x, 2)
        ..lineTo(x + (pen.nextDouble() - 0.5) * 2, 2 + length);
    }

    final inner = Path()..addPolygon(_outline((Offset.zero & size).deflate(11), notch - 4), true);
    return _cloths[key] = (
      folds: folds,
      sheen: sheen,
      rodShade: rodShade,
      stitch: traceByHand(inner, pen, wobble: 0.8, step: 16),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sketch = Sketch.of(_outline(Offset.zero & size, notch), seed);
    final cloth = _cloth(size);

    sketch.paintFill(canvas, GuildColors.brickDeep, shadow: GuildShadow.paper);

    canvas.save();
    canvas.clipPath(sketch.shape);
    canvas.drawPath(cloth.folds, Sketch.pen(GuildColors.brickShade.withValues(alpha: 0.55), 2.6));
    canvas.drawPath(cloth.sheen, Sketch.pen(GuildColors.cream.withValues(alpha: 0.12), 1.8));
    canvas.drawPath(cloth.rodShade, Sketch.pen(GuildColors.brickShade.withValues(alpha: 0.7), 1.3));
    canvas.restore();

    sketch.paintShading(canvas, ink: GuildColors.brickShade, strength: 2.2);
    sketch.paintBorder(canvas, color: GuildColors.brickShade, width: 1.8);

    drawDashedPath(
      canvas,
      cloth.stitch,
      Paint()
        ..color = GuildColors.cream.withValues(alpha: 0.7)
        ..strokeWidth = 2,
      dash: 7,
      gap: 6,
    );
  }

  @override
  bool shouldRepaint(_BannerPainter old) => old.notch != notch || old.seed != seed;
}
