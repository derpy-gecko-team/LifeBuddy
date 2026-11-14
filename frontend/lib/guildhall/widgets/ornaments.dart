import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import 'guild_icons.dart';
import 'sketch.dart';

void drawDashedPath(Canvas canvas, Path path, Paint paint, {double dash = 6, double gap = 5}) {
  final pen = Random(41);
  final dashed = Path();
  for (final PathMetric metric in path.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      final length = dash * (0.7 + pen.nextDouble() * 0.6);
      dashed.addPath(
        metric.extractPath(d, min(d + length, metric.length)),
        Offset((pen.nextDouble() - 0.5) * 1.2, (pen.nextDouble() - 0.5) * 1.2),
      );
      d += length + gap * (0.7 + pen.nextDouble() * 0.6);
    }
  }
  canvas.drawPath(
    dashed,
    Paint.from(paint)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round,
  );
}

class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.color = GuildColors.inkSoft, this.height = 1.5});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _DashedLinePainter(color, height)),
      );
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color, this.thickness);
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);
    drawDashedPath(
      canvas,
      path,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = thickness,
    );
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.color = GuildColors.inkSoft,
    this.circle = false,
    this.radius = 4,
    this.strokeWidth = 1.5,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final bool circle;
  final double radius;
  final double strokeWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedBorderPainter(color, circle, radius, strokeWidth),
        child: Padding(padding: padding, child: child),
      );
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter(this.color, this.circle, this.radius, this.strokeWidth);
  final Color color;
  final bool circle;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2 + 1);
    final outline = circle
        ? (Path()..addOval(rect))
        : (Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))));
    final path = traceByHand(outline, Random(size.width.round() * 31 + size.height.round()), wobble: 0.8, step: 9);
    drawDashedPath(
      canvas,
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

class GuildProgressBar extends StatelessWidget {
  const GuildProgressBar({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: GuildColors.ink,
        border: Border.all(color: GuildColors.shadow, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1)),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: const ColoredBox(color: GuildColors.gold),
          ),
        ),
      ),
    );
  }
}

class SealProgress extends StatelessWidget {
  const SealProgress({super.key, required this.total, required this.done, this.size = 18});

  final int total;
  final int done;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (total > 10) {
      return GuildProgressBar(value: total == 0 ? 0 : done / total);
    }
    return Semantics(
      label: '$done of $total quests fulfilled',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var i = 0; i < total; i++)
              SizedBox.square(
                dimension: size,
                child: CustomPaint(painter: _SealDotPainter(filled: i < done)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SealDotPainter extends CustomPainter {
  _SealDotPainter({required this.filled});
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1.5;
    if (filled) {
      canvas.drawCircle(c + const Offset(1, 1.5), r, Paint()..color = GuildColors.shadow);
      canvas.drawCircle(c, r, Paint()..color = GuildColors.gold);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = GuildColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final inset = size.width * 0.26;
      canvas.save();
      canvas.translate(inset, inset);
      canvas.drawPath(
        checkPath(Size.square(size.width - inset * 2)),
        Paint()
          ..color = GuildColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(c, r, Paint()..color = GuildColors.shadow.withValues(alpha: 0.45));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = GuildColors.cream.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_SealDotPainter old) => old.filled != filled;
}

class RoundBadge extends StatelessWidget {
  const RoundBadge({
    super.key,
    required this.asset,
    this.size = 44,
    this.color = GuildColors.crimsonLight,
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: GuildColors.ink, width: size >= 56 ? 3 : 2.5),
        boxShadow: const [BoxShadow(color: GuildColors.shadow, offset: Offset(2, 3))],
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class PerilSkulls extends StatelessWidget {
  const PerilSkulls({super.key, required this.peril, this.size = 18});

  final Peril peril;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Peril: ${peril.label}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < Peril.values.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Image.asset(
                  GuildAssets.iconSkull,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  opacity: AlwaysStoppedAnimation(i < peril.skulls ? 1 : 0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum SealKind {
  locked(GuildColors.verdigrisLight, GuildColors.verdigrisDark, GuildGlyph.lock),

  claimed(GuildColors.goldBright, GuildColors.gold, GuildGlyph.check);

  const SealKind(this.light, this.dark, this.glyph);
  final Color light;
  final Color dark;
  final GuildGlyph glyph;
}

class WaxSeal extends StatelessWidget {
  const WaxSeal({super.key, this.size = 56, this.kind = SealKind.locked});

  final double size;
  final SealKind kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _WaxSealPainter(kind),
        child: Center(
          child: GuildIcon(kind.glyph, size: size * 0.42, color: GuildColors.ink),
        ),
      ),
    );
  }
}

class _WaxSealPainter extends CustomPainter {
  _WaxSealPainter(this.kind);
  final SealKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    const bumps = 11;
    final path = Path();
    for (var i = 0; i <= bumps * 8; i++) {
      final a = i / (bumps * 8) * 2 * pi;
      final rr = r * (0.93 + 0.07 * sin(a * bumps));
      final p = c + Offset(cos(a) * rr, sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(path.shift(const Offset(2, 3)), Paint()..color = GuildColors.shadow);
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [kind.light, kind.dark],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = GuildColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      c,
      r * 0.66,
      Paint()
        ..color = GuildColors.ink.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_WaxSealPainter old) => old.kind != kind;
}

class SealRibbon extends StatelessWidget {
  const SealRibbon({super.key, this.axis = Axis.horizontal, this.thickness = 14});

  final Axis axis;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    const edge = BorderSide(color: GuildColors.ink, width: 2);
    return Container(
      width: axis == Axis.vertical ? thickness : null,
      height: axis == Axis.horizontal ? thickness : null,
      decoration: BoxDecoration(
        color: GuildColors.verdigris,
        border: axis == Axis.horizontal
            ? const Border(top: edge, bottom: edge)
            : const Border(left: edge, right: edge),
      ),
    );
  }
}

class FulfilledStamp extends StatelessWidget {
  const FulfilledStamp({super.key, this.fontSize = GuildType.xs});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: GuildColors.bronze, width: 2),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text('Fulfilled', style: GuildText.label(fontSize, color: GuildColors.bronze, spacing: 1.2)),
      ),
    );
  }
}

class GuildArt extends StatelessWidget {
  const GuildArt(this.asset, {super.key, required this.height});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: Image.asset(asset, height: height, fit: BoxFit.contain));
  }
}

class TorchGlow extends StatefulWidget {
  const TorchGlow({super.key, this.size = 460});

  final double size;

  @override
  State<TorchGlow> createState() => _TorchGlowState();
}

class _TorchGlowState extends State<TorchGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late final Animation<double> _opacity = _controller.drive(_FlickerTween());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: FadeTransition(
          opacity: _opacity,
          child: SizedBox.square(
            dimension: widget.size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    GuildColors.torchlight.withValues(alpha: 0.26),
                    GuildColors.torchlight.withValues(alpha: 0.10),
                    GuildColors.torchlight.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlickerTween extends Animatable<double> {
  @override
  double transform(double t) {
    final a = 2 * pi * t;
    final wobble = sin(a * 2) * 0.5 + sin(a * 5) * 0.3 + sin(a * 11) * 0.2;
    return 0.84 + 0.16 * wobble;
  }
}

class InkCheckbox extends StatelessWidget {
  const InkCheckbox({super.key, required this.checked, this.enabled = true, this.size = 28});

  final bool checked;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: checked ? 1 : 0),
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : GuildMotion.quick,
      curve: Curves.easeOut,
      builder: (context, t, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _InkCheckPainter(t, enabled)),
      ),
    );
  }
}

class _InkCheckPainter extends CustomPainter {
  _InkCheckPainter(this.t, this.enabled);
  final double t;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius((Offset.zero & size).deflate(1.5), const Radius.circular(3));
    if (t > 0) {
      canvas.drawRRect(box, Paint()..color = GuildColors.parchmentDark.withValues(alpha: 0.7 * t));
    }
    canvas.drawRRect(
      box,
      Paint()
        ..color = enabled || t > 0 ? GuildColors.ink : GuildColors.inkSoft.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (t <= 0) return;

    canvas.save();
    canvas.translate(size.width * 0.06, -size.height * 0.1);
    final full = checkPath(size * 1.02);
    final metric = full.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = GuildColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InkCheckPainter old) => old.t != t || old.enabled != enabled;
}
