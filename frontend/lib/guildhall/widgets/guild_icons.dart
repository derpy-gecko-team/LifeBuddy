import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../theme/guild_theme.dart';

enum GuildGlyph {
  chevronLeft,
  chevronRight,
  lock,
  check,
  envelope,
  flame,
  cross,
}

class GuildIcon extends StatelessWidget {
  const GuildIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color = GuildColors.cream,
  });

  final GuildGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _GlyphPainter(glyph, color)),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final GuildGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, s * 0.11)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    Offset p(double x, double y) => Offset(x * s, y * s);

    switch (glyph) {
      case GuildGlyph.chevronLeft:
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.62, s * 0.18)
            ..lineTo(s * 0.32, s * 0.5)
            ..lineTo(s * 0.62, s * 0.82),
          stroke,
        );
      case GuildGlyph.chevronRight:
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.38, s * 0.18)
            ..lineTo(s * 0.68, s * 0.5)
            ..lineTo(s * 0.38, s * 0.82),
          stroke,
        );
      case GuildGlyph.check:
        canvas.drawPath(checkPath(size), stroke);
      case GuildGlyph.cross:
        canvas.drawLine(p(0.24, 0.24), p(0.76, 0.76), stroke);
        canvas.drawLine(p(0.76, 0.24), p(0.24, 0.76), stroke);
      case GuildGlyph.lock:
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.32, s * 0.46)
            ..lineTo(s * 0.32, s * 0.34)
            ..arcToPoint(p(0.68, 0.34), radius: Radius.circular(s * 0.18))
            ..lineTo(s * 0.68, s * 0.46),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(s * 0.22, s * 0.46, s * 0.78, s * 0.86),
            Radius.circular(s * 0.08),
          ),
          fill,
        );
      case GuildGlyph.envelope:
        final body = RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.12, s * 0.24, s * 0.88, s * 0.78),
          Radius.circular(s * 0.06),
        );
        canvas.drawRRect(body, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.14, s * 0.28)
            ..lineTo(s * 0.5, s * 0.56)
            ..lineTo(s * 0.86, s * 0.28),
          stroke,
        );
        canvas.drawCircle(p(0.5, 0.6), s * 0.09, fill);
      case GuildGlyph.flame:
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.5, s * 0.1)
            ..cubicTo(s * 0.86, s * 0.42, s * 0.84, s * 0.9, s * 0.5, s * 0.9)
            ..cubicTo(s * 0.16, s * 0.9, s * 0.14, s * 0.56, s * 0.34, s * 0.4)
            ..cubicTo(
              s * 0.38,
              s * 0.52,
              s * 0.46,
              s * 0.52,
              s * 0.46,
              s * 0.44,
            )
            ..cubicTo(s * 0.46, s * 0.3, s * 0.42, s * 0.22, s * 0.5, s * 0.1)
            ..close(),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}

Path checkPath(Size size) {
  final s = size.width;
  return Path()
    ..moveTo(s * 0.18, s * 0.54)
    ..lineTo(s * 0.42, s * 0.78)
    ..lineTo(s * 0.84, s * 0.2);
}
