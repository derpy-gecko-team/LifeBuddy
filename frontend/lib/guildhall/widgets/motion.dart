import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/guild_theme.dart';
import 'ornaments.dart';

/// Motion in the hall follows what things are made of: paper hangs from its
/// pin, pencil lines get drawn, wax and ink are stamped. Every piece here
/// stands still when the system asks for reduced motion.

/// Lands its child the way a stamp comes down: large and faint, then pressed
/// flat with a small rebound and a tap of haptics on contact.
class StampIn extends StatefulWidget {
  const StampIn({super.key, required this.child, required this.animate, this.delay = Duration.zero});

  final Widget child;

  /// Whether to play the landing when this is first shown. False shows the
  /// stamp already in place.
  final bool animate;
  final Duration delay;

  @override
  State<StampIn> createState() => _StampInState();
}

class _StampInState extends State<StampIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.animate ? 0 : 1,
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 2.6, end: 0.9).chain(CurveTween(curve: Curves.easeInCubic)), weight: 68),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 32),
  ]);

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
        return;
      }
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
      _c.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 285));
      if (mounted) HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c.drive(CurveTween(curve: const Interval(0, 0.3))),
      child: ScaleTransition(scale: _c.drive(_scale), child: widget.child),
    );
  }
}

/// Paper held to the wall by one fastener at its top edge. It rests at
/// [rest]; while [held] it hangs straight, and when let go it swings back
/// around the fastener and settles. Each time [nudges] changes it is set
/// swinging again, as when the paper has just been pinned back up.
class PinnedSwing extends StatefulWidget {
  const PinnedSwing({super.key, required this.rest, required this.held, required this.child, this.nudges = 0});

  /// Resting angle, in radians.
  final double rest;
  final bool held;
  final int nudges;
  final Widget child;

  @override
  State<PinnedSwing> createState() => _PinnedSwingState();
}

class _PinnedSwingState extends State<PinnedSwing> with SingleTickerProviderStateMixin {
  late final AnimationController _angle = AnimationController.unbounded(vsync: this, value: widget.rest);

  // Taken in the hand, the paper is steadied at once. Let go, it is light
  // and loose: a couple of swings before it is still.
  static final _steady = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: 0.85);
  static final _loose = SpringDescription.withDampingRatio(mass: 1, stiffness: 170, ratio: 0.3);

  // The push, in radians a second, that paper gets from being let go of.
  static const _push = 1.5;

  @override
  void didUpdateWidget(PinnedSwing old) {
    super.didUpdateWidget(old);
    final nudged = old.nudges != widget.nudges;
    if (!nudged && old.held == widget.held && old.rest == widget.rest) return;
    final target = widget.held ? 0.0 : widget.rest;
    if (MediaQuery.disableAnimationsOf(context)) {
      _angle.value = target;
      return;
    }
    // Let go or pinned back, the paper is thrown past where it rests and
    // swings there before it is still.
    final released = !widget.held && (nudged || old.held);
    final away = widget.rest < 0 ? -1.0 : 1.0;
    _angle.animateWith(
      SpringSimulation(
        widget.held ? _steady : _loose,
        _angle.value,
        target,
        released ? away * _push : _angle.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _angle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _angle,
      builder: (context, child) => Transform.rotate(
        angle: _angle.value,
        alignment: Alignment.topCenter,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Something hanging from a thread. Each time [nudged] turns true it sways
/// about the top of the thread and comes to rest.
class HangingSway extends StatefulWidget {
  const HangingSway({super.key, required this.nudged, required this.child, this.reach = 0.11});

  final bool nudged;
  final Widget child;

  /// How far the first swing goes, in radians.
  final double reach;

  @override
  State<HangingSway> createState() => _HangingSwayState();
}

class _HangingSwayState extends State<HangingSway> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 950), value: 1);

  @override
  void didUpdateWidget(HangingSway old) {
    super.didUpdateWidget(old);
    if (widget.nudged && !old.nudged && !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
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
        // A swing that dies away: two and a bit swings inside the duration.
        final angle = t >= 1 ? 0.0 : widget.reach * exp(-4.4 * t) * sin(t * 2 * pi * 2.2);
        return Transform.rotate(angle: angle, alignment: Alignment.topCenter, child: child);
      },
      child: widget.child,
    );
  }
}

/// Text that is crossed out by hand: when [struck] turns true a pencil line
/// is drawn through the words, one line of text after the next.
class StruckText extends StatelessWidget {
  const StruckText(this.text, {super.key, required this.style, required this.struck, this.lineColor});

  final String text;
  final TextStyle style;
  final bool struck;
  final Color? lineColor;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: struck ? 1 : 0),
      duration: reduced
          ? Duration.zero
          : struck
              ? const Duration(milliseconds: 460)
              : const Duration(milliseconds: 160),
      // The line starts once the tick beside it has been drawn.
      curve: struck ? const Interval(0.35, 1, curve: Curves.easeInOutCubic) : Curves.easeOut,
      builder: (context, t, child) => CustomPaint(
        foregroundPainter: _StrikePainter(
          text: text,
          style: resolved,
          textScaler: MediaQuery.textScalerOf(context),
          direction: Directionality.of(context),
          color: lineColor ?? style.color ?? GuildColors.inkSoft,
          progress: t,
        ),
        child: child,
      ),
      child: Text(text, style: style),
    );
  }
}

class _StrikePainter extends CustomPainter {
  _StrikePainter({
    required this.text,
    required this.style,
    required this.textScaler,
    required this.direction,
    required this.color,
    required this.progress,
  });

  final String text;
  final TextStyle style;
  final TextScaler textScaler;
  final TextDirection direction;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: textScaler,
    )..layout(maxWidth: size.width);
    final lines = painter.computeLineMetrics();
    painter.dispose();

    final fontSize = textScaler.scale(style.fontSize ?? 16);
    final total = lines.fold<double>(0, (sum, line) => sum + line.width);
    var remaining = total * progress;
    final pen = Random(text.hashCode);
    final stroke = Path();

    for (final line in lines) {
      if (remaining <= 0) break;
      final length = min(line.width, remaining);
      remaining -= line.width;
      final y = line.baseline - fontSize * 0.27;
      final from = line.left - 2;
      final to = line.left + length + (length >= line.width ? 3 : 0);
      stroke.moveTo(from, y + (pen.nextDouble() - 0.5) * 1.6);
      for (var x = from + 16; x < to; x += 16) {
        stroke.lineTo(x, y + (pen.nextDouble() - 0.5) * 1.6);
      }
      stroke.lineTo(to, y + (pen.nextDouble() - 0.5) * 1.6);
    }

    canvas.drawPath(
      stroke,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.6, fontSize * 0.08)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) =>
      old.progress != progress ||
      old.text != text ||
      old.style != style ||
      old.color != color ||
      old.textScaler != textScaler;
}

/// The seal on a quest. While [sealed] it shows what [builder] lays out,
/// intact; when the quest unlocks, the same pieces are driven from 0 to 1 so
/// the ribbon can part and the seal fall away, and then nothing is shown.
///
/// Goes inside a [Stack] and fills it, so [builder] may return [Positioned]
/// children placed against the card.
class SealBreak extends StatefulWidget {
  const SealBreak({super.key, required this.sealed, required this.builder});

  final bool sealed;
  final List<Widget> Function(Animation<double> breaking) builder;

  @override
  State<SealBreak> createState() => _SealBreakState();
}

class _SealBreakState extends State<SealBreak> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 760));

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(SealBreak old) {
    super.didUpdateWidget(old);
    if (old.sealed && !widget.sealed) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    } else if (!old.sealed && widget.sealed) {
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breaking = !widget.sealed && _c.value < 1 && _c.isAnimating;
    if (!widget.sealed && !breaking) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(clipBehavior: Clip.none, children: widget.builder(_c)),
      ),
    );
  }
}

/// The ribbon under a seal. As [breaking] runs, it comes apart at the middle
/// and each half is drawn back toward its own end.
class PartingRibbon extends StatelessWidget {
  const PartingRibbon({super.key, required this.breaking, this.axis = Axis.horizontal});

  final Animation<double> breaking;
  final Axis axis;

  static const _part = Interval(0.18, 0.8, curve: Curves.easeInOutCubic);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breaking,
      builder: (context, _) {
        final gone = _part.transform(breaking.value);
        final left = 1 - gone;
        final horizontal = axis == Axis.horizontal;
        Widget half(Alignment anchor) => Expanded(
              child: Opacity(
                opacity: (left * 2).clamp(0.0, 1.0),
                child: FractionallySizedBox(
                  alignment: anchor,
                  widthFactor: horizontal ? left : null,
                  heightFactor: horizontal ? null : left,
                  child: SealRibbon(axis: axis),
                ),
              ),
            );
        return Flex(
          direction: axis,
          children: [
            half(horizontal ? Alignment.centerLeft : Alignment.topCenter),
            half(horizontal ? Alignment.centerRight : Alignment.bottomCenter),
          ],
        );
      },
    );
  }
}

/// The wax seal itself. As [breaking] runs it is knocked loose, then drops
/// and tips over as it falls out of sight.
class FallingSeal extends StatelessWidget {
  const FallingSeal({super.key, required this.breaking, required this.size});

  final Animation<double> breaking;
  final double size;

  static const _knock = Interval(0, 0.22, curve: Curves.easeOut);
  static const _fall = Interval(0.22, 1, curve: Curves.easeInCubic);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breaking,
      builder: (context, child) {
        final t = breaking.value;
        final knock = _knock.transform(t);
        final fall = _fall.transform(t);
        return Opacity(
          opacity: (1 - fall * 1.15).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(fall * size * 0.25, fall * size * 1.2 - sin(knock * pi) * 3),
            child: Transform.rotate(
              angle: sin(knock * pi) * -0.12 + fall * 0.7,
              child: child,
            ),
          ),
        );
      },
      child: WaxSeal(size: size),
    );
  }
}
