import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The small things that move around the fire: the embers and the fireflies.
/// Both are painted from the clock alone, over the still artwork.

double _chance(int a, [int b = 0]) {
  final x = sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// The fire, still warm: a glow that breathes and gutters over the ash, the
/// cracks in the logs flaring one by one, and sparks drifting up.
///
/// Laid over `campfire.png` (393 x 226 in the frame's units), with [headroom]
/// more above it for the sparks to rise into.
class EmbersPainter extends CustomPainter {
  EmbersPainter({required this.time, required this.s}) : super(repaint: time);

  final ValueListenable<double> time;
  final double s;

  static const headroom = 170.0;

  // The heart of the fire, and the glowing cracks along the logs, as they
  // lie in campfire.png.
  static const _heart = Offset(197, 112);
  static const _cracks = [
    Offset(130, 127),
    Offset(150, 124),
    Offset(190, 121),
    Offset(214, 113),
    Offset(175, 98),
    Offset(210, 88),
    Offset(245, 120),
    Offset(262, 130),
    Offset(218, 140),
    Offset(142, 150),
  ];

  static const _orange = Color(0xFFFF8A3C);
  static const _yellow = Color(0xFFFFD27A);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas.translate(0, headroom * s);
    Offset at(Offset p) => p * s;

    // The glow: never quite steady.
    final flicker = 0.62 + 0.2 * sin(t * 1.9) + 0.11 * sin(t * 5.3 + 1) + 0.07 * sin(t * 11.7 + 2);
    final glow = Rect.fromCenter(center: at(_heart), width: 330 * s, height: 190 * s);
    canvas.drawOval(
      glow,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            _orange.withValues(alpha: 0.30 * flicker),
            _orange.withValues(alpha: 0.10 * flicker),
            _orange.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(glow),
    );

    // Each crack flares and dims in its own time.
    final ember = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < _cracks.length; i++) {
      final heat = 0.5 + 0.5 * sin(t * (0.9 + 0.8 * _chance(i)) + i * 2.4);
      final c = at(_cracks[i]);
      // Soft, in two rings, so it reads as heat and not as a disc.
      ember.color = _orange.withValues(alpha: 0.04 + 0.05 * heat);
      canvas.drawCircle(c, (12 + 4 * heat) * s, ember);
      ember.color = _orange.withValues(alpha: 0.06 + 0.10 * heat);
      canvas.drawCircle(c, (5.5 + 2 * heat) * s, ember);
      ember.color = _yellow.withValues(alpha: 0.12 + 0.5 * heat);
      canvas.drawCircle(c, (1.6 + 1.6 * heat) * s, ember);
    }

    // Sparks: each lives a few seconds, wanders up on the warm air, and is
    // born again somewhere else in the fire.
    final spark = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 14; i++) {
      final life = 2.6 + 2.4 * _chance(i, 1);
      final age = (t + life * _chance(i, 2)) / life;
      final born = age.floor();
      final p = age - born;
      final from = at(_heart) + Offset((_chance(i, born) - 0.5) * 110 * s, (_chance(born, i) - 0.5) * 34 * s);
      final rise = (70 + 150 * _chance(i + 31, born)) * s;
      final drift = sin(p * 5 + i) * 14 * s + (_chance(i, born + 9) - 0.5) * 50 * s * p;
      final fade = p < 0.12 ? p / 0.12 : pow(1 - p, 1.4).toDouble();
      final c = from + Offset(drift, -rise * p);
      spark.color = _orange.withValues(alpha: 0.28 * fade);
      canvas.drawCircle(c, 3.4 * s, spark);
      spark.color = _yellow.withValues(alpha: 0.95 * fade);
      canvas.drawCircle(c, (1.5 - 0.7 * p) * s, spark);
    }
  }

  @override
  bool shouldRepaint(EmbersPainter old) => old.time != time || old.s != s;
}

/// Fireflies wandering between the trees, each on its own slow loop, each
/// glowing and going dark as fireflies do.
class FirefliesPainter extends CustomPainter {
  FirefliesPainter({required this.time, required this.s, required this.top}) : super(repaint: time);

  final ValueListenable<double> time;
  final double s;

  /// Where the frame's y = 0 falls on the canvas.
  final double top;

  static const _count = 11;
  static const _light = Color(0xFFE9F5A0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final paint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < _count; i++) {
      // Home is somewhere among the trunks, down to the edge of the clearing.
      final home = Offset((0.06 + 0.88 * _chance(i, 3)) * size.width, top + (215 + 440 * _chance(i, 4)) * s);
      final pace = 0.16 + 0.2 * _chance(i, 5);
      final phase = i * 1.9;
      final at =
          home +
          Offset(
            (34 * sin(t * pace + phase) + 15 * sin(t * pace * 2.7 + phase * 2)) * s,
            (22 * cos(t * pace * 1.3 + phase) + 10 * sin(t * pace * 3.1 + phase)) * s,
          );
      // Lit for a while, dark for a while.
      final pulse = sin(t * (0.7 + 0.6 * _chance(i, 6)) + phase * 3);
      final lit = ((pulse + 0.35) / 1.35).clamp(0.0, 1.0);
      if (lit == 0) continue;
      final size_ = 0.8 + 0.5 * _chance(i, 7);
      paint.color = _light.withValues(alpha: 0.07 * lit);
      canvas.drawCircle(at, 11 * size_ * s, paint);
      paint.color = _light.withValues(alpha: 0.16 * lit);
      canvas.drawCircle(at, 5.5 * size_ * s, paint);
      paint.color = _light.withValues(alpha: 0.95 * lit);
      canvas.drawCircle(at, 1.7 * size_ * s, paint);
    }
  }

  @override
  bool shouldRepaint(FirefliesPainter old) => old.time != time || old.s != s || old.top != top;
}
