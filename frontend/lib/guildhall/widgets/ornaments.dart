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
  const DashedLine({super.key, this.color = GuildColors.pencil, this.height = 1.5});

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
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = thickness,
    );
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color || old.thickness != thickness;
}

class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.color = GuildColors.pencil,
    this.circle = false,
    this.strokeWidth = 1.5,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final bool circle;
  final double strokeWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedBorderPainter(color, circle, strokeWidth),
        child: Padding(padding: padding, child: child),
      );
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter(this.color, this.circle, this.strokeWidth);
  final Color color;
  final bool circle;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2 + 1);
    final outline = circle
        ? (Path()..addOval(rect))
        : (Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4))));
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
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.circle != circle || old.strokeWidth != strokeWidth;
}

class GuildProgressBar extends StatelessWidget {
  const GuildProgressBar({
    super.key,
    required this.value,
    this.track = GuildColors.shadow,
    this.fill = GuildColors.gold,
    this.edge = GuildColors.chalkLine,
    this.animate = true,
  });

  const GuildProgressBar.onPaper({super.key, required this.value, this.animate = true})
      : track = GuildColors.parchmentDark,
        fill = GuildColors.brickDeep,
        edge = GuildColors.pencil;

  static const height = 8.0;

  final double value;
  final Color track;
  final Color fill;
  final Color edge;

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: track,
        border: Border.all(color: edge, width: 1),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1)),
          duration: !animate || MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: ColoredBox(color: fill),
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: i < done ? 1 : 0),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 1100),
                  builder: (context, t, _) => CustomPaint(painter: _SealDotPainter(t)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SealDotPainter extends CustomPainter {
  _SealDotPainter(this.risen);

  final double risen;

  static const _disc = Interval(0.35, 0.68, curve: Curves.easeOutCubic);
  static const _rays = Interval(0.6, 1, curve: Curves.easeOutCubic);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final disc = _disc.transform(risen);
    final rays = _rays.transform(risen);

    if (disc < 1) {
      canvas.drawCircle(c, r * 0.52, Sketch.pen(GuildColors.cream.withValues(alpha: 0.9 * (1 - disc)), 1.4));
    }
    if (disc > 0) {
      canvas.drawCircle(c, r * 0.52 * disc, Paint()..color = GuildColors.goldBright);
    }
    if (rays > 0) {
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4 + 0.2;
        final dir = Offset(cos(a), sin(a));
        final reach = r * (0.72 + 0.26 * rays);
        path
          ..moveTo(c.dx + dir.dx * r * 0.72, c.dy + dir.dy * r * 0.72)
          ..lineTo(c.dx + dir.dx * reach, c.dy + dir.dy * reach);
      }
      canvas.drawPath(path, Sketch.pen(GuildColors.goldBright.withValues(alpha: rays.clamp(0.0, 1.0)), 1.5));
    }
  }

  @override
  bool shouldRepaint(_SealDotPainter old) => old.risen != risen;
}

class RoundBadge extends StatelessWidget {
  const RoundBadge({
    super.key,
    this.asset,
    this.child,
    this.size = 44,
    this.color = GuildColors.brick,
  }) : assert(asset != null || child != null);

  final String? asset;
  final Widget? child;
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
        border: Border.all(color: GuildColors.cream, width: size >= 56 ? 2.2 : 1.8),
        boxShadow: const [BoxShadow(color: GuildShadow.color, offset: GuildShadow.box)],
      ),
      child: child != null ? Center(child: child) : Image.asset(asset!, fit: BoxFit.contain),
    );
  }
}

class JourneyEmblem extends StatelessWidget {
  const JourneyEmblem({super.key, required this.journey, required this.size});

  final Journey journey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(
        tag: 'journey-emblem-${journey.id}',
        child: Image.asset(journey.emblemAsset, width: size, height: size, fit: BoxFit.contain),
      ),
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
  locked(GuildColors.indigoLight, GuildColors.indigoDeep, GuildGlyph.lock, GuildColors.cream),

  claimed(GuildColors.goldBright, GuildColors.gold, GuildGlyph.check, GuildColors.ink);

  const SealKind(this.light, this.dark, this.glyph, this.mark);
  final Color light;
  final Color dark;
  final GuildGlyph glyph;
  final Color mark;
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
          child: GuildIcon(kind.glyph, size: size * 0.42, color: kind.mark),
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

    canvas.drawPath(path.shift(const Offset(2, 3)), Paint()..color = GuildColors.shadow.withValues(alpha: 0.45));
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
        ..color = GuildColors.shadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      c,
      r * 0.66,
      Paint()
        ..color = kind.mark.withValues(alpha: 0.45)
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
    const edge = BorderSide(color: GuildColors.shadow, width: 1.4);
    return Container(
      width: axis == Axis.vertical ? thickness : null,
      height: axis == Axis.horizontal ? thickness : null,
      decoration: BoxDecoration(
        color: GuildColors.indigo,
        border: axis == Axis.horizontal
            ? const Border(top: edge, bottom: edge)
            : const Border(left: edge, right: edge),
      ),
    );
  }
}

class InkStamp extends StatelessWidget {
  const InkStamp(this.label, {super.key, this.fontSize = GuildType.xs});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: GuildColors.brickDeep, width: 1.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label, style: GuildText.label(fontSize, color: GuildColors.brickDeep, spacing: 1.2)),
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
                    GuildColors.torchlight.withValues(alpha: 0.18),
                    GuildColors.torchlight.withValues(alpha: 0.07),
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
        ..strokeWidth = 1.7,
    );
    if (t <= 0) return;

    canvas.save();
    canvas.translate(size.width * 0.06, -size.height * 0.1);
    final full = checkPath(size * 1.02);
    final metric = full.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = GuildColors.brickDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InkCheckPainter old) => old.t != t || old.enabled != enabled;
}

class LetteredTitle extends StatelessWidget {
  const LetteredTitle(
    this.text, {
    super.key,
    required this.size,
    this.color = GuildColors.cream,
    this.textAlign = TextAlign.start,
    this.drawIn = false,
    this.onDrawn,
  });

  final String text;
  final double size;
  final Color color;
  final TextAlign textAlign;

  final bool drawIn;
  final VoidCallback? onDrawn;

  @override
  Widget build(BuildContext context) {
    final style = GuildText.title(size, color: color);
    final initial = text.characters.first;
    final Widget swash;
    if (!drawIn || MediaQuery.disableAnimationsOf(context)) {
      swash = CustomPaint(painter: _SwashPainter(color, 1));
    } else if (!Visibility.of(context)) {
      swash = CustomPaint(painter: _SwashPainter(color, 0));
    } else {
      swash = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: const Interval(0.3, 1, curve: Curves.easeInOutCubic),
        onEnd: onDrawn,
        builder: (context, t, _) => CustomPaint(painter: _SwashPainter(color, t)),
      );
    }
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: initial, style: TextStyle(fontSize: style.fontSize! * 1.5, height: 0.95)),
                TextSpan(text: text.substring(initial.length)),
              ],
            ),
            textAlign: textAlign,
            style: style,
          ),
          SizedBox(
            height: size * 0.24,
            child: ExcludeSemantics(child: swash),
          ),
        ],
      ),
    );
  }
}

class _SwashPainter extends CustomPainter {
  _SwashPainter(this.color, this.drawn);
  final Color color;

  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawn <= 0) return;
    if (drawn < 1) canvas.clipRect(Rect.fromLTWH(0, -size.height, size.width * drawn, size.height * 3));
    final from = Offset(size.width * 0.02, size.height * 0.85);
    final to = Offset(size.width * 0.99, size.height * 0.2);
    final bow = Offset(size.width * 0.45, size.height * 0.95);
    final weight = (size.height * 0.34).clamp(1.6, 3.4);
    final stroke = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(bow.dx, bow.dy - weight, to.dx, to.dy)
      ..quadraticBezierTo(bow.dx, bow.dy + weight, from.dx, from.dy)
      ..close();
    canvas.drawPath(stroke, Paint()..color = color.withValues(alpha: color.a * 0.9));
  }

  @override
  bool shouldRepaint(_SwashPainter old) => old.color != color || old.drawn != drawn;
}

class ChalkStar extends StatelessWidget {
  const ChalkStar({super.key, this.size = 15, this.seed = 0, this.color = GuildColors.chalk});

  final double size;
  final int seed;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _ChalkStarPainter(seed, color)));
}

class _ChalkStarPainter extends CustomPainter {
  _ChalkStarPainter(this.seed, this.color);
  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Random(seed * 17 + 3);
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final turn = (pen.nextDouble() - 0.5) * 0.7;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = turn + i * pi / 4;
      final reach = i.isEven ? r * (0.82 + pen.nextDouble() * 0.18) : r * 0.3;
      final p = c + Offset(cos(a), sin(a)) * reach;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ChalkStarPainter old) => old.seed != seed || old.color != color;
}

class RuledFrame extends StatelessWidget {
  const RuledFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = GuildColors.tan,
    this.outerWidth = 1.6,
    this.innerWidth = 1,
    this.gap = 3,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double outerWidth;
  final double innerWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(gap),
      decoration: BoxDecoration(border: Border.all(color: color, width: outerWidth)),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: color.a * 0.7), width: innerWidth)),
        child: child,
      ),
    );
  }
}

enum FastenerKind { tape, pin, nail }

class Fastener extends StatelessWidget {
  const Fastener({super.key, required this.kind});

  final FastenerKind kind;

  static const _shadow = [BoxShadow(color: GuildShadow.color, offset: GuildShadow.small)];

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case FastenerKind.tape:
        return Transform.rotate(
          angle: -0.06,
          child: Container(
            width: 62,
            height: 18,
            decoration: BoxDecoration(
              color: GuildColors.chalk.withValues(alpha: 0.82),
              border: Border.all(color: GuildColors.tan, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      case FastenerKind.pin:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GuildColors.brick,
            border: Border.all(color: GuildColors.brickDeep, width: 1),
            boxShadow: _shadow,
          ),
          alignment: const Alignment(-0.3, -0.3),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white54),
          ),
        );
      case FastenerKind.nail:
        return Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GuildColors.gold,
            border: Border.all(color: GuildColors.bronze, width: 1),
            boxShadow: _shadow,
          ),
        );
    }
  }
}

class BuddyPortrait extends StatelessWidget {
  const BuddyPortrait({super.key, this.width = 62, this.asset = GuildAssets.buddyWizard});

  final double width;
  final String asset;

  static const aspect = 457 / 683;

  @override
  Widget build(BuildContext context) {
    final height = width / aspect;
    Widget art([Color? tint]) => Image.asset(
          asset,
          width: width,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          color: tint,
          colorBlendMode: tint == null ? null : BlendMode.srcIn,
        );
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: GuildShadow.box.dx, top: GuildShadow.box.dy, child: art(GuildShadow.color)),
          art(),
        ],
      ),
    );
  }
}

class BuddyCameo extends StatelessWidget {
  const BuddyCameo({super.key, this.size = 32, this.asset = GuildAssets.buddyWizardFace});

  final double size;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: GuildColors.ink, width: 1.5),
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover, filterQuality: FilterQuality.medium),
        ),
      ),
    );
  }
}
