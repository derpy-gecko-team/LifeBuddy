import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/guild_theme.dart';

void _smooth(Path path, List<Offset> points) {
  if (points.length < 2) return;
  path.moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length - 1; i++) {
    final mid = (points[i] + points[i + 1]) / 2;
    path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
  }
  path.lineTo(points.last.dx, points.last.dy);
}

double _inwardSign(Path source, PathMetric metric) {
  final probe = metric.getTangentForOffset(metric.length * 0.37);
  if (probe == null) return 1;
  final normal = Offset(-probe.vector.dy, probe.vector.dx);
  return source.contains(probe.position + normal * 2) ? 1 : -1;
}

Path traceByHand(
  Path source,
  Random pen, {
  double inset = 0,
  double wobble = 1.2,
  double step = 11,
  double lift = 0,
}) {
  final path = Path();
  for (final metric in source.computeMetrics()) {
    if (metric.length < step * 2) continue;
    final inward = _inwardSign(source, metric);
    final count = max(6, (metric.length / step).round());
    var run = <Offset>[];
    for (var i = 0; i <= count; i++) {
      final at = metric.isClosed ? (i % count) / count : i / count;
      final tangent = metric.getTangentForOffset(metric.length * at);
      if (tangent == null) continue;
      final normal = Offset(-tangent.vector.dy, tangent.vector.dx) * inward;
      final point = tangent.position +
          normal * (inset + (pen.nextDouble() - 0.5) * 2 * wobble) +
          tangent.vector * ((pen.nextDouble() - 0.5) * wobble);
      if (run.isNotEmpty && pen.nextDouble() < lift) {
        _smooth(path, run);
        run = <Offset>[];
      }
      run.add(point);
    }
    _smooth(path, run);
  }
  return path;
}

Path _roughEdges(List<Offset> points, Random pen, {required double wobble}) {
  final path = Path();
  for (var i = 0; i < points.length; i++) {
    final from = points[i];
    final to = points[(i + 1) % points.length];
    final delta = to - from;
    final length = delta.distance;
    if (length < 1) continue;
    final along = delta / length;
    final across = Offset(-along.dy, along.dx);
    final pieces = max(1, (length / 28).round());
    final run = <Offset>[from - along * (pen.nextDouble() * 1.6)];
    for (var k = 1; k < pieces; k++) {
      run.add(from + delta * (k / pieces) + across * ((pen.nextDouble() - 0.5) * 2 * wobble));
    }
    run.add(to + along * (pen.nextDouble() * 1.6));
    _smooth(path, run);
  }
  return path;
}

Path _edgeHatch(Path source, Random pen) {
  final path = Path();
  final bounds = source.getBounds();
  final scale = (bounds.shortestSide / 160).clamp(0.35, 1.0);
  const upLeft = -pi * 0.62;

  void stroke(Offset from, double angle, double length) {
    final a = angle + (pen.nextDouble() - 0.5) * 0.18;
    path
      ..moveTo(from.dx, from.dy)
      ..lineTo(from.dx + cos(a) * length, from.dy + sin(a) * length);
  }

  for (final metric in source.computeMetrics()) {
    final inward = _inwardSign(source, metric);
    final phase = pen.nextDouble() * 2 * pi;
    final waves = max(1, (metric.length / 260).round());
    for (var d = 0.0; d < metric.length; d += 4.5 + pen.nextDouble() * 2.5) {
      final tangent = metric.getTangentForOffset(d);
      if (tangent == null) continue;
      final outward = Offset(-tangent.vector.dy, tangent.vector.dx) * -inward;
      final shade = outward.dx * 0.5 + outward.dy * 0.87;
      if (shade < 0.3) continue;
      final swell = 0.55 + 0.45 * sin(d / metric.length * 2 * pi * waves + phase);
      stroke(tangent.position, upLeft, (4 + shade * swell * 22 + pen.nextDouble() * 5) * scale);
    }
  }

  for (var i = 0; i < 6; i++) {
    stroke(bounds.topLeft + Offset(5 + i * 5.0, 1), pi * 0.36, ((6 - i) * 3.4 + 3) * scale);
    stroke(bounds.topLeft + Offset(1, 6 + i * 5.0), -pi * 0.1, ((6 - i) * 2.8 + 3) * scale);
  }
  return path;
}

Path sketchFlecks(Rect bounds, Random pen, {double area = 5000, int least = 3, int most = 30, double inset = 6}) {
  final path = Path();
  final count = (bounds.width * bounds.height / area).clamp(least, most).round();
  for (var i = 0; i < count; i++) {
    final x = bounds.left + inset + pen.nextDouble() * max(1.0, bounds.width - inset * 2);
    final y = bounds.top + inset + pen.nextDouble() * max(1.0, bounds.height - inset * 2);
    final a = pen.nextDouble() * pi;
    final length = 1 + pen.nextDouble() * 2.5;
    path
      ..moveTo(x, y)
      ..lineTo(x + cos(a) * length, y + sin(a) * length);
  }
  return path;
}

class Sketch {
  Sketch._({
    required this.shape,
    required this.border,
    required this.echo,
    required this.loose,
    required this.hatch,
    required this.flecks,
  });

  factory Sketch.of(List<Offset> points, int seed) {
    final key = (seed, Object.hashAll(points));
    final cached = _cache[key];
    if (cached != null) return cached;
    if (_cache.length > 160) _cache.remove(_cache.keys.first);

    final pen = Random(seed * 53 + 11);
    final shape = Path()..addPolygon(points, true);
    return _cache[key] = Sketch._(
      shape: shape,
      border: _roughEdges(points, pen, wobble: 1.0),
      echo: _roughEdges(points, pen, wobble: 1.8),
      loose: traceByHand(shape, pen, inset: 4, wobble: 1.3, lift: 0.1),
      hatch: _edgeHatch(shape, pen),
      flecks: sketchFlecks(shape.getBounds(), pen),
    );
  }

  static final _cache = <(int, int), Sketch>{};

  final Path shape;
  final Path border;
  final Path echo;
  final Path loose;
  final Path hatch;
  final Path flecks;

  static List<Offset> box(Size size, {double inset = 0, double bevel = 0}) {
    final r = (Offset.zero & size).deflate(inset);
    if (bevel <= 0) return [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
    return [
      Offset(r.left + bevel, r.top),
      Offset(r.right - bevel, r.top),
      Offset(r.right, r.top + bevel),
      Offset(r.right, r.bottom - bevel),
      Offset(r.right - bevel, r.bottom),
      Offset(r.left + bevel, r.bottom),
      Offset(r.left, r.bottom - bevel),
      Offset(r.left, r.top + bevel),
    ];
  }

  static Paint pen(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static bool isDark(Color color) => color.computeLuminance() < 0.12;

  void paintFill(Canvas canvas, Color color, {Offset? shadow}) {
    if (shadow != null) {
      canvas.drawPath(shape.shift(shadow), Paint()..color = GuildColors.shadow.withValues(alpha: color.a * 0.5));
    }
    canvas.drawPath(shape, Paint()..color = color);
  }

  void paintShading(Canvas canvas, {Color ink = GuildColors.ink, double strength = 1}) {
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawPath(hatch, pen(ink.withValues(alpha: 0.22 * strength), 1.1));
    canvas.drawPath(flecks, pen(ink.withValues(alpha: 0.26 * strength), 1.3));
    canvas.drawPath(loose, pen(ink.withValues(alpha: 0.4 * strength), 1.1));
    canvas.restore();
  }

  void paintBorder(Canvas canvas, {Color color = GuildColors.pencil, double width = 1.8}) {
    canvas.drawPath(border, pen(color, width));
    canvas.drawPath(echo, pen(color.withValues(alpha: color.a * 0.75), 1.1));
  }
}

class SketchBox extends StatelessWidget {
  const SketchBox({
    super.key,
    required this.color,
    this.child,
    this.borderColor = GuildColors.pencil,
    this.borderWidth = 1.8,
    this.bevel = 0,
    this.shadow = GuildShadow.box,
    this.shading = true,
    this.seed = 1,
    this.padding = EdgeInsets.zero,
  });

  final Color color;
  final Widget? child;
  final Color borderColor;
  final double borderWidth;
  final double bevel;
  final Offset? shadow;
  final bool shading;
  final int seed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SketchBoxPainter(
        color: color,
        borderColor: borderColor,
        borderWidth: borderWidth,
        bevel: bevel,
        shadow: shadow,
        shading: shading,
        seed: seed,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SketchBoxPainter extends CustomPainter {
  _SketchBoxPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.bevel,
    required this.shadow,
    required this.shading,
    required this.seed,
  });

  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double bevel;
  final Offset? shadow;
  final bool shading;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final sketch = Sketch.of(Sketch.box(size, inset: borderWidth / 2, bevel: bevel), seed);
    final dark = Sketch.isDark(color);
    sketch.paintFill(canvas, color, shadow: shadow);
    if (shading) {
      sketch.paintShading(
        canvas,
        ink: dark ? GuildColors.cream : GuildColors.ink,
        strength: dark ? 0.55 : 1,
      );
    }
    sketch.paintBorder(canvas, color: borderColor, width: borderWidth);
  }

  @override
  bool shouldRepaint(_SketchBoxPainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.bevel != bevel ||
      old.shadow != shadow ||
      old.shading != shading ||
      old.seed != seed;
}
