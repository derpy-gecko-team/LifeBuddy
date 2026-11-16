import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/buddy_theme.dart';

/// The hero's writing line. Closed ([t] = 0) it is the rolled-up pill from
/// the design; as [t] goes to 1 its corners square off and a rod shows at the
/// top and the foot, so that it reads as a scroll that has been unrolled.
class WritingScrollPainter extends CustomPainter {
  WritingScrollPainter({required this.t, required this.s});

  /// 0 rolled up, 1 unrolled.
  final double t;

  /// The scale of the scene (see `HearthPage`).
  final double s;

  /// How tall a rod is, for whoever lays text out between them.
  static double rod(double s) => 16 * s;

  @override
  void paint(Canvas canvas, Size size) {
    final line = 3 * s;
    final outline = Paint()
      ..color = BuddyColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = line;
    final shadow = Offset(0, 4 * s);

    final sheet = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(lerpDouble(29 * s, 4 * s, t)!));
    canvas.drawRRect(sheet.shift(shadow), Paint()..color = BuddyColors.outline);
    canvas.drawRRect(sheet, Paint()..color = BuddyColors.card);
    canvas.drawRRect(sheet.deflate(line / 2), outline);

    // The rods come in over the first half of the unrolling.
    final shown = (t * 2).clamp(0.0, 1.0);
    if (shown == 0) return;
    final height = rod(s);
    final reach = 6 * s * t;
    canvas.saveLayer(
      (Offset.zero & size).inflate(reach + line + shadow.dy),
      Paint()..color = Color.fromRGBO(0, 0, 0, shown),
    );
    for (final top in [0.0, size.height - height]) {
      final rect = Rect.fromLTWH(-reach, top, size.width + reach * 2, height);
      final bar = RRect.fromRectAndRadius(rect, Radius.circular(height / 2));
      if (top > 0) canvas.drawRRect(bar.shift(shadow), Paint()..color = BuddyColors.outline);
      canvas.drawRRect(bar, Paint()..color = BuddyColors.cardShade);
      canvas.drawRRect(bar.deflate(line / 2), outline);
      // A glint along the roll, and the edge of the paper wound round each end.
      canvas.drawLine(
        Offset(rect.left + height * 1.4, top + height * 0.36),
        Offset(rect.right - height * 1.4, top + height * 0.36),
        Paint()
          ..color = BuddyColors.cardLight
          ..strokeWidth = 2 * s
          ..strokeCap = StrokeCap.round,
      );
      final wound = Paint()
        ..color = BuddyColors.outline
        ..strokeWidth = 1.6 * s
        ..strokeCap = StrokeCap.round;
      for (final x in [rect.left + height * 0.8, rect.right - height * 0.8]) {
        canvas.drawLine(Offset(x, top + line + 1.5 * s), Offset(x, top + height - line - 1.5 * s), wound);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WritingScrollPainter old) => old.t != t || old.s != s;
}
