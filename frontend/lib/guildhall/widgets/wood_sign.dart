import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/guild_theme.dart';

class WoodSign extends StatelessWidget {
  const WoodSign({
    super.key,
    required this.child,
    this.hanging = true,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
  });

  static const ropeHeight = 16.0;

  final Widget child;
  final bool hanging;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WoodSignPainter(hanging: hanging),
      child: Padding(
        padding: padding.add(EdgeInsets.only(top: hanging ? ropeHeight : 0)),
        child: child,
      ),
    );
  }
}

class _WoodSignPainter extends CustomPainter {
  _WoodSignPainter({required this.hanging});
  final bool hanging;

  @override
  void paint(Canvas canvas, Size size) {
    final top = hanging ? WoodSign.ropeHeight : 0.0;
    final rect = Rect.fromLTRB(0, top, size.width, size.height);
    final plank = RRect.fromRectAndRadius(rect, const Radius.circular(5));

    if (hanging) {
      final rope = Paint()
        ..color = const Color(0xFF9A8B6A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (final x in [size.width * 0.14, size.width * 0.86]) {
        canvas.drawLine(Offset(x, 3), Offset(x, top + 8), rope);
        canvas.drawCircle(Offset(x, 3), 3.5, Paint()..color = GuildColors.ink);
      }
    }

    canvas.drawRRect(plank.shift(const Offset(3, 5)), Paint()..color = GuildColors.shadow);
    canvas.drawRRect(plank, Paint()..color = GuildColors.wood);

    canvas.save();
    canvas.clipRRect(plank);
    final rnd = Random(5);
    final dark = Paint()
      ..color = GuildColors.woodDark.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final light = Paint()
      ..color = GuildColors.woodLight.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var y = rect.top + 7; y < rect.bottom; y += 9 + rnd.nextDouble() * 6) {
      final path = Path()..moveTo(rect.left, y);
      for (var x = rect.left + 30; x <= rect.right + 30; x += 30) {
        path.lineTo(x, y + (rnd.nextDouble() - 0.5) * 4);
      }
      canvas.drawPath(path, rnd.nextBool() ? dark : light);
    }
    canvas.restore();

    canvas.drawRRect(
      plank,
      Paint()
        ..color = GuildColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    if (hanging) {
      for (final x in [size.width * 0.14, size.width * 0.86]) {
        canvas.drawCircle(Offset(x, top + 8), 3, Paint()..color = GuildColors.ink);
      }
    }
  }

  @override
  bool shouldRepaint(_WoodSignPainter old) => old.hanging != hanging;
}
