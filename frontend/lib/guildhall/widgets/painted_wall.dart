import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/guild_theme.dart';

enum WallVariant {
  board(7),
  journey(23),
  quest(41),
  bazaar(59);

  const WallVariant(this.seed);
  final int seed;
}

class PaintedWall extends StatelessWidget {
  const PaintedWall({super.key, this.variant = WallVariant.board, this.scroll});

  final WallVariant variant;

  final ValueListenable<double>? scroll;

  static const _rate = 0.12;

  static const _reach = 200.0;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final still = scroll == null || MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final view = constraints.biggest;
        if (!view.isFinite || view.isEmpty) return const SizedBox.shrink();
        final size = Size(view.width, view.height + _reach);
        final Widget wall = RawImage(
          image: _WallCache.imageFor(size, dpr, variant),
          width: size.width,
          height: size.height,
          fit: BoxFit.fill,
        );
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: size.height,
            maxHeight: size.height,
            child: still
                ? wall
                : ValueListenableBuilder<double>(
                    valueListenable: scroll!,
                    builder: (context, pixels, child) => Transform.translate(
                      offset: Offset(0, -(pixels * _rate).clamp(0.0, _reach)),
                      child: child,
                    ),
                    child: wall,
                  ),
          ),
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
    _paintWash(canvas, size, variant.seed);
    _Doodler(canvas, size, variant).draw();
    final picture = recorder.endRecording();
    final image = picture.toImageSync((size.width * dpr).ceil(), (size.height * dpr).ceil());
    picture.dispose();
    return _images[key] = image;
  }
}

void _paintWash(Canvas canvas, Size size, int seed) {
  final rnd = Random(seed);
  final area = Offset.zero & size;
  canvas.drawRect(area, Paint()..color = GuildColors.indigo);

  canvas.save();
  canvas.clipRect(area);

  final patches = (size.width * size.height / 16000).round();
  for (var i = 0; i < patches; i++) {
    final lighter = rnd.nextBool();
    final center = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
    final w = 90 + rnd.nextDouble() * 170;
    final h = 50 + rnd.nextDouble() * 110;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()
        ..color = (lighter ? GuildColors.indigoLight : GuildColors.indigoDeep)
            .withValues(alpha: 0.10 + rnd.nextDouble() * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
  }

  final streaks = (size.height / 13).round();
  for (var i = 0; i < streaks; i++) {
    final y = rnd.nextDouble() * size.height;
    final from = -20 + rnd.nextDouble() * size.width * 0.6;
    final length = size.width * (0.25 + rnd.nextDouble() * 0.7);
    final path = Path()..moveTo(from, y);
    var x = from;
    var dy = 0.0;
    while (x < from + length) {
      x += 40 + rnd.nextDouble() * 30;
      dy += (rnd.nextDouble() - 0.5) * 5;
      path.lineTo(x, y + dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = (rnd.nextDouble() < 0.55 ? GuildColors.indigoLight : GuildColors.shadow)
            .withValues(alpha: 0.05 + rnd.nextDouble() * 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + rnd.nextDouble() * 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }
  canvas.restore();
}

class _Doodler {
  _Doodler(this.canvas, this.size, this.variant) : pen = Random(variant.seed * 13 + 1);

  final Canvas canvas;
  final Size size;
  final WallVariant variant;
  final Random pen;

  static const _alpha = 0.5;

  final _line = Path();
  final _solid = Path();

  double _r(double from, double to) => from + pen.nextDouble() * (to - from);
  double _jitter(double amount) => (pen.nextDouble() - 0.5) * 2 * amount;

  List<Rect> get _quiet => switch (variant) {
        WallVariant.board => [Rect.fromLTWH(0, 0, size.width * 0.8, 200)],
        WallVariant.journey => [Rect.fromLTWH(0, 0, size.width, 120)],
        WallVariant.quest => [Rect.fromLTWH(0, 0, size.width, 150)],
        WallVariant.bazaar => [Rect.fromLTWH(0, 0, size.width, 215)],
      };

  bool _isQuiet(Offset p) => _quiet.any((r) => r.contains(p));

  void draw() {
    final topLeft = _quiet.first.bottom;
    _vine(Offset(_r(10, 22), topLeft + _r(10, 40)), pi / 2, size.height - topLeft - 60, sway: 16);
    _vine(Offset(size.width - _r(10, 22), _r(160, 200)), pi / 2, size.height - 260, sway: 16);
    _vine(Offset(size.width * _r(0.25, 0.4), size.height * _r(0.52, 0.6)), _r(-0.5, 0.2), size.width * 0.5, sway: 12);
    _vine(Offset(size.width * _r(0.5, 0.7), size.height * _r(0.86, 0.92)), pi + _r(-0.3, 0.3), size.width * 0.45, sway: 12);

    const cell = 104.0;
    for (var y = cell * 0.2; y < size.height; y += cell) {
      for (var x = cell * 0.25; x < size.width; x += cell) {
        final at = Offset(x + _r(0, cell * 0.6), y + _r(0, cell * 0.6));
        final roll = pen.nextDouble();
        if (_isQuiet(at) || at.dx > size.width - 8 || at.dy > size.height - 8) continue;
        if (roll < 0.20) {
          _star(at, _r(7, 13));
        } else if (roll < 0.34) {
          _swirl(at, _r(8, 15));
        } else if (roll < 0.46) {
          _sun(at, _r(12, 21));
        } else if (roll < 0.58) {
          _burst(at, _r(9, 16));
        } else if (roll < 0.74) {
          _dots(at);
        } else if (roll < 0.86) {
          _sprig(at, _r(0, 2 * pi));
        }
      }
    }

    final chalk = GuildColors.chalk;
    canvas.drawPath(_solid, Paint()..color = chalk.withValues(alpha: _alpha * 0.9));
    canvas.drawPath(
      _line,
      Paint()
        ..color = chalk.withValues(alpha: _alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      _line.shift(const Offset(0.7, 0.5)),
      Paint()
        ..color = chalk.withValues(alpha: _alpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _curve(List<Offset> points) {
    if (points.length < 2) return;
    _line.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      _line.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    _line.lineTo(points.last.dx, points.last.dy);
  }

  List<Offset> _coil(Offset start, double heading, double radius, {required double side, double turns = 1.6}) {
    final center = start + Offset(cos(heading + side * pi / 2), sin(heading + side * pi / 2)) * radius;
    final from = heading - side * pi / 2;
    final steps = (turns * 18).round();
    return [
      for (var i = 0; i <= steps; i++)
        center +
            Offset(cos(from + side * turns * 2 * pi * i / steps), sin(from + side * turns * 2 * pi * i / steps)) *
                (radius * (1 - 0.82 * i / steps)),
    ];
  }

  void _leaf(Offset base, double angle, double length, {bool filled = false}) {
    final tip = base + Offset(cos(angle), sin(angle)) * length;
    final across = Offset(-sin(angle), cos(angle)) * (length * 0.3);
    final mid = Offset.lerp(base, tip, 0.5)!;
    final target = filled ? _solid : _line;
    target
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(mid.dx + across.dx, mid.dy + across.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(mid.dx - across.dx, mid.dy - across.dy, base.dx, base.dy);
  }

  void _vine(Offset start, double heading, double length, {required double sway}) {
    final points = <Offset>[start];
    final phase = _r(0, 2 * pi);
    final wave = _r(110, 170);
    var at = start;
    var travelled = 0.0;
    var nextBranch = _r(24, 50);
    var side = pen.nextBool() ? 1.0 : -1.0;

    while (travelled < length) {
      const step = 13.0;
      travelled += step;
      final bend = cos(travelled / wave * 2 * pi + phase) * sway / wave * 2 * pi;
      final dir = heading + atan(bend) + _jitter(0.08);
      at += Offset(cos(dir), sin(dir)) * step;
      points.add(at);

      if (travelled >= nextBranch && !_isQuiet(at)) {
        nextBranch = travelled + _r(34, 70);
        side = -side;
        final out = dir + side * _r(0.7, 1.2);
        final roll = pen.nextDouble();
        if (roll < 0.42) {
          final stalk = at + Offset(cos(out), sin(out)) * _r(8, 16);
          _curve([at, Offset.lerp(at, stalk, 0.5)! + Offset(_jitter(2), _jitter(2)), stalk]);
          _curve(_coil(stalk, out, _r(5, 10), side: side));
        } else if (roll < 0.85) {
          _leaf(at, out, _r(11, 19), filled: pen.nextDouble() < 0.45);
          if (pen.nextDouble() < 0.5) _leaf(at, dir - side * _r(0.7, 1.2), _r(9, 15));
        } else {
          final dot = at + Offset(cos(out), sin(out)) * _r(8, 14);
          _solid.addOval(Rect.fromCircle(center: dot, radius: _r(1.3, 2.2)));
        }
      }
    }
    _curve(points);
    final last = points.last;
    final before = points[points.length - 2];
    _curve(_coil(last, (last - before).direction, _r(7, 12), side: side, turns: 1.4));
  }

  void _sprig(Offset at, double angle) {
    final length = _r(22, 38);
    final tip = at + Offset(cos(angle), sin(angle)) * length;
    final bend = Offset.lerp(at, tip, 0.5)! + Offset(-sin(angle), cos(angle)) * _jitter(6);
    _curve([at, bend, tip]);
    for (final t in [0.35, 0.65, 1.0]) {
      final on = Offset.lerp(at, tip, t)!;
      _leaf(on, angle + _r(0.6, 1.0), _r(8, 13), filled: pen.nextBool());
      if (t < 1) _leaf(on, angle - _r(0.6, 1.0), _r(8, 13));
    }
  }

  void _swirl(Offset at, double radius) {
    final heading = _r(0, 2 * pi);
    _curve(_coil(at, heading, radius, side: pen.nextBool() ? 1 : -1, turns: _r(1.5, 2.3)));
  }

  void _star(Offset at, double radius) {
    final points = pen.nextDouble() < 0.4 ? 4 : 5;
    final turn = _r(0, 2 * pi);
    final inner = radius * _r(0.34, 0.44);
    for (var i = 0; i < points * 2; i++) {
      final a = turn + i * pi / points;
      final r = i.isEven ? radius * _r(0.82, 1.15) : inner;
      final p = at + Offset(cos(a), sin(a)) * r;
      i == 0 ? _solid.moveTo(p.dx, p.dy) : _solid.lineTo(p.dx, p.dy);
    }
    _solid.close();
  }

  void _burst(Offset at, double radius) {
    final rays = 9 + pen.nextInt(5);
    final turn = _r(0, 2 * pi);
    for (var i = 0; i < rays; i++) {
      final a = turn + i * 2 * pi / rays + _jitter(0.12);
      final from = at + Offset(cos(a), sin(a)) * radius * 0.12;
      final to = at + Offset(cos(a), sin(a)) * radius * _r(0.6, 1.15);
      _line
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
    }
    _solid.addOval(Rect.fromCircle(center: at, radius: radius * 0.22));
  }

  void _sun(Offset at, double radius) {
    for (var pass = 0; pass < 2; pass++) {
      final from = _r(0, 2 * pi);
      final wobble = radius * 0.06;
      _curve([
        for (var i = 0; i <= 20; i++)
          at +
              Offset(cos(from + i * 2 * pi / 19), sin(from + i * 2 * pi / 19)) * (radius + _jitter(wobble)) +
              Offset(pass * 0.8, pass * 0.6),
      ]);
    }
    if (pen.nextDouble() < 0.6) {
      final slant = _r(0.5, 1.0);
      final across = Offset(cos(slant), sin(slant));
      final along = Offset(-sin(slant), cos(slant));
      final scribble = <Offset>[];
      var flip = 1.0;
      for (var d = -radius * 0.8; d <= radius * 0.8; d += radius * 0.17) {
        final half = sqrt(max(0, radius * radius * 0.86 - d * d));
        scribble.add(at + along * d + across * (half * flip) + Offset(_jitter(0.8), _jitter(0.8)));
        flip = -flip;
      }
      for (var i = 0; i < scribble.length - 1; i++) {
        _line
          ..moveTo(scribble[i].dx, scribble[i].dy)
          ..lineTo(scribble[i + 1].dx, scribble[i + 1].dy);
      }
    } else {
      _curve(_coil(at + Offset(radius * 0.5, 0), -pi / 2, radius * 0.5, side: -1, turns: 1.2));
    }
  }

  void _dots(Offset at) {
    final count = 2 + pen.nextInt(4);
    for (var i = 0; i < count; i++) {
      _solid.addOval(
        Rect.fromCircle(center: at + Offset(_jitter(16), _jitter(16)), radius: _r(1.1, 2.3)),
      );
    }
  }
}
