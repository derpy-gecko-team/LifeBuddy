import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/buddy_theme.dart';

/// The sky above the campfire, where old chatter drifts.
///
/// It is painted from nothing but how high the view has climbed, so it never
/// runs out: first the night over the treetops, then the moon, a bank of
/// clouds, the northern lights, the constellations, and past those open space
/// with a new sight every so often for as long as the conversation goes on.
///
/// The sky is far away: it passes at [parallax] of the speed the messages do.
class SkyPainter extends CustomPainter {
  SkyPainter({required this.climb, required this.time, required this.s})
    : super(repaint: Listenable.merge([climb, time]));

  /// How far the view has been pulled up from the fire, in logical pixels.
  final ValueListenable<double> climb;

  /// Seconds, for everything that twinkles and drifts.
  final ValueListenable<double> time;

  /// The scale of the scene (see `HearthPage`).
  final double s;

  static const parallax = 0.45;

  // Heights are in sky pixels: climb x parallax, at scale 1.
  static const _moonAt = 520.0;
  static const _cloudsFrom = 900.0;
  static const _cloudsTo = 1500.0;
  static const _auroraFrom = 1900.0;
  static const _auroraTo = 2900.0;
  static const _constellationsFrom = 3300.0;
  static const _constellationGap = 520.0;
  static const _spaceFrom = 5000.0;
  static const _sightGap = 900.0;

  static const _shades = <(double, Color)>[
    (0, Color(0xFF0A0F24)),
    (500, Color(0xFF10163C)),
    (1300, Color(0xFF1A1A52)),
    (2400, Color(0xFF261C5A)),
    (3400, Color(0xFF141238)),
    (5000, Color(0xFF07071A)),
  ];

  // Out in space the colour keeps wandering, slowly, between these.
  static const _deep = [Color(0xFF07071A), Color(0xFF120B2C), Color(0xFF06101F), Color(0xFF160A22)];

  static Color shadeAt(double h) {
    if (h <= 0) return _shades.first.$2;
    for (var i = 1; i < _shades.length; i++) {
      if (h < _shades[i].$1) {
        final (h0, c0) = _shades[i - 1];
        final (h1, c1) = _shades[i];
        return Color.lerp(c0, c1, (h - h0) / (h1 - h0))!;
      }
    }
    final along = (h - _spaceFrom) / 2600;
    final i = along.floor();
    return Color.lerp(_deep[i % _deep.length], _deep[(i + 1) % _deep.length], along - i)!;
  }

  /// A steady pseudo-random number in 0..1 for a place in the sky.
  static double _noise(int a, int b, [int c = 0]) {
    var h = a * 374761393 + b * 668265263 + c * 2147483647;
    h = (h ^ (h >> 13)) * 1274126177;
    h = h ^ (h >> 16);
    return (h & 0xffffff) / 0xffffff;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    // The height of the bottom edge of the view, and a way from a height to
    // a y on the canvas.
    final base = climb.value * parallax / s;
    final span = size.height / s;
    double y(double h) => size.height - (h - base) * s;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [for (var i = 0; i <= 4; i++) shadeAt(base + span * i / 4)],
        ).createShader(Offset.zero & size),
    );

    bool inView(double from, double to) => to > base - 200 && from < base + span + 200;

    if (inView(_auroraFrom, _auroraTo)) _aurora(canvas, size, y, t);
    _stars(canvas, size, base, span, y, t);
    if (inView(_moonAt - 120, _moonAt + 120)) _moon(canvas, Offset(size.width * 0.74, y(_moonAt)));
    if (inView(_cloudsFrom - 100, _cloudsTo + 100)) _clouds(canvas, size, y, t);

    for (var i = 0; i < _constellations.length; i++) {
      final h = _constellationsFrom + i * _constellationGap;
      if (inView(h - 200, h + 200)) {
        _constellation(canvas, _constellations[i], Offset(size.width * (i.isEven ? 0.36 : 0.62), y(h)), t);
      }
    }

    final first = max(0, ((base - 300 - _spaceFrom) / _sightGap).floor());
    final last = ((base + span + 300 - _spaceFrom) / _sightGap).ceil();
    for (var i = first; i <= last; i++) {
      _sight(canvas, size, i, y(_spaceFrom + i * _sightGap), t);
    }
  }

  void _stars(Canvas canvas, Size size, double base, double span, double Function(double) y, double t) {
    const cell = 58.0;
    final paint = Paint();
    final columns = (size.width / s / cell).ceil();
    for (var row = (base / cell).floor(); row <= ((base + span) / cell).ceil(); row++) {
      // Few stars through the haze over the trees, plenty higher up.
      final height = row * cell;
      final chance = 0.22 + 0.5 * (height / 2600).clamp(0.0, 1.0);
      for (var column = 0; column < columns; column++) {
        if (_noise(row, column) > chance) continue;
        final at = Offset((column + _noise(row, column, 1)) * cell * s, y(height + _noise(row, column, 2) * cell));
        final kind = _noise(row, column, 3);
        final twinkle = 0.55 + 0.45 * sin(t * (0.6 + kind * 1.6) + kind * 40);
        paint.color = BuddyColors.cream.withValues(alpha: twinkle * (0.35 + 0.65 * kind));
        if (kind > 0.93) {
          _sparkle(canvas, at, (4 + 4 * _noise(row, column, 4)) * s, paint);
        } else {
          canvas.drawCircle(at, (0.6 + 1.3 * kind) * s, paint);
        }
      }
    }
  }

  /// A four-pointed star, as in the designs.
  void _sparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final w = r * 0.22;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
        ..close(),
      paint,
    );
  }

  void _moon(Canvas canvas, Offset c) {
    final r = 34 * s;
    canvas.drawCircle(c, r * 2.1, Paint()..color = const Color(0x14F4E3C3));
    canvas.drawCircle(c, r * 1.5, Paint()..color = const Color(0x1AF4E3C3));
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c + Offset(-r * 0.42, -r * 0.2), radius: r * 0.92)),
    );
    canvas.drawPath(crescent, Paint()..color = const Color(0xFFF2D58A));
    canvas.drawPath(
      crescent,
      Paint()
        ..color = BuddyColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _clouds(Canvas canvas, Size size, double Function(double) y, double t) {
    for (var i = 0; i < 6; i++) {
      final h = _cloudsFrom + (_cloudsTo - _cloudsFrom) * i / 5;
      final width = (130 + 90 * _noise(i, 7)) * s;
      // Each drifts across at its own pace and comes round again.
      final lap = size.width + width * 2;
      final x = (_noise(i, 8) * lap + t * (3 + 5 * _noise(i, 9)) * s) % lap - width;
      _cloud(canvas, Offset(x, y(h)), width, i);
    }
  }

  void _cloud(Canvas canvas, Offset at, double width, int seed) {
    final height = width * 0.3;
    final shape = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, width, height), Radius.circular(height / 2)));
    for (var i = 0; i < 3; i++) {
      final r = height * (0.5 + 0.35 * _noise(seed, i, 11));
      shape.addOval(
        Rect.fromCircle(center: Offset(at.dx + width * (0.26 + 0.24 * i), at.dy + height * 0.2), radius: r),
      );
    }
    canvas.drawPath(shape, Paint()..color = const Color(0xFF2B2F63));
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawRect(
      Rect.fromLTWH(at.dx, at.dy + height * 0.55, width, height),
      Paint()..color = const Color(0xFF22265A),
    );
    canvas.restore();
  }

  void _aurora(Canvas canvas, Size size, double Function(double) y, double t) {
    const colours = [Color(0xFF4FE0B0), Color(0xFF58C7E8), Color(0xFF9C7BEA)];
    const steps = 36;
    for (var i = 0; i < 3; i++) {
      // A curtain: a slow wave along its top edge, light falling away below
      // it to nothing well before the hem, so that no lower edge shows.
      final top = y(_auroraTo - 120 - i * 230);
      final drop = (280 + 70 * i) * s;
      double edge(int k) {
        final u = k / steps;
        return top + sin(u * 5.2 + t * 0.22 + i * 1.7) * 34 * s + sin(u * 2.1 - t * 0.13 + i) * 48 * s;
      }

      final path = Path()..moveTo(0, edge(0));
      for (var k = 1; k <= steps; k++) {
        path.lineTo(size.width * k / steps, edge(k));
      }
      path
        ..lineTo(size.width, top + drop + 90 * s)
        ..lineTo(0, top + drop + 90 * s)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colours[i].withValues(alpha: 0.3), colours[i].withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, top - 82 * s, size.width, drop)),
      );
    }
  }

  // Points on a 100 x 100 card, and which of them are joined.
  static const _constellations = <(List<Offset>, List<(int, int)>)>[
    // The Cat: two ears, a face, whiskers.
    (
      [
        Offset(20, 20), Offset(32, 44), Offset(50, 38), Offset(68, 44), Offset(80, 20), //
        Offset(84, 66), Offset(50, 88), Offset(16, 66), Offset(2, 60), Offset(98, 60),
      ],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0), (7, 8), (5, 9)],
    ),
    // The Sword.
    (
      [Offset(50, 0), Offset(50, 62), Offset(28, 62), Offset(72, 62), Offset(50, 80), Offset(50, 98)],
      [(0, 1), (2, 3), (1, 4), (4, 5)],
    ),
    // The Kettle over the fire.
    (
      [Offset(22, 40), Offset(78, 40), Offset(86, 72), Offset(50, 90), Offset(14, 72), Offset(34, 14), Offset(66, 14)],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (0, 5), (5, 6), (6, 1)],
    ),
  ];

  void _constellation(Canvas canvas, (List<Offset>, List<(int, int)>) shape, Offset centre, double t) {
    final (points, joins) = shape;
    final scale = 1.5 * s;
    Offset place(Offset p) => centre + (p - const Offset(50, 50)) * scale;
    final line = Paint()
      ..color = BuddyColors.cream.withValues(alpha: 0.3)
      ..strokeWidth = 1.2 * s
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in joins) {
      canvas.drawLine(place(points[a]), place(points[b]), line);
    }
    final star = Paint();
    for (var i = 0; i < points.length; i++) {
      star.color = BuddyColors.cream.withValues(alpha: 0.75 + 0.25 * sin(t * 1.3 + i * 2.1));
      canvas.drawCircle(place(points[i]), 2.6 * s, star);
    }
  }

  /// Something to come across in open space. Which one, where and what colour
  /// all follow from its number, so it is the same every time it is passed.
  void _sight(Canvas canvas, Size size, int i, double y, double t) {
    final x = size.width * (0.2 + 0.6 * _noise(i, 21));
    const palette = [Color(0xFFC4514B), Color(0xFFE2B85A), Color(0xFF5E7FC2), Color(0xFF6FA487), Color(0xFF9C7BEA)];
    final colour = palette[(_noise(i, 22) * palette.length).floor() % palette.length];
    final outline = Paint()
      ..color = BuddyColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s;

    switch (i % 4) {
      case 0: // a planet, some with a ring
        final r = (26 + 22 * _noise(i, 23)) * s;
        final c = Offset(x, y);
        final disc = Path()..addOval(Rect.fromCircle(center: c, radius: r));
        canvas.drawPath(disc, Paint()..color = colour);
        canvas.save();
        canvas.clipPath(disc);
        final band = Paint()..color = Color.lerp(colour, BuddyColors.outline, 0.3)!;
        canvas.drawRect(Rect.fromLTWH(c.dx - r, c.dy - r * 0.25, r * 2, r * 0.3), band);
        canvas.drawRect(Rect.fromLTWH(c.dx - r, c.dy + r * 0.4, r * 2, r * 0.18), band);
        canvas.drawCircle(c + Offset(r * 0.5, r * 0.5), r * 1.1, Paint()..color = const Color(0x3015142A));
        canvas.restore();
        canvas.drawPath(disc, outline);
        if (_noise(i, 24) > 0.45) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(-0.35);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: r * 3.4, height: r * 0.9),
            Paint()
              ..color = BuddyColors.cream.withValues(alpha: 0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * s,
          );
          canvas.restore();
        }
      case 1: // a comet crossing, over and over
        final lap = size.width + 400 * s;
        final along = (t * 26 * s + _noise(i, 25) * lap) % lap - 200 * s;
        final head = Offset(along, y + (along - size.width / 2) * 0.22);
        final tail = head - Offset(120 * s, 26 * s);
        canvas.drawLine(
          tail,
          head,
          Paint()
            ..shader = LinearGradient(
              colors: [BuddyColors.cream.withValues(alpha: 0), BuddyColors.cream.withValues(alpha: 0.8)],
            ).createShader(Rect.fromPoints(tail, head))
            ..strokeWidth = 4 * s
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(head, 4.5 * s, Paint()..color = BuddyColors.cream);
      case 2: // a far galaxy, turning
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(t * 0.03 + i);
        final arm = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 4; k++) {
          arm
            ..color = colour.withValues(alpha: 0.5 - k * 0.1)
            ..strokeWidth = (3 - k * 0.5) * s;
          canvas.drawArc(
            Rect.fromCenter(center: Offset.zero, width: (40 + k * 34) * s, height: (18 + k * 16) * s),
            k * 1.1,
            3.6,
            false,
            arm,
          );
        }
        canvas.drawCircle(Offset.zero, 5 * s, Paint()..color = BuddyColors.cream.withValues(alpha: 0.9));
        canvas.restore();
      default: // a constellation again, a long way from the first
        _constellation(canvas, _constellations[(i ~/ 4) % _constellations.length], Offset(x, y), t);
    }
  }

  @override
  bool shouldRepaint(SkyPainter old) => old.climb != climb || old.time != time || old.s != s;
}

/// The tops of the trees, seen from just above them: the dark crown of the
/// forest painting carried on upwards until it breaks into the sky.
class TreetopsPainter extends CustomPainter {
  const TreetopsPainter({required this.s});

  final double s;

  /// The colour the forest painting ends on at its top edge.
  static const canopy = Color(0xFF050A0C);
  static const _leaf = Color(0xFF0A1714);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(4);
    final dark = Paint()..color = canopy;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45 + 1), dark);
    // Crowns further back first, a shade lighter, then the near ones.
    for (final (paint, rise) in [(Paint()..color = _leaf, 0.12), (dark, 0.36)]) {
      for (var x = -30.0 * s; x < size.width + 30 * s; x += (26 + random.nextDouble() * 30) * s) {
        final r = (26 + random.nextDouble() * 26) * s;
        canvas.drawCircle(Offset(x, size.height * (rise + random.nextDouble() * 0.22) + r), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TreetopsPainter old) => old.s != s;
}
