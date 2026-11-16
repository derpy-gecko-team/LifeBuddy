import 'dart:math';

import 'package:flutter/material.dart';

import '../../guildhall/theme/guild_assets.dart';
import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/ornaments.dart';
import '../../guildhall/widgets/pressable.dart';
import '../../guildhall/widgets/sketch.dart';
import '../../guildhall/widgets/torn_paper.dart';
import '../data/models.dart';
import 'bazaar_widgets.dart';

abstract final class ShopWood {
  static const pale = Color(0xFFC9A57A);
  static const light = Color(0xFFB08A63);
  static const mid = Color(0xFF8F6C4D);
  static const dark = Color(0xFF6C4F3B);
  static const alcove = Color(0xFF2B2A55);
  static const brass = GuildColors.gold;
  static const glass = Color(0xFFA990B8);
}

Paint _ink([double width = 2, double alpha = 1]) => Sketch.pen(GuildColors.ink.withValues(alpha: alpha), width);

Paint _gilt([double width = 1.6, double alpha = 1]) => Sketch.pen(ShopWood.brass.withValues(alpha: alpha), width);

Path _handLine(Offset a, Offset b, Random pen, {double wobble = 1, double over = 1.5}) {
  final d = b - a;
  final length = d.distance;
  final path = Path();
  if (length < 0.5) return path;
  final along = d / length;
  final across = Offset(-along.dy, along.dx);
  double sway() => (pen.nextDouble() - 0.5) * 2 * wobble;
  final pieces = max(1, (length / 30).round());
  var prev = a - along * (pen.nextDouble() * over);
  path.moveTo(prev.dx, prev.dy);
  for (var i = 1; i <= pieces; i++) {
    final end = i == pieces ? b + along * (pen.nextDouble() * over) : a + d * (i / pieces) + across * sway();
    final bend = (prev + end) / 2 + across * sway();
    path.quadraticBezierTo(bend.dx, bend.dy, end.dx, end.dy);
    prev = end;
  }
  return path;
}

void _handPoly(Canvas canvas, List<Offset> points, Color fill, Random pen, {double width = 2, double wobble = 1}) {
  final p = [
    for (final o in points) o + Offset((pen.nextDouble() - 0.5) * wobble * 1.4, (pen.nextDouble() - 0.5) * wobble * 1.4),
  ];
  canvas.drawPath(Path()..addPolygon(p, true), Paint()..color = fill);
  for (var i = 0; i < p.length; i++) {
    canvas.drawPath(_handLine(p[i], p[(i + 1) % p.length], pen, wobble: wobble * 0.8), _ink(width));
  }
  for (var i = 0; i < p.length; i++) {
    canvas.drawPath(_handLine(p[i], p[(i + 1) % p.length], pen, wobble: wobble * 1.7, over: 3), _ink(1, 0.42));
  }
}

void _grain(Canvas canvas, Rect board, Random pen, {bool vertical = false, int lines = 3}) {
  final paint = _ink(1, 0.22);
  final long = vertical ? board.height : board.width;
  final short = vertical ? board.width : board.height;
  for (var i = 0; i < lines; i++) {
    final at = short * (0.15 + pen.nextDouble() * 0.7);
    final length = min(long, 18 + pen.nextDouble() * 54);
    final from = pen.nextDouble() * max(1.0, long - length);
    final drift = (pen.nextDouble() - 0.5) * 2.4;
    final a = vertical ? Offset(board.left + at, board.top + from) : Offset(board.left + from, board.top + at);
    final b = vertical ? a + Offset(drift, length) : a + Offset(length, drift);
    canvas.drawPath(_handLine(a, b, pen, wobble: 1.1, over: 0), paint);
  }
}

void _knot(Canvas canvas, Offset c, double r, Random pen, {bool vertical = false}) {
  for (var k = 0; k < 3; k++) {
    final long = r * (1 - k * 0.3) * (1.5 + pen.nextDouble() * 0.3);
    final short = r * (1 - k * 0.3);
    final ring = Rect.fromCenter(
      center: c + Offset(pen.nextDouble() - 0.5, pen.nextDouble() - 0.5),
      width: (vertical ? short : long) * 2,
      height: (vertical ? long : short) * 2,
    );
    canvas.drawOval(ring, _ink(1, 0.34));
  }
  canvas.drawCircle(c, 0.9, Paint()..color = GuildColors.ink.withValues(alpha: 0.5));
}

void _hatch(Canvas canvas, Rect area, Random pen, {Color color = GuildColors.ink, double alpha = 0.24, double gap = 4.5}) {
  canvas.save();
  canvas.clipRect(area);
  final paint = Sketch.pen(color.withValues(alpha: alpha), 1);
  if (area.height > area.width * 2) {
    for (var y = area.top; y < area.bottom + area.width; y += gap + pen.nextDouble() * 2.5) {
      final reach = area.width * (0.5 + pen.nextDouble() * 0.5);
      canvas.drawLine(Offset(area.right, y), Offset(area.right - reach, y - reach * 0.7), paint);
    }
  } else {
    for (var x = area.left - area.height; x < area.right; x += gap + pen.nextDouble() * 2.5) {
      final reach = area.height * (0.5 + pen.nextDouble() * 0.5);
      canvas.drawLine(Offset(x, area.bottom), Offset(x + reach * 0.7, area.bottom - reach), paint);
    }
  }
  canvas.restore();
}

void _nail(Canvas canvas, Offset at) {
  canvas.drawCircle(at, 1.9, Paint()..color = GuildColors.ink);
  canvas.drawCircle(at + const Offset(-0.5, -0.6), 0.6, Paint()..color = GuildColors.cream.withValues(alpha: 0.7));
}

void _board(
  Canvas canvas,
  Rect rect,
  Color color,
  Random pen, {
  bool vertical = false,
  int grain = 3,
  int knots = 0,
  bool shade = true,
}) {
  _handPoly(canvas, [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft], color, pen);
  canvas.save();
  canvas.clipRect(rect);
  _grain(canvas, rect, pen, vertical: vertical, lines: grain);
  for (var k = 0; k < knots; k++) {
    final c = Offset(
      rect.left + rect.width * (0.2 + pen.nextDouble() * 0.6),
      rect.top + rect.height * (0.2 + pen.nextDouble() * 0.6),
    );
    _knot(canvas, c, min(rect.shortestSide * 0.26, 4.5), pen, vertical: vertical);
  }
  if (shade) {
    final depth = min(5.0, rect.shortestSide * 0.4);
    _hatch(
      canvas,
      vertical
          ? Rect.fromLTRB(rect.right - depth, rect.top, rect.right, rect.bottom)
          : Rect.fromLTRB(rect.left, rect.bottom - depth, rect.right, rect.bottom),
      pen,
    );
  }
  final worn = Sketch.pen(Colors.white.withValues(alpha: 0.2), 1.2);
  final long = vertical ? rect.height : rect.width;
  for (var from = 4 + pen.nextDouble() * 20; from < long - 12; from += 30 + pen.nextDouble() * 60) {
    final length = min(long - from - 4, 12 + pen.nextDouble() * 34);
    final a = vertical ? Offset(rect.left + 3, rect.top + from) : Offset(rect.left + from, rect.top + 3);
    canvas.drawPath(_handLine(a, a + (vertical ? Offset(0, length) : Offset(length, 0)), pen, wobble: 0.6, over: 0), worn);
  }
  canvas.restore();
}

Path _spiral(Offset c, double r, {double turns = 1.6, bool clockwise = true, double from = 0}) {
  final path = Path();
  const steps = 30;
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final a = from + (clockwise ? 1 : -1) * t * turns * 2 * pi;
    final p = c + Offset(cos(a), sin(a)) * (r * (1 - t * 0.82));
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path;
}

void _crescent(Canvas canvas, Offset c, double r, {double turn = 0}) {
  final moon = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: c, radius: r)),
    Path()..addOval(Rect.fromCircle(center: c + Offset(cos(turn), sin(turn) - 0.15) * (r * 0.48), radius: r * 0.86)),
  );
  canvas.drawPath(moon, Paint()..color = ShopWood.brass);
  canvas.drawPath(moon, _ink(1.2));
}

void _star(Canvas canvas, Offset c, double r, Random pen) {
  final turn = (pen.nextDouble() - 0.5) * 0.5;
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final a = turn + i * pi / 4 - pi / 2;
    final p = c + Offset(cos(a), sin(a)) * (i.isEven ? r * (0.85 + pen.nextDouble() * 0.15) : r * 0.34);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  path.close();
  canvas.drawPath(path, Paint()..color = ShopWood.brass);
  canvas.drawPath(path, _ink(1.1));
}

Path _flamePath(Offset tip) => Path()
  ..moveTo(tip.dx, tip.dy)
  ..cubicTo(tip.dx + 5, tip.dy + 6, tip.dx + 4, tip.dy + 11, tip.dx, tip.dy + 11)
  ..cubicTo(tip.dx - 4, tip.dy + 11, tip.dx - 5, tip.dy + 6, tip.dx, tip.dy)
  ..close();

void _candle(Canvas canvas, double x, double foot, double height, Random pen) {
  final glowAt = Offset(x, foot - height - 8);
  canvas.drawCircle(
    glowAt,
    22,
    Paint()
      ..shader = RadialGradient(
        colors: [GuildColors.torchlight.withValues(alpha: 0.42), GuildColors.torchlight.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: glowAt, radius: 22)),
  );
  _handPoly(
    canvas,
    [Offset(x - 8, foot - 3), Offset(x + 8, foot - 3), Offset(x + 5, foot), Offset(x - 5, foot)],
    ShopWood.brass,
    pen,
    width: 1.5,
    wobble: 0.6,
  );
  _handPoly(
    canvas,
    [Offset(x - 3.6, foot - 3 - height), Offset(x + 3.6, foot - 2 - height), Offset(x + 3.8, foot - 3), Offset(x - 3.8, foot - 3)],
    GuildColors.vellum,
    pen,
    width: 1.5,
    wobble: 0.6,
  );
  final drip = Path()
    ..moveTo(x + 3.6, foot - 2 - height)
    ..quadraticBezierTo(x + 6.5, foot - height + 3, x + 4.2, foot - height + 8 + pen.nextDouble() * 4);
  canvas.drawPath(drip, _ink(1.3));
  canvas.drawLine(Offset(x, foot - 3 - height), Offset(x + 0.6, foot - 6 - height), _ink(1.2));
  final flame = _flamePath(Offset(x + 0.8, foot - 17 - height));
  canvas.drawPath(flame, Paint()..color = GuildColors.goldBright);
  canvas.drawPath(flame, _ink(1.3));
}

class WareHero extends StatelessWidget {
  const WareHero({super.key, required this.ware, required this.child, this.dye});

  final Ware ware;
  final WareDye? dye;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(
        tag: 'ware-art-${ware.id}',
        flightShuttleBuilder: (_, _, _, _, _) => Image.asset(
          ware.artFor(dye ?? ware.dye),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
        child: child,
      ),
    );
  }
}

class ShopShelves extends StatelessWidget {
  const ShopShelves({super.key, required this.wares, required this.onOpen, required this.restockKey});

  final List<Ware> wares;
  final OpenWare onOpen;

  final Object restockKey;

  static const perShelf = 3;
  static const _post = 16.0;

  @override
  Widget build(BuildContext context) {
    final shelf = [for (final w in wares) w.id];
    final rows = (wares.length / perShelf).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Cornice(),
          CustomPaint(
            painter: const _CabinetPainter(_post),
            foregroundPainter: const _GarlandPainter(_post),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _post),
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : GuildMotion.swift,
                switchInCurve: Curves.easeOut,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: Column(
                  key: ValueKey(restockKey),
                  children: [
                    for (var r = 0; r < rows; r++)
                      _ShelfRow(
                        seed: r * 7 + 3,
                        children: [
                          for (var c = 0; c < perShelf; c++)
                            if (r * perShelf + c < wares.length)
                              _HopIn(
                                key: ValueKey(wares[r * perShelf + c].id),
                                order: r * perShelf + c,
                                child: _ShelfWare(
                                  ware: wares[r * perShelf + c],
                                  onOpen: () => onOpen(wares[r * perShelf + c].id, shelf: shelf),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const _CabinetBase(),
        ],
      ),
    );
  }
}

class _Cornice extends StatelessWidget {
  const _Cornice();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 98, child: ExcludeSemantics(child: CustomPaint(painter: _CornicePainter())));
}

class _CornicePainter extends CustomPainter {
  const _CornicePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Random(5);
    final w = size.width;
    final base = size.height - 18;

    canvas.drawRect(Rect.fromLTWH(3, base + 4, w, 18), Paint()..color = GuildColors.shadow.withValues(alpha: 0.4));

    _candle(canvas, w * 0.075, base, 24, pen);
    _candle(canvas, w * 0.135, base, 14, pen);
    _hourglass(canvas, Offset(w * 0.9, base), pen);
    _bottle(canvas, Offset(w * 0.835, base), pen);

    Path crest(double s) {
      double x(double f) => w / 2 + (w * f - w / 2) * s;
      double y(double v) => base - (base - v) * s;
      return Path()
        ..moveTo(x(0.2), y(base))
        ..cubicTo(x(0.2), y(base - 22), x(0.28), y(base - 29), x(0.36), y(base - 29))
        ..cubicTo(x(0.43), y(base - 29), x(0.44), y(13), x(0.5), y(10))
        ..cubicTo(x(0.56), y(13), x(0.57), y(base - 29), x(0.64), y(base - 29))
        ..cubicTo(x(0.72), y(base - 29), x(0.8), y(base - 22), x(0.8), y(base))
        ..close();
    }

    final outer = crest(1);
    canvas.drawPath(outer.shift(const Offset(3, 3)), Paint()..color = GuildColors.shadow.withValues(alpha: 0.4));
    canvas.drawPath(outer, Paint()..color = ShopWood.mid);
    canvas.save();
    canvas.clipPath(outer);
    _grain(canvas, Rect.fromLTWH(w * 0.2, base - 30, w * 0.6, 30), pen, lines: 7);
    _hatch(canvas, Rect.fromLTWH(w * 0.5, 8, w * 0.32, base - 8), pen, alpha: 0.16, gap: 6);
    canvas.restore();
    final panel = crest(0.8);
    canvas.drawPath(panel, Paint()..color = ShopWood.dark);
    canvas.drawPath(panel, _ink(1.4));
    canvas.drawPath(outer, _ink(2.2));
    canvas.drawPath(outer.shift(const Offset(-0.9, 0.8)), _ink(1, 0.4));

    final moon = Offset(w / 2, base - 27);
    canvas.drawCircle(moon, 14.5, _gilt(1.5));
    canvas.drawCircle(moon + const Offset(0.6, 0.4), 15.6, _gilt(0.9, 0.5));
    _crescent(canvas, moon, 9.5);
    for (final side in const [-1.0, 1.0]) {
      final curl = Offset(w / 2 + side * w * 0.16, base - 12);
      canvas.drawPath(_spiral(curl, 7.5, clockwise: side > 0, from: side > 0 ? pi : 0), _gilt(1.7));
      final sweep = Path()
        ..moveTo(curl.dx - side * 7.5, curl.dy)
        ..quadraticBezierTo(w / 2 + side * w * 0.09, base - 3, w / 2 + side * 20, base - 14);
      canvas.drawPath(sweep, _gilt(1.5));
      final leaf = Path()
        ..moveTo(w / 2 + side * w * 0.1, base - 10)
        ..quadraticBezierTo(w / 2 + side * w * 0.115, base - 21, w / 2 + side * w * 0.085, base - 23);
      canvas.drawPath(leaf, _gilt(1.2, 0.85));
      canvas.drawCircle(Offset(w / 2 + side * w * 0.225, base - 9), 1.5, Paint()..color = ShopWood.brass);
      canvas.drawCircle(Offset(w / 2 + side * 21, base - 42), 1.3, Paint()..color = ShopWood.brass);
    }
    canvas.drawCircle(Offset(w / 2, 8), 4.4, Paint()..color = ShopWood.brass);
    canvas.drawCircle(Offset(w / 2, 8), 4.4, _ink(1.5));

    _board(canvas, Rect.fromLTWH(5, base + 9, w - 10, 9), ShopWood.dark, pen, grain: 2, shade: false);
    for (var x = 22.0; x < w - 16; x += 22 + pen.nextDouble() * 5) {
      final c = Offset(x, base + 13.5 + (pen.nextDouble() - 0.5));
      final d = 2.6 + pen.nextDouble() * 0.8;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - d)
          ..lineTo(c.dx + d * 1.3, c.dy)
          ..lineTo(c.dx, c.dy + d)
          ..lineTo(c.dx - d * 1.3, c.dy)
          ..close(),
        _gilt(1.1, 0.85),
      );
    }
    _board(canvas, Rect.fromLTWH(-1, base, w + 2, 10), ShopWood.light, pen, grain: 6, knots: 1);
    _nail(canvas, Offset(9, base + 5));
    _nail(canvas, Offset(w - 9, base + 5.4));
  }

  void _hourglass(Canvas canvas, Offset foot, Random pen) {
    final x = foot.dx, y = foot.dy;
    final glass = Path()
      ..moveTo(x - 7, y - 25)
      ..lineTo(x + 7, y - 25)
      ..quadraticBezierTo(x + 6, y - 17, x + 1, y - 14)
      ..quadraticBezierTo(x + 6, y - 11, x + 7, y - 3)
      ..lineTo(x - 7, y - 3)
      ..quadraticBezierTo(x - 6, y - 11, x - 1, y - 14)
      ..quadraticBezierTo(x - 6, y - 17, x - 7, y - 25)
      ..close();
    canvas.drawPath(glass, Paint()..color = GuildColors.mist);
    canvas.drawPath(
      Path()
        ..moveTo(x - 5.6, y - 3)
        ..quadraticBezierTo(x, y - 12, x + 5.6, y - 3)
        ..close(),
      Paint()..color = ShopWood.brass,
    );
    canvas.drawPath(glass, _ink(1.5));
    canvas.drawLine(Offset(x, y - 14), Offset(x, y - 8), _gilt(1));
    for (final bar in [y - 28.0, y - 3.0]) {
      _handPoly(
        canvas,
        [Offset(x - 9.5, bar), Offset(x + 9.5, bar), Offset(x + 9.5, bar + 3.2), Offset(x - 9.5, bar + 3.2)],
        ShopWood.pale,
        pen,
        width: 1.4,
        wobble: 0.5,
      );
    }
    canvas.drawLine(Offset(x - 8.6, y - 25), Offset(x - 8.6, y - 3), _ink(1.3));
    canvas.drawLine(Offset(x + 8.6, y - 25), Offset(x + 8.6, y - 3), _ink(1.3));
  }

  void _bottle(Canvas canvas, Offset foot, Random pen) {
    final c = foot + const Offset(0, -8);
    canvas.drawCircle(c, 7.5, Paint()..color = ShopWood.glass);
    canvas.drawCircle(c, 7.5, _ink(1.5));
    final neck = Rect.fromLTWH(c.dx - 2.6, c.dy - 13, 5.2, 6.5);
    canvas.drawRect(neck, Paint()..color = GuildColors.mist);
    canvas.drawRect(neck, _ink(1.3));
    final cork = Rect.fromLTWH(c.dx - 2.2, c.dy - 16.5, 4.4, 4);
    canvas.drawRect(cork, Paint()..color = ShopWood.pale);
    canvas.drawRect(cork, _ink(1.2));
    canvas.drawArc(Rect.fromCircle(center: c, radius: 4.6), pi * 0.95, pi * 0.45, false, Sketch.pen(Colors.white70, 1.3));
  }

  @override
  bool shouldRepaint(_CornicePainter old) => false;
}

class _CabinetPainter extends CustomPainter {
  const _CabinetPainter(this.post);
  final double post;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Random(11);
    final w = size.width, h = size.height;
    canvas.drawRect(Rect.fromLTWH(3, 0, w, h + 4), Paint()..color = GuildColors.shadow.withValues(alpha: 0.4));
    canvas.drawRect(Offset.zero & size, Paint()..color = ShopWood.alcove);

    for (var x = post + 26 + pen.nextDouble() * 14; x < w - post - 14; x += 28 + pen.nextDouble() * 18) {
      final lean = (pen.nextDouble() - 0.5) * 3;
      canvas.drawPath(
        _handLine(Offset(x, 0), Offset(x + lean, h), pen, wobble: 1.3, over: 0),
        Sketch.pen(GuildColors.shadow.withValues(alpha: 0.7), 1.5),
      );
      canvas.drawPath(
        _handLine(Offset(x + 1.6, 0), Offset(x + lean + 1.6, h), pen, wobble: 1.3, over: 0),
        Sketch.pen(GuildColors.cream.withValues(alpha: 0.07), 1),
      );
    }
    final faint = Sketch.pen(GuildColors.cream.withValues(alpha: 0.07), 1);
    for (var i = 0; i < (h / 70).ceil(); i++) {
      final at = Offset(post + 12 + pen.nextDouble() * (w - post * 2 - 24), pen.nextDouble() * h);
      if (i.isEven) {
        canvas.drawOval(Rect.fromCenter(center: at, width: 5, height: 9), faint);
        canvas.drawOval(Rect.fromCenter(center: at, width: 10, height: 17), faint);
      } else {
        canvas.drawPath(_handLine(at, at + Offset(pen.nextDouble() * 8 - 4, 14 + pen.nextDouble() * 22), pen, over: 0), faint);
      }
    }
    _hatch(canvas, Rect.fromLTWH(w - post - 11, 0, 11, h), pen, color: GuildColors.shadow, alpha: 0.75, gap: 5);
    canvas.save();
    canvas.translate(post * 2 + 9, 0);
    canvas.scale(-1, 1);
    _hatch(canvas, Rect.fromLTWH(0, 0, 9, h), pen, color: GuildColors.shadow, alpha: 0.6, gap: 6);
    canvas.restore();

    _cobweb(canvas, Offset(post, 0), pen);

    for (final left in [0.0, w - post]) {
      _board(
        canvas,
        Rect.fromLTWH(left, 0, post, h),
        ShopWood.mid,
        pen,
        vertical: true,
        grain: (h / 46).ceil(),
        knots: (h / 260).ceil(),
      );
      final x = left + post / 2;
      for (var y = 54.0; y < h - 30; y += 157) {
        final c = Offset(x + (pen.nextDouble() - 0.5), y + (pen.nextDouble() - 0.5) * 6);
        final diamond = Path()
          ..moveTo(c.dx, c.dy - 6.5)
          ..lineTo(c.dx + 3.6, c.dy)
          ..lineTo(c.dx, c.dy + 6.5)
          ..lineTo(c.dx - 3.6, c.dy)
          ..close();
        canvas.drawPath(diamond, Paint()..color = ShopWood.brass);
        canvas.drawPath(diamond, _ink(1.1));
        for (final up in const [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy + up * 9)
              ..quadraticBezierTo(c.dx + 3.6, c.dy + up * 13, c.dx, c.dy + up * 18)
              ..quadraticBezierTo(c.dx - 3.6, c.dy + up * 13, c.dx, c.dy + up * 9),
            _gilt(1.1, 0.9),
          );
          canvas.drawCircle(Offset(c.dx, c.dy + up * 22), 1.1, Paint()..color = ShopWood.brass);
        }
      }
      for (var y = 128.0; y < h - 20; y += 157) {
        _nail(canvas, Offset(x + (pen.nextDouble() - 0.5) * 3, y));
      }
    }
  }

  void _cobweb(Canvas canvas, Offset corner, Random pen) {
    final silk = Sketch.pen(GuildColors.cream.withValues(alpha: 0.3), 1);
    const spokes = [0.06, 0.5, 1.0, 1.5];
    final ends = [for (final a in spokes) corner + Offset(cos(a), sin(a)) * (30 + pen.nextDouble() * 12)];
    for (final end in ends) {
      canvas.drawLine(corner, end, silk);
    }
    for (final reach in const [0.42, 0.72, 1.0]) {
      final path = Path();
      for (var i = 0; i < ends.length; i++) {
        final p = corner + (ends[i] - corner) * reach;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          final before = corner + (ends[i - 1] - corner) * reach;
          final sag = corner + ((before + p) / 2 - corner) * 0.8;
          path.quadraticBezierTo(sag.dx, sag.dy, p.dx, p.dy);
        }
      }
      canvas.drawPath(path, silk);
    }
    final hang = corner + const Offset(15, 13);
    final spider = hang + const Offset(0, 21);
    canvas.drawLine(hang, spider, silk);
    final body = Paint()..color = GuildColors.cream.withValues(alpha: 0.6);
    canvas.drawCircle(spider, 2.3, body);
    final leg = Sketch.pen(GuildColors.cream.withValues(alpha: 0.55), 0.9);
    for (final side in const [-1.0, 1.0]) {
      for (final lift in const [-2.0, 0.5, 3.0]) {
        canvas.drawLine(spider, spider + Offset(side * 4.6, lift), leg);
      }
    }
  }

  @override
  bool shouldRepaint(_CabinetPainter old) => old.post != post;
}

class _GarlandPainter extends CustomPainter {
  const _GarlandPainter(this.post);
  final double post;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Random(31);
    final thread = Sketch.pen(GuildColors.chalk.withValues(alpha: 0.75), 1.1);
    final pins = [Offset(post + 46, 2), Offset(size.width / 2, 4), Offset(size.width - post - 3, 2)];
    var charm = 0;
    for (var s = 0; s < pins.length - 1; s++) {
      final a = pins[s], b = pins[s + 1];
      final dip = Offset((a.dx + b.dx) / 2, 23 + pen.nextDouble() * 5);
      canvas.drawPath(Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(dip.dx, dip.dy, b.dx, b.dy), thread);
      for (final t in const [0.24, 0.5, 0.76]) {
        final at = a * ((1 - t) * (1 - t)) + dip * (2 * t * (1 - t)) + b * (t * t);
        final drop = 3.5 + pen.nextDouble() * 4.5;
        final c = at + Offset(0, drop + 4);
        canvas.drawLine(at, at + Offset(0, drop), thread);
        switch (charm++ % 3) {
          case 0:
            _crescent(canvas, c, 4.6, turn: pen.nextDouble() * 0.8 - 0.4);
          case 1:
            _star(canvas, c, 4.8, pen);
          default:
            canvas.drawCircle(c + const Offset(0, -1.5), 2.4, Paint()..color = ShopWood.brass);
            canvas.drawCircle(c + const Offset(0, -1.5), 2.4, _ink(1));
        }
      }
    }
    for (final pin in pins) {
      _nail(canvas, pin + const Offset(0, 1));
    }
  }

  @override
  bool shouldRepaint(_GarlandPainter old) => old.post != post;
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({required this.seed, required this.children});

  final int seed;
  final List<Widget> children;

  static const bay = 104.0;
  static const plank = 13.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShelfRowPainter(seed),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final child in children) Expanded(child: child)],
      ),
    );
  }
}

class _ShelfRowPainter extends CustomPainter {
  _ShelfRowPainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Random(seed);
    final w = size.width;
    const top = _ShelfRow.bay, thick = _ShelfRow.plank;
    final l = (pen.nextDouble() - 0.5) * 2.6, r = (pen.nextDouble() - 0.5) * 2.6;
    double sag(double x) => l + (r - l) * (x / w);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 16),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GuildColors.shadow.withValues(alpha: 0.5), GuildColors.shadow.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, w, 16)),
    );

    final under = top + thick + max(l, r);
    canvas.drawRect(Rect.fromLTWH(0, under - 3, w, 8), Paint()..color = GuildColors.shadow.withValues(alpha: 0.4));
    _hatch(canvas, Rect.fromLTWH(0, under - 3, w, 15), pen, color: GuildColors.shadow, alpha: 0.8, gap: 5);

    for (final right in const [false, true]) {
      final x = right ? w : 0.0;
      final d = right ? -1.0 : 1.0;
      final y = top + thick + sag(x) - 1;
      final bracket = Path()
        ..moveTo(x, y)
        ..lineTo(x + d * 17, y)
        ..quadraticBezierTo(x + d * 15, y + 9, x + d * 7, y + 10)
        ..quadraticBezierTo(x + d * 8, y + 18, x, y + 21)
        ..close();
      canvas.drawPath(bracket, Paint()..color = ShopWood.dark);
      canvas.drawPath(bracket, _ink(1.7));
      canvas.drawPath(_spiral(Offset(x + d * 6, y + 6), 3.4, turns: 1.2, clockwise: right), _gilt(1.1, 0.9));
    }

    _handPoly(
      canvas,
      [Offset(-1, top - 3.5 + l), Offset(w + 1, top - 3.5 + r), Offset(w + 1, top + r), Offset(-1, top + l)],
      ShopWood.pale,
      pen,
      width: 1.5,
      wobble: 0.7,
    );
    final face = [
      Offset(-1, top + l),
      Offset(w + 1, top + r),
      Offset(w + 1, top + thick + r + pen.nextDouble()),
      Offset(-1, top + thick + l + pen.nextDouble()),
    ];
    _handPoly(canvas, face, ShopWood.light, pen);

    canvas.save();
    canvas.clipPath(Path()..addPolygon(face, true));
    final plank = Rect.fromLTWH(0, top + min(l, r), w, thick + (l - r).abs() + 1);
    _grain(canvas, plank, pen, lines: 6);
    if (pen.nextDouble() < 0.7) {
      final x = w * (0.12 + pen.nextDouble() * 0.76);
      _knot(canvas, Offset(x, top + thick * 0.5 + sag(x)), 3.4, pen);
    }
    _hatch(canvas, Rect.fromLTWH(0, top + thick - 4.5 + min(l, r), w, 6 + (l - r).abs()), pen, alpha: 0.26);
    final fromRight = pen.nextBool();
    var crack = Offset(fromRight ? w : 0, top + thick * (0.3 + pen.nextDouble() * 0.4) + (fromRight ? r : l));
    final split = Path()..moveTo(crack.dx, crack.dy);
    for (var i = 0; i < 4; i++) {
      crack += Offset((fromRight ? -1 : 1) * (4 + pen.nextDouble() * 6), (pen.nextDouble() - 0.5) * 3.4);
      split.lineTo(crack.dx, crack.dy);
    }
    canvas.drawPath(split, _ink(1, 0.55));
    canvas.restore();

    final worn = Sketch.pen(Colors.white.withValues(alpha: 0.24), 1.3);
    for (var x = 6 + pen.nextDouble() * 30; x < w - 20; x += 50 + pen.nextDouble() * 70) {
      final length = 14 + pen.nextDouble() * 30;
      canvas.drawPath(
        _handLine(Offset(x, top + 2.6 + sag(x)), Offset(x + length, top + 2.6 + sag(x + length)), pen, wobble: 0.5, over: 0),
        worn,
      );
    }

    final chipAt = w * (pen.nextBool() ? 1 / 3 : 2 / 3) + (pen.nextDouble() - 0.5) * 26;
    final chipY = top + thick + sag(chipAt);
    final chip = Path()
      ..moveTo(chipAt - 4.5, chipY + 1.5)
      ..lineTo(chipAt - 1, chipY - 3.2)
      ..lineTo(chipAt + 1.6, chipY - 1.4)
      ..lineTo(chipAt + 5, chipY + 1.5)
      ..close();
    canvas.drawPath(chip, Paint()..color = ShopWood.alcove);
    canvas.drawPath(
      Path()
        ..moveTo(chipAt - 4.5, chipY + 0.6)
        ..lineTo(chipAt - 1, chipY - 3.2)
        ..lineTo(chipAt + 1.6, chipY - 1.4)
        ..lineTo(chipAt + 5, chipY + 0.6),
      _ink(1.4),
    );

    _nail(canvas, Offset(7 + pen.nextDouble() * 3, top + thick * 0.5 + l));
    _nail(canvas, Offset(w - 7 - pen.nextDouble() * 3, top + thick * 0.5 + r));
  }

  @override
  bool shouldRepaint(_ShelfRowPainter old) => old.seed != seed;
}

class _ShelfWare extends StatelessWidget {
  const _ShelfWare({required this.ware, required this.onOpen});

  final Ware ware;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return GuildPressable(
      semanticLabel: wareSemantics(ware),
      onTap: onOpen,
      haptic: true,
      pressedScale: 1,
      builder: (context, pressed) => Column(
        children: [
          SizedBox(
            height: _ShelfRow.bay,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: still ? Duration.zero : GuildMotion.press,
                curve: Curves.easeOut,
                transformAlignment: Alignment.bottomCenter,
                transform: Matrix4.translationValues(0, pressed ? -7 : 0, 0)
                  ..rotateZ(pressed ? (stableSeed(ware.id).isEven ? 0.05 : -0.05) : 0),
                padding: const EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.5,
                    colors: [
                      GuildColors.torchlight.withValues(alpha: ware.owned ? 0.08 : 0.2),
                      GuildColors.torchlight.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Opacity(
                  opacity: ware.owned ? 0.5 : 1,
                  child: WareHero(ware: ware, child: WareArt(ware.artFor(ware.dye), size: 84)),
                ),
              ),
            ),
          ),
          const SizedBox(height: _ShelfRow.plank),
          Container(width: 1.4, height: 8, color: GuildColors.chalkLine),
          if (ware.owned)
            const _PaperChip('Yours')
          else
            FittedBox(fit: BoxFit.scaleDown, child: PriceTag(ware.price, size: 12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 5, 4, 14),
            child: Text(
              ware.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GuildText.label(GuildType.xs, color: GuildColors.cream.withValues(alpha: 0.92), spacing: 0.3)
                  .copyWith(height: 1.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperChip extends StatelessWidget {
  const _PaperChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SketchBox(
      color: GuildColors.vellum,
      borderColor: GuildColors.brickDeep,
      borderWidth: 1.5,
      shadow: GuildShadow.small,
      seed: 13,
      padding: const EdgeInsets.fromLTRB(9, 2, 9, 3),
      child: Text(label.toUpperCase(), style: GuildText.title(GuildTitle.xs, color: GuildColors.brickDeep).copyWith(letterSpacing: 1.6)),
    );
  }
}

class _HopIn extends StatefulWidget {
  const _HopIn({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  State<_HopIn> createState() => _HopInState();
}

class _HopInState extends State<_HopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: GuildMotion.slide);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    Future<void>.delayed(Duration(milliseconds: 40 + min(widget.order, 14) * 36), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        return Opacity(
          opacity: Curves.easeOut.transform((t * 2.2).clamp(0.0, 1.0)),
          child: Transform.translate(
            offset: Offset(0, (1 - Curves.easeOutBack.transform(t)) * -22),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _CabinetBase extends StatelessWidget {
  const _CabinetBase();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 138, child: ExcludeSemantics(child: CustomPaint(painter: _BasePainter())));
}

class _BasePainter extends CustomPainter {
  const _BasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Random(17);
    final w = size.width, h = size.height;
    canvas.drawRect(Rect.fromLTWH(3, 4, w, h), Paint()..color = GuildColors.shadow.withValues(alpha: 0.4));

    _board(canvas, Rect.fromLTWH(0, 20, w, h - 30), ShopWood.mid, pen, grain: 0, shade: false);
    _hatch(canvas, Rect.fromLTWH(0, 20, w, 9), pen, alpha: 0.3, gap: 5);

    final side = w * 0.25;
    const drawers = 3;
    final drawerH = (h - 30 - 16 - (drawers - 1) * 5) / drawers;
    Offset? keyPull;
    for (final right in const [false, true]) {
      for (var i = 0; i < drawers; i++) {
        final drawer = Rect.fromLTWH(
          (right ? w - side + 1 : 7) + (pen.nextDouble() - 0.5) * 1.4,
          29 + i * (drawerH + 5) + (pen.nextDouble() - 0.5) * 1.4,
          side - 8,
          drawerH,
        );
        _board(canvas, drawer, ShopWood.light, pen, grain: 2, knots: pen.nextDouble() < 0.3 ? 1 : 0);
        final plate = Rect.fromCenter(
          center: drawer.center + Offset(0, -drawerH * 0.14),
          width: min(34.0, drawer.width * 0.56),
          height: 9,
        );
        _handPoly(
          canvas,
          [plate.topLeft, plate.topRight, plate.bottomRight, plate.bottomLeft],
          GuildColors.vellum,
          pen,
          width: 1.2,
          wobble: 0.5,
        );
        final scribble = Path()..moveTo(plate.left + 4, plate.center.dy);
        for (var x = plate.left + 6; x < plate.right - 4; x += 3) {
          scribble.lineTo(x, plate.center.dy + (pen.nextDouble() - 0.5) * 3.4);
        }
        canvas.drawPath(scribble, Sketch.pen(GuildColors.pencil, 0.9));
        final pull = drawer.center + Offset(0, drawerH * 0.27);
        canvas.drawArc(Rect.fromCenter(center: pull, width: 13, height: 8), 0, pi, false, _ink(3));
        canvas.drawArc(Rect.fromCenter(center: pull, width: 13, height: 8), 0, pi, false, _gilt(1.6));
        if (right && i == 1) keyPull = pull + const Offset(24, -1);
      }
    }

    final doors = Rect.fromLTRB(side + 4, 29, w - side - 4, h - 17);
    for (final right in const [false, true]) {
      final door = Rect.fromLTWH(
        right ? doors.center.dx + 2 : doors.left,
        doors.top + (pen.nextDouble() - 0.5) * 1.6,
        doors.width / 2 - 2,
        doors.height,
      );
      _board(canvas, door, ShopWood.dark, pen, vertical: true, grain: 4, knots: 1);
      final frame = door.deflate(6);
      final corners = [frame.topLeft, frame.topRight, frame.bottomRight, frame.bottomLeft];
      for (var i = 0; i < 4; i++) {
        canvas.drawPath(_handLine(corners[i], corners[(i + 1) % 4], pen, wobble: 0.9, over: 2.5), _gilt(1.2, 0.85));
      }
      for (final corner in corners) {
        final inward = (frame.center - corner);
        canvas.drawCircle(corner + Offset(inward.dx.sign * 5, inward.dy.sign * 5), 1.2, Paint()..color = ShopWood.brass);
      }
      final c = door.center + Offset(0, -2);
      if (right) {
        _star(canvas, c, 13, pen);
        for (var k = 0; k < 4; k++) {
          final a = pi / 4 + k * pi / 2;
          canvas.drawCircle(c + Offset(cos(a), sin(a)) * 12.5, 1.4, Paint()..color = ShopWood.brass);
        }
      } else {
        _crescent(canvas, c, 12, turn: -0.3);
        for (var k = 0; k < 7; k++) {
          final a = pi * 0.62 + k * pi * 0.2;
          canvas.drawLine(c + Offset(cos(a), sin(a)) * 16, c + Offset(cos(a), sin(a)) * (19.5 + (k.isEven ? 2.5 : 0)), _gilt(1.1, 0.9));
        }
      }
      final hingeX = right ? door.right - 1.5 : door.left + 1.5;
      for (final f in const [0.2, 0.8]) {
        final hinge = Rect.fromCenter(center: Offset(hingeX, door.top + door.height * f), width: 5, height: 11);
        canvas.drawRect(hinge, Paint()..color = ShopWood.brass);
        canvas.drawRect(hinge, _ink(1.2));
      }
      final knob = Offset(right ? door.left + 6.5 : door.right - 6.5, door.center.dy + 3);
      canvas.drawCircle(knob, 3.6, Paint()..color = ShopWood.brass);
      canvas.drawCircle(knob, 3.6, _ink(1.4));
      canvas.drawCircle(knob + const Offset(-1, -1.1), 0.9, Paint()..color = Colors.white70);
    }

    if (keyPull != null) {
      final ring = keyPull + const Offset(0, 6);
      canvas.drawCircle(ring, 5, _ink(2.6));
      canvas.drawCircle(ring, 5, _gilt(1.4));
      for (final lean in const [-0.28, 0.2]) {
        final end = ring + Offset(sin(lean) * 17, 5 + cos(lean) * 14);
        final from = ring + Offset(sin(lean) * 5, cos(lean) * 5);
        canvas.drawLine(from, end, _ink(2.8));
        canvas.drawLine(from, end, _gilt(1.5));
        canvas.drawLine(end, end + const Offset(3.4, -0.6), _gilt(1.5));
        canvas.drawLine(end + const Offset(-0.4, -3.4), end + const Offset(2.6, -4), _gilt(1.3));
      }
    }

    _board(canvas, Rect.fromLTWH(3, 14, w - 6, 7), ShopWood.dark, pen, grain: 1, shade: false);
    _board(canvas, Rect.fromLTWH(-4, 0, w + 8, 15), ShopWood.light, pen, grain: 7, knots: 2);
    _nail(canvas, const Offset(8, 7.5));
    _nail(canvas, Offset(w - 8, 7));
    _board(canvas, Rect.fromLTWH(-3, h - 11, w + 6, 11), ShopWood.dark, pen, grain: 4);
  }

  @override
  bool shouldRepaint(_BasePainter old) => false;
}

class FeaturedNiche extends StatelessWidget {
  const FeaturedNiche({super.key, required this.ware, required this.now, required this.onOpen});

  final Ware ware;
  final DateTime now;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final leaves = ware.leavesAt;
    return GuildPressable(
      semanticLabel: '${wareSemantics(ware)}. ${ware.blurb}${leaves == null ? '' : ' ${leavesLabel(leaves, now)}.'}',
      onTap: onOpen,
      pressedScale: 0.98,
      haptic: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 132,
            height: 196,
            child: CustomPaint(
              painter: const _NichePainter(),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Opacity(
                    opacity: ware.owned ? 0.55 : 1,
                    child: WareHero(ware: ware, child: WareArt(ware.artFor(ware.dye), size: 92)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: GuildSpace.md),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                TornPaper(
                  seed: 37,
                  tear: 4,
                  tearBottom: 10,
                  padding: const EdgeInsets.fromLTRB(14, 20, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leaves != null) ...[
                        Row(
                          children: [
                            ExcludeSemantics(
                              child: Image.asset(
                                GuildAssets.iconHourglass,
                                height: 14,
                                color: GuildColors.brickDeep,
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: GuildSpace.xs),
                            Flexible(
                              child: Text(
                                leavesLabel(leaves, now),
                                style: GuildText.hand(GuildType.sm, color: GuildColors.brickDeep),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: GuildSpace.xs),
                      ],
                      Text(
                        leaves == null ? ware.shelf : 'Rare find · ${ware.category.label}',
                        style: GuildText.label(GuildType.xs, color: GuildColors.inkSoft, spacing: 0.4),
                      ),
                      Text(ware.name, style: GuildText.title(GuildTitle.xl, color: GuildColors.brickDeep)),
                      const SizedBox(height: GuildSpace.hair),
                      Text(ware.blurb, style: GuildText.hand(GuildType.sm)),
                      const SizedBox(height: GuildSpace.sm),
                      RarityMark(ware.rarity),
                      const SizedBox(height: GuildSpace.sm),
                      if (ware.owned)
                        Text('In your chest', style: GuildText.hand(GuildType.sm, color: GuildColors.inkSoft))
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: PriceTag(ware.price),
                        ),
                    ],
                  ),
                ),
                const Positioned(top: -9, left: 0, right: 0, child: Center(child: Fastener(kind: FastenerKind.tape))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NichePainter extends CustomPainter {
  const _NichePainter();

  Path _arch(Rect r) {
    final radius = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + radius)
      ..arcToPoint(Offset(r.right, r.top + radius), radius: Radius.circular(radius))
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Random(23);
    final ink = Sketch.pen(GuildColors.ink, 2.2);
    final outer = _arch((Offset.zero & size).deflate(1.5));
    final inside = Rect.fromLTRB(13, 13, size.width - 13, size.height - 12);
    final inner = _arch(inside);

    canvas.drawPath(outer.shift(const Offset(3, 4)), Paint()..color = GuildColors.shadow.withValues(alpha: 0.45));
    canvas.drawPath(outer, Paint()..color = ShopWood.mid);
    canvas.save();
    canvas.clipPath(outer);
    _grain(canvas, Rect.fromLTWH(0, size.height * 0.4, 13, size.height * 0.6), pen, vertical: true, lines: 3);
    _grain(canvas, Rect.fromLTWH(size.width - 13, size.height * 0.4, 13, size.height * 0.6), pen, vertical: true, lines: 3);
    canvas.restore();
    canvas.drawPath(outer, ink);

    canvas.drawPath(inner, Paint()..color = ShopWood.alcove);
    canvas.save();
    canvas.clipPath(inner);
    final glowAt = Offset(size.width / 2, size.height * 0.62);
    canvas.drawCircle(
      glowAt,
      size.width * 0.62,
      Paint()
        ..shader = RadialGradient(
          colors: [GuildColors.torchlight.withValues(alpha: 0.5), GuildColors.torchlight.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: glowAt, radius: size.width * 0.62)),
    );
    canvas.restore();
    canvas.drawPath(inner, ink);

    final sill = Rect.fromLTWH(6, size.height - 27, size.width - 12, 13);
    _board(canvas, sill, ShopWood.light, pen, grain: 3);
    for (final x in [inside.left + 9, inside.right - 9]) {
      final candle = Rect.fromLTWH(x - 3.5, sill.top - 17, 7, 17);
      canvas.drawRect(candle, Paint()..color = GuildColors.vellum);
      canvas.drawRect(candle, Sketch.pen(GuildColors.ink, 1.5));
      final flame = _flamePath(Offset(x, candle.top - 12));
      canvas.drawPath(flame, Paint()..color = GuildColors.goldBright);
      canvas.drawPath(flame, Sketch.pen(GuildColors.ink, 1.4));
    }

    final key = Offset(size.width / 2, 7.5);
    canvas.drawCircle(key, 4.5, Paint()..color = ShopWood.brass);
    canvas.drawCircle(key, 4.5, Sketch.pen(GuildColors.ink, 1.5));
  }

  @override
  bool shouldRepaint(_NichePainter old) => false;
}
