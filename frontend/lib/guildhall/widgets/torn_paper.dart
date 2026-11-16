import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../theme/guild_theme.dart';

Color paperColor(PaperTone tone) => switch (tone) {
      PaperTone.parchment => GuildColors.parchment,
      PaperTone.sage => GuildColors.mist,
      PaperTone.vellum => GuildColors.vellum,
    };

class TornPaper extends StatelessWidget {
  const TornPaper({
    super.key,
    required this.child,
    this.color = GuildColors.parchment,
    this.foldColor,
    this.seed = 1,
    this.tear = 6,
    this.tearBottom,
    this.foldCorner = false,
    this.padding = const EdgeInsets.all(16),
  });

  factory TornPaper.forTone({
    Key? key,
    required PaperTone tone,
    required Widget child,
    int seed = 1,
    double tear = 6,
    double? tearBottom,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      TornPaper(
        key: key,
        color: paperColor(tone),
        foldColor: tone == PaperTone.sage ? GuildColors.mistDark : null,
        foldCorner: tone == PaperTone.sage,
        seed: seed,
        tear: tone == PaperTone.vellum ? tear * 1.5 : tear,
        tearBottom: tearBottom,
        padding: padding,
        child: child,
      );

  final Widget child;
  final Color color;
  final Color? foldColor;
  final int seed;

  final double tear;

  final double? tearBottom;

  final bool foldCorner;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final shape = _TearShape(seed, tear, tearBottom ?? tear * 2, foldCorner);
    return CustomPaint(
      painter: _TornPaperPainter(
        shape: shape,
        color: color,
        foldColor: foldColor ?? Color.lerp(color, Colors.black, 0.15)!,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

typedef _Sheet = ({Path outline, Path loose, Path hatch, Path smudge, Path flecks});

@immutable
class _TearShape {
  const _TearShape(this.seed, this.tear, this.tearBottom, this.foldCorner);

  final int seed;
  final double tear;
  final double tearBottom;
  final bool foldCorner;

  static const fold = 26.0;
  static final _cache = <(int, double, double, bool, Size), _Sheet>{};

  _Sheet sheet(Size s) {
    final key = (seed, tear, tearBottom, foldCorner, s);
    final cached = _cache[key];
    if (cached != null) return cached;
    if (_cache.length > 256) _cache.remove(_cache.keys.first);
    return _cache[key] = _build(s);
  }

  _Sheet _build(Size s) {
    final points = _tornEdge(s);
    final pen = Random(seed * 131 + 7);
    return (
      outline: Path()..addPolygon(points, true),
      loose: _looseLine(points, s, pen),
      hatch: _hatching(s, pen),
      smudge: _smudges(s, pen),
      flecks: _flecks(s, pen),
    );
  }

  List<Offset> _tornEdge(Size s) {
    final rnd = Random(seed);
    final points = <Offset>[];
    double jag(double depth) => rnd.nextDouble() * depth;
    void add(double x, double y) => points.add(Offset(x, y));

    add(jag(tear), jag(tear));
    for (var x = 12.0; x < s.width - (foldCorner ? fold : 12); x += 10 + rnd.nextDouble() * 14) {
      add(x, jag(tear));
    }
    if (foldCorner) {
      add(s.width - fold, 0);
      add(s.width, fold);
    } else {
      add(s.width - jag(tear), jag(tear));
    }
    for (var y = 16.0; y < s.height - 16; y += 14 + rnd.nextDouble() * 20) {
      add(s.width - jag(tear * 0.6), y);
    }
    for (var x = s.width - 8; x > 8; x -= 8 + rnd.nextDouble() * 16) {
      final deep = rnd.nextDouble() < 0.25;
      add(x, s.height - jag(deep ? tearBottom : tearBottom * 0.35));
    }
    add(jag(tear), s.height - jag(tearBottom * 0.5));
    for (var y = s.height - 16; y > 16; y -= 14 + rnd.nextDouble() * 20) {
      add(jag(tear * 0.6), y);
    }
    return points;
  }

  Path _looseLine(List<Offset> points, Size s, Random pen) {
    final path = Path();
    var penDown = false;
    for (var i = 0; i <= points.length; i++) {
      final p = points[i % points.length];
      final x = p.dx + (s.width / 2 - p.dx).sign * 2.4 + (pen.nextDouble() - 0.5) * 2.4;
      final y = p.dy + (s.height / 2 - p.dy).sign * 2.4 + (pen.nextDouble() - 0.5) * 2.4;
      if (penDown && pen.nextDouble() > 0.12) {
        path.lineTo(x, y);
      } else {
        path.moveTo(x, y);
        penDown = true;
      }
    }
    return path;
  }

  Path _hatching(Size s, Random pen) {
    final path = Path();
    void stroke(double x, double y, double angle, double length) {
      final a = angle + (pen.nextDouble() - 0.5) * 0.18;
      path
        ..moveTo(x, y)
        ..lineTo(x + cos(a) * length, y + sin(a) * length);
    }

    const upLeft = -pi * 0.62;
    final corner = min(s.width * 0.42, 110.0);
    for (var x = s.width - 4; x > 6; x -= 4.5 + pen.nextDouble() * 2.5) {
      final near = ((x - (s.width - corner)) / corner).clamp(0.0, 1.0);
      if (near == 0 && pen.nextDouble() < 0.45) continue;
      stroke(x, s.height - tearBottom * 0.3, upLeft, 5 + near * near * 24 + pen.nextDouble() * 5);
    }
    final side = min(s.height * 0.5, 150.0);
    for (var y = s.height - 10; y > s.height - side; y -= 5 + pen.nextDouble() * 3) {
      final near = (y - (s.height - side)) / side;
      stroke(s.width - 1, y, upLeft, 4 + near * 13 + pen.nextDouble() * 4);
    }
    for (var i = 0; i < 7; i++) {
      stroke(5 + i * 5.0, 2, pi * 0.36, (7 - i) * 3.2 + 3);
      stroke(2, 7 + i * 5.0, -pi * 0.1, (7 - i) * 2.6 + 3);
    }
    return path;
  }

  Path _smudges(Size s, Random pen) {
    final path = Path();
    final patches = s.height > 200 ? 2 : 1;
    for (var i = 0; i < patches; i++) {
      final w = 34 + pen.nextDouble() * 30;
      final h = 16 + pen.nextDouble() * 14;
      final left = 12 + pen.nextDouble() * max(1.0, s.width - w - 24);
      final top = 12 + pen.nextDouble() * max(1.0, s.height - h - 24);
      path.moveTo(left, top + h);
      for (var x = 0.0; x < w; x += 5) {
        path
          ..lineTo(left + x + 6, top + pen.nextDouble() * 4)
          ..lineTo(left + x + 5, top + h - pen.nextDouble() * 4);
      }
    }
    return path;
  }

  Path _flecks(Size s, Random pen) {
    final path = Path();
    final count = (s.width * s.height / 4500).clamp(6, 40).round();
    for (var i = 0; i < count; i++) {
      final x = 8 + pen.nextDouble() * (s.width - 16);
      final y = 8 + pen.nextDouble() * (s.height - 16);
      final a = pen.nextDouble() * pi;
      final length = 1 + pen.nextDouble() * 2.5;
      path
        ..moveTo(x, y)
        ..lineTo(x + cos(a) * length, y + sin(a) * length);
    }
    return path;
  }

  @override
  bool operator ==(Object other) =>
      other is _TearShape &&
      other.seed == seed &&
      other.tear == tear &&
      other.tearBottom == tearBottom &&
      other.foldCorner == foldCorner;

  @override
  int get hashCode => Object.hash(seed, tear, tearBottom, foldCorner);
}

class _TornPaperPainter extends CustomPainter {
  _TornPaperPainter({required this.shape, required this.color, required this.foldColor});

  final _TearShape shape;
  final Color color;
  final Color foldColor;

  static Paint _pencil(double alpha, double width) => Paint()
    ..color = GuildColors.pencil.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final _hatchPaint = _pencil(0.34, 1);
  static final _smudgePaint = _pencil(0.07, 2.4);
  static final _fleckPaint = _pencil(0.4, 1.2);
  static final _loosePaint = _pencil(0.75, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final sheet = shape.sheet(size);
    final outline = sheet.outline;

    canvas.drawPath(
      outline.shift(const Offset(3, 4)),
      Paint()..color = GuildColors.shadow.withValues(alpha: 0.5),
    );
    canvas.drawPath(outline, Paint()..color = color);

    canvas.save();
    canvas.clipPath(outline);
    canvas.drawPath(sheet.smudge, _smudgePaint);
    canvas.drawPath(sheet.hatch, _hatchPaint);
    canvas.drawPath(sheet.flecks, _fleckPaint);
    canvas.restore();

    if (shape.foldCorner) {
      const f = _TearShape.fold;
      final fold = Path()
        ..moveTo(size.width - f, 0)
        ..lineTo(size.width - f, f)
        ..lineTo(size.width, f)
        ..close();
      canvas.drawPath(fold, Paint()..color = foldColor);
      canvas.drawPath(
        fold,
        Paint()
          ..color = GuildColors.pencil
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeJoin = StrokeJoin.round,
      );
    }

    canvas.drawPath(
      outline,
      Paint()
        ..color = GuildColors.pencil
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(sheet.loose, _loosePaint);
  }

  @override
  bool shouldRepaint(_TornPaperPainter old) =>
      old.shape != shape || old.color != color || old.foldColor != foldColor;
}
