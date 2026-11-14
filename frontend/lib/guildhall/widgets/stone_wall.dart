import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/guild_theme.dart';

enum WallVariant {
  board(7),
  questline(23),
  quest(41);

  const WallVariant(this.seed);
  final int seed;
}

class StoneWall extends StatelessWidget {
  const StoneWall({super.key, this.variant = WallVariant.board});

  final WallVariant variant;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
        return RawImage(
          image: _WallCache.imageFor(size, dpr, variant),
          width: size.width,
          height: size.height,
          fit: BoxFit.fill,
        );
      },
    );
  }
}

abstract final class _WallCache {
  static final _images = <String, ui.Image>{};

  static ui.Image imageFor(Size size, double dpr, WallVariant variant) {
    final key = '${size.width.round()}x${size.height.round()}@$dpr#${variant.name}';
    final cached = _images[key];
    if (cached != null) return cached;

    if (_images.length >= 8) _images.remove(_images.keys.first)?.dispose();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    _paintBricks(canvas, size, variant.seed);
    _paintDressing(canvas, size, variant);
    _paintVignette(canvas, size);
    final picture = recorder.endRecording();
    final image = picture.toImageSync((size.width * dpr).ceil(), (size.height * dpr).ceil());
    picture.dispose();
    return _images[key] = image;
  }
}

const _tones = [
  GuildColors.stoneDark,
  GuildColors.stone,
  GuildColors.stone,
  GuildColors.stoneLight,
];

void _paintBricks(Canvas canvas, Size size, int seed) {
  final rnd = Random(seed);
  final pen = Random(seed * 97 + 3);
  final sketch = Paint()
    ..color = GuildColors.shadow.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawRect(Offset.zero & size, Paint()..color = GuildColors.mortar);

  final fill = Paint();
  final edge = Paint()
    ..color = GuildColors.shadow.withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final highlight = Paint()
    ..color = Colors.white.withValues(alpha: 0.035)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final crack = Paint()
    ..color = GuildColors.shadow.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;

  const gap = 7.0;
  var y = -20.0;
  while (y < size.height) {
    final rowH = 70.0 + rnd.nextDouble() * 34;
    var x = -rnd.nextDouble() * 120;
    while (x < size.width) {
      final w = 90.0 + rnd.nextDouble() * 90;
      final rect = Rect.fromLTWH(x + gap / 2, y + gap / 2, w - gap, rowH - gap);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(5));
      fill.color = _tones[rnd.nextInt(_tones.length)];
      canvas.drawRRect(rr, fill);
      canvas.drawLine(rect.topLeft + const Offset(6, 2), rect.topRight + const Offset(-6, 2), highlight);
      canvas.drawRRect(rr, edge);
      _sketchBrick(canvas, rect, pen, sketch);

      if (rnd.nextInt(7) == 0) {
        final start = Offset(rect.left + rnd.nextDouble() * rect.width, rect.top + 3);
        final path = Path()..moveTo(start.dx, start.dy);
        var p = start;
        for (var i = 0; i < 3; i++) {
          p += Offset((rnd.nextDouble() - 0.5) * 18, rect.height * (0.2 + rnd.nextDouble() * 0.15));
          path.lineTo(p.dx, min(p.dy, rect.bottom - 3));
        }
        canvas.drawPath(path, crack);
      }
      x += w;
    }
    y += rowH;
  }
}

void _sketchBrick(Canvas canvas, Rect rect, Random pen, Paint paint) {
  double wobble() => (pen.nextDouble() - 0.5) * 3;
  final inner = rect.deflate(4);
  final corners = [inner.topLeft, inner.topRight, inner.bottomRight, inner.bottomLeft];
  final path = Path();
  for (var i = 0; i < 4; i++) {
    if (pen.nextDouble() < 0.2) continue;
    final from = corners[i];
    final to = corners[(i + 1) % 4];
    final mid = Offset.lerp(from, to, 0.35 + pen.nextDouble() * 0.3)!;
    path
      ..moveTo(from.dx + wobble(), from.dy + wobble())
      ..lineTo(mid.dx + wobble(), mid.dy + wobble())
      ..lineTo(to.dx + wobble(), to.dy + wobble());
  }

  final reach = rect.width * (0.2 + pen.nextDouble() * 0.3);
  for (var x = rect.right - 7; x > rect.right - 7 - reach; x -= 5 + pen.nextDouble() * 2) {
    final near = 1 - (rect.right - 7 - x) / reach;
    final length = 5 + near * rect.height * 0.3 + pen.nextDouble() * 4;
    path
      ..moveTo(x, rect.bottom - 5)
      ..lineTo(x - length * 0.45, rect.bottom - 5 - length);
  }
  canvas.drawPath(path, paint);
}

typedef _Scrap = ({double x, double y, double w, double h, double tilt, Color color});

const _oldPaper = Color(0xFF6F6A50);
const _oldPaperGreen = Color(0xFF5C6656);
const _oldPaperGrey = Color(0xFF666B66);

const _scraps = <WallVariant, List<_Scrap>>{
  WallVariant.board: [
    (x: 0.06, y: 0.34, w: 92, h: 70, tilt: -0.10, color: _oldPaper),
    (x: 0.90, y: 0.47, w: 84, h: 104, tilt: 0.08, color: _oldPaperGreen),
    (x: 0.12, y: 0.80, w: 110, h: 64, tilt: 0.05, color: _oldPaperGrey),
    (x: 0.80, y: 0.92, w: 96, h: 80, tilt: -0.07, color: _oldPaper),
  ],
  WallVariant.questline: [
    (x: 0.10, y: 0.14, w: 80, h: 96, tilt: 0.09, color: _oldPaperGreen),
    (x: 0.93, y: 0.62, w: 90, h: 70, tilt: -0.12, color: _oldPaper),
    (x: 0.20, y: 0.93, w: 120, h: 70, tilt: -0.04, color: _oldPaperGrey),
  ],
  WallVariant.quest: [
    (x: 0.04, y: 0.22, w: 70, h: 110, tilt: -0.06, color: _oldPaper),
    (x: 0.97, y: 0.36, w: 76, h: 90, tilt: 0.10, color: _oldPaperGrey),
    (x: 0.88, y: 0.86, w: 110, h: 76, tilt: 0.06, color: _oldPaperGreen),
    (x: 0.08, y: 0.74, w: 86, h: 64, tilt: 0.12, color: _oldPaper),
  ],
};

void _paintDressing(Canvas canvas, Size size, WallVariant variant) {
  final rnd = Random(variant.seed * 13);
  final ink = Paint()
    ..color = GuildColors.shadow.withValues(alpha: 0.7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round;
  final scribble = Paint()
    ..color = GuildColors.shadow.withValues(alpha: 0.28)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  for (final s in _scraps[variant]!) {
    canvas.save();
    canvas.translate(size.width * s.x, size.height * s.y);
    canvas.rotate(s.tilt);
    canvas.translate(-s.w / 2, -s.h / 2);

    final path = Path()..moveTo(rnd.nextDouble() * 4, rnd.nextDouble() * 4);
    for (var x = 10.0; x < s.w; x += 8 + rnd.nextDouble() * 10) {
      path.lineTo(x, rnd.nextDouble() * 4);
    }
    path.lineTo(s.w, 2);
    for (var y = 10.0; y < s.h; y += 10 + rnd.nextDouble() * 12) {
      path.lineTo(s.w - rnd.nextDouble() * 4, y);
    }
    for (var x = s.w; x > 0; x -= 7 + rnd.nextDouble() * 10) {
      path.lineTo(x, s.h - rnd.nextDouble() * 12);
    }
    for (var y = s.h - 8; y > 0; y -= 10 + rnd.nextDouble() * 12) {
      path.lineTo(rnd.nextDouble() * 4, y);
    }
    path.close();

    canvas.drawPath(path.shift(const Offset(3, 4)), Paint()..color = GuildColors.shadow.withValues(alpha: 0.5));
    canvas.drawPath(path, Paint()..color = s.color.withValues(alpha: 0.82));
    canvas.drawPath(path, ink);

    for (var ly = s.h * 0.34; ly < s.h - 16; ly += 13) {
      final from = 10 + rnd.nextDouble() * 6;
      final to = s.w - 12 - rnd.nextDouble() * s.w * 0.35;
      final line = Path()..moveTo(from, ly);
      for (var x = from + 8; x < to; x += 8) {
        line.lineTo(x, ly + (rnd.nextDouble() - 0.5) * 3);
      }
      canvas.drawPath(line, scribble);
    }

    final nail = Offset(s.w / 2, 9);
    canvas.drawCircle(nail + const Offset(1, 2), 5, Paint()..color = GuildColors.shadow.withValues(alpha: 0.6));
    canvas.drawCircle(nail, 4.5, Paint()..color = GuildColors.ink);
    canvas.drawCircle(nail - const Offset(1.4, 1.4), 1.3, Paint()..color = Colors.white.withValues(alpha: 0.35));
    canvas.restore();
  }

  final ring = switch (variant) {
    WallVariant.board => Offset(size.width * 0.93, size.height * 0.70),
    WallVariant.questline => Offset(size.width * 0.07, size.height * 0.48),
    WallVariant.quest => Offset(size.width * 0.06, size.height * 0.52),
  };
  final iron = Paint()..color = const Color(0xFF23272A);
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: ring, width: 20, height: 26), const Radius.circular(4)),
    iron,
  );
  canvas.drawCircle(ring - const Offset(0, 6), 2, Paint()..color = Colors.white.withValues(alpha: 0.25));
  canvas.drawCircle(
    ring + const Offset(0, 22),
    15,
    Paint()
      ..color = const Color(0xFF23272A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5,
  );
  canvas.drawArc(
    Rect.fromCircle(center: ring + const Offset(0, 22), radius: 15),
    pi * 1.1,
    pi * 0.5,
    false,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}

void _paintVignette(Canvas canvas, Size size) {
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = RadialGradient(
        radius: 1.1,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
      ).createShader(Offset.zero & size),
  );
}
