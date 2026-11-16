import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/hearing_controller.dart';
import '../theme/buddy_theme.dart';

/// The way to speak to Pip: a gold coin, a speaking-horn struck on its face,
/// turning and glinting above the embers.
///
/// Tap it and it is tossed into the fire, which catches: while the flames are
/// up, Pip is listening. Tap the fire (or just stop talking) and what was
/// said is sent; the flames die back and a coin is there again.
///
/// The widget covers the foot of the scene, [height] units tall from the
/// bottom of the page, and draws the flames as well as the coin, since the
/// one sets off the other.
class SpeakCoin extends StatefulWidget {
  const SpeakCoin({
    super.key,
    required this.hearing,
    required this.time,
    required this.hush,
    required this.enabled,
    required this.s,
  });

  final HearingController hearing;

  /// Seconds; turns the coin and moves the flames.
  final ValueListenable<double> time;

  /// 0..1 as the writing scroll comes out. The coin steps back for it,
  /// unless it is the coin that called the scroll out.
  final Animation<double> hush;

  /// False while Pip is answering: one thing at a time.
  final bool enabled;

  /// The scale of the scene (see `HearthPage`).
  final double s;

  /// In the frame's units, measured up from the bottom of the page.
  static const height = 430.0;
  static const _heart = 150.0; // the middle of the fire in campfire.png
  static const _home = 226.0; // where the coin hangs
  static const _radius = 58.0;

  @override
  State<SpeakCoin> createState() => _SpeakCoinState();
}

class _SpeakCoinState extends State<SpeakCoin> with TickerProviderStateMixin {
  // The coin's flight into the fire.
  late final AnimationController _toss = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));

  // How high the fire burns: up when the coin lands, down when Pip stops listening.
  late final AnimationController _blaze = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 900),
  );

  // A coin arriving back in its place.
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    value: 1,
  );

  /// From the tap until a coin is back: the one that was there is in the fire.
  bool _tossed = false;

  // The hero's voice, as the fire feels it: the loudness the ears report,
  // eased so the flames swell and sink instead of twitching.
  final _voice = ValueNotifier<double>(0);
  double _lastTick = 0;

  void _breathe() {
    final now = widget.time.value;
    final dt = (now - _lastTick).clamp(0.0, 0.1);
    _lastTick = now;
    final target = _hearing.loudness.value;
    // Quick to rise with a word, slower to fall after it.
    final rate = target > _voice.value ? 14.0 : 5.0;
    final next = _voice.value + (target - _voice.value) * (1 - exp(-rate * dt));
    _voice.value = next < 0.002 ? 0 : next;
  }

  HearingController get _hearing => widget.hearing;

  @override
  void initState() {
    super.initState();
    _hearing.addListener(_settle);
    widget.time.addListener(_breathe);
    _toss.addStatusListener((status) {
      if (status == AnimationStatus.completed) _settle();
    });
  }

  @override
  void didUpdateWidget(SpeakCoin old) {
    super.didUpdateWidget(old);
    if (old.time != widget.time) {
      old.time.removeListener(_breathe);
      widget.time.addListener(_breathe);
    }
    if (old.hearing != widget.hearing) {
      old.hearing.removeListener(_settle);
      widget.hearing.addListener(_settle);
    }
  }

  @override
  void dispose() {
    _hearing.removeListener(_settle);
    widget.time.removeListener(_breathe);
    _voice.dispose();
    _toss.dispose();
    _blaze.dispose();
    _back.dispose();
    super.dispose();
  }

  void _throw() {
    if (!widget.enabled || _tossed || _hearing.active) return;
    HapticFeedback.selectionClick();
    setState(() => _tossed = true);
    final still = MediaQuery.disableAnimationsOf(context);
    _toss.duration = still ? Duration.zero : const Duration(milliseconds: 720);
    _toss.forward(from: 0);
    // The microphone wakes while the coin is in the air.
    _hearing.start();
  }

  /// Brings the fire and the coin in line with whether Pip is listening.
  /// Called when the coin lands and whenever the listening changes.
  void _settle() {
    if (!mounted) return;
    if (_toss.isAnimating) return; // decided on landing
    if (_hearing.active) {
      if (_tossed && _blaze.status == AnimationStatus.dismissed) {
        HapticFeedback.mediumImpact();
        _blaze.forward();
      }
    } else {
      if (_blaze.value > 0) _blaze.reverse();
      if (_tossed) {
        setState(() => _tossed = false);
        _toss.value = 0;
        _back.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AnimatedBuilder(
      animation: Listenable.merge([_hearing, widget.hush]),
      builder: (context, _) {
        final listening = _hearing.state == Hearing.listening;
        final busy = _tossed || _hearing.active;
        // Out of the way of the scroll when it is the hero writing.
        final present = busy ? 1.0 : 1 - widget.hush.value;
        final tag = switch (_hearing.state) {
          Hearing.idle => _tossed ? '' : 'Let’s talk!',
          Hearing.waking => 'One moment…',
          Hearing.listening => 'Tap the fire to send',
          Hearing.finishing => 'Got it',
        };

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final ground = constraints.maxHeight;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _CoinPainter(
                          time: widget.time,
                          toss: _toss,
                          blaze: _blaze,
                          back: _back,
                          voice: _voice,
                          tossed: _tossed,
                          present: present,
                          dim: widget.enabled ? 1 : 0.5,
                          s: s,
                        ),
                      ),
                    ),
                  ),
                ),
                // The fire: tap it to say "that is all".
                if (listening)
                  Positioned(
                    left: width / 2 - 110 * s,
                    width: 220 * s,
                    top: ground - (SpeakCoin._heart + 130) * s,
                    height: 190 * s,
                    child: Semantics(
                      button: true,
                      label: 'Listening. Tap the fire to send',
                      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _hearing.finish),
                    ),
                  ),
                // The coin: tap it to toss it in.
                if (!busy && present > 0.5)
                  Positioned(
                    left: width / 2 - (SpeakCoin._radius + 10) * s,
                    width: (SpeakCoin._radius + 10) * 2 * s,
                    top: ground - (SpeakCoin._home + SpeakCoin._radius + 10) * s,
                    height: (SpeakCoin._radius + 10) * 2 * s,
                    child: Semantics(
                      button: true,
                      enabled: widget.enabled,
                      label: 'Let’s talk. Toss the coin into the fire to speak',
                      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _throw),
                    ),
                  ),
                // Under the coin when it is there; down under the fire while it burns.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOutCubic,
                  left: 0,
                  right: 0,
                  top: ground - (busy ? 104 : SpeakCoin._home - SpeakCoin._radius - 12) * s,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: tag.isEmpty ? 0 : present * (widget.enabled ? 1 : 0.55),
                      child: Center(
                        child: _Tag(text: tag, s: s),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The few words under the coin, on a scrap of parchment.
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.s});

  final String text;
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14 * s, 5 * s, 14 * s, 6 * s),
      decoration: BoxDecoration(
        color: BuddyColors.card,
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(color: BuddyColors.outline, width: 2.5 * s),
        boxShadow: [BoxShadow(color: BuddyColors.outline, offset: Offset(0, 3 * s))],
      ),
      child: Text(text, style: BuddyText.serif(16 * s)),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter({
    required this.time,
    required this.toss,
    required this.blaze,
    required this.back,
    required this.voice,
    required this.tossed,
    required this.present,
    required this.dim,
    required this.s,
  }) : super(repaint: Listenable.merge([time, toss, blaze, back]));

  final ValueListenable<double> time;
  final Animation<double> toss;
  final Animation<double> blaze;
  final Animation<double> back;

  /// How loud the hero is speaking, 0..1, already eased.
  final ValueListenable<double> voice;
  final bool tossed;
  final double present;
  final double dim;
  final double s;

  static const _gold = Color(0xFFEBC25A);
  static const _goldLight = Color(0xFFF9E7A8);
  static const _goldDeep = Color(0xFFC99B3C);
  static const _goldDark = Color(0xFF9C7226);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final centre = size.width / 2;
    double up(double units) => size.height - units * s;
    final heart = Offset(centre, up(SpeakCoin._heart));

    _flames(canvas, heart, Curves.easeOutBack.transform(blaze.value).clamp(0.0, 1.2), blaze.value, t);

    if (tossed) {
      final p = toss.value;
      if (p >= 1) return; // in the fire
      // Up a little, then down into the heart of the fire, tumbling.
      final y = SpeakCoin._home + (SpeakCoin._heart - SpeakCoin._home) * p + 96 * sin(pi * p) * (1 - p * 0.6);
      final fade = p > 0.86 ? (1 - p) / 0.14 : 1.0;
      _coin(
        canvas,
        Offset(centre, up(y)),
        radius: SpeakCoin._radius * s * (1 - 0.34 * p),
        angle: p * pi * 7,
        shine: -1,
        opacity: fade,
        t: t,
      );
      return;
    }
    if (present <= 0) return;

    // At rest: one slow turn, then a while face-on, glinting, and round again.
    const turn = 4.6;
    final u = t % turn;
    final angle = u < 1.5 ? 2 * pi * Curves.easeInOutCubic.transform(u / 1.5) : 0.0;
    final shine = ((u - 2.0) / 0.9).clamp(-1.0, 2.0);
    // Arriving: drops into place with a spin and a small bounce.
    final arrive = Curves.easeOutBack.transform(back.value);
    final bob = sin(t * 1.7) * 3.5;
    _coin(
      canvas,
      Offset(centre, up(SpeakCoin._home + bob + 46 * (1 - back.value))),
      radius: SpeakCoin._radius * s * (0.4 + 0.6 * arrive),
      angle: angle + (1 - back.value) * pi * 4,
      shine: back.value < 1 ? -1 : shine,
      opacity: present * dim * back.value.clamp(0.0, 1.0),
      t: t,
    );
  }

  void _coin(
    Canvas canvas,
    Offset c, {
    required double radius,
    required double angle,
    required double shine,
    required double opacity,
    required double t,
  }) {
    if (opacity <= 0) return;
    final layered = opacity < 1;
    if (layered) {
      canvas.saveLayer(
        Rect.fromCircle(center: c, radius: radius * 2),
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
    }

    // A warm halo, so the gold reads as lit by the fire.
    canvas.drawCircle(
      c,
      radius * 1.7,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [_gold.withValues(alpha: 0.22), _gold.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: radius * 1.7)),
    );

    final cosA = cos(angle);
    final wide = cosA.abs().clamp(0.03, 1.0);
    final front = cosA >= 0;
    // The coin has thickness: the far face sits a little to one side.
    final lean = 4.2 * s * sin(angle) * (front ? 1 : -1);
    final outline = Paint()
      ..color = BuddyColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeJoin = StrokeJoin.round;

    Rect face(double dx) => Rect.fromCenter(center: c + Offset(dx, 0), width: radius * 2 * wide, height: radius * 2);
    final near = face(lean);
    final far = face(-lean);
    final edge = Path.combine(
      PathOperation.union,
      Path.combine(PathOperation.union, Path()..addOval(far), Path()..addOval(near)),
      Path()..addRect(
        Rect.fromLTRB(min(near.center.dx, far.center.dx), near.top, max(near.center.dx, far.center.dx), near.bottom),
      ),
    );
    canvas.drawPath(edge.shift(Offset(0, 3.5 * s)), Paint()..color = BuddyColors.outline);
    canvas.drawPath(edge, Paint()..color = _goldDark);
    canvas.drawPath(edge, outline);

    canvas.drawOval(near, Paint()..color = _gold);

    // Everything struck on the face, squashed with it as it turns.
    canvas.save();
    canvas.clipPath(Path()..addOval(near));
    canvas.translate(near.center.dx, near.center.dy);
    canvas.scale(wide, 1);
    final r = radius;
    // Light from the upper left.
    canvas.drawCircle(Offset(-r * 0.28, -r * 0.3), r * 0.92, Paint()..color = _goldLight.withValues(alpha: 0.35));
    canvas.drawCircle(Offset(r * 0.1, r * 0.12), r * 0.98, Paint()..color = _gold);
    canvas.drawCircle(
      Offset.zero,
      r * 0.8,
      Paint()
        ..color = _goldDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * s,
    );
    // Little beads round the rim.
    final bead = Paint()..color = _goldDeep;
    for (var i = 0; i < 16; i++) {
      final a = i * pi / 8;
      canvas.drawCircle(Offset(cos(a), sin(a)) * r * 0.9, 1.5 * s, bead);
    }
    if (front) {
      _horn(canvas, r);
    } else {
      _paw(canvas, r);
    }
    // A band of light crossing the face.
    if (shine > -1 && shine < 2) {
      canvas.rotate(-0.5);
      canvas.drawRect(
        Rect.fromCenter(center: Offset((shine * 2 - 1) * r * 1.5, 0), width: r * 0.42, height: r * 3),
        Paint()..color = Colors.white.withValues(alpha: 0.42),
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset((shine * 2 - 1) * r * 1.5 + r * 0.42, 0), width: r * 0.12, height: r * 3),
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }
    canvas.restore();
    canvas.drawOval(near, outline);

    // A star of light on the rim, coming and going.
    final glint = max(0.0, sin(t * 2.3 + 1));
    if (glint > 0 && wide > 0.5) {
      _sparkle(
        canvas,
        c + Offset(radius * 0.62, -radius * 0.66),
        radius * 0.3 * glint,
        Colors.white.withValues(alpha: glint),
      );
    }

    if (layered) canvas.restore();
  }

  /// The speaking-horn from the first button, struck into the gold: sunk
  /// shapes in a darker gold with a bright lip along their lower right.
  void _horn(Canvas canvas, double r) {
    // The drawing is about 100 x 54 around (50, 30); fit it to the coin.
    final k = r * 1.34 / 100;
    canvas.save();
    canvas.scale(k);
    canvas.translate(-51, -29);

    final cone = Path()
      ..moveTo(10, 30)
      ..quadraticBezierTo(36, 30, 66, 6)
      ..lineTo(66, 46)
      ..quadraticBezierTo(36, 34, 10, 38)
      ..close();
    final mouthpiece = Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, 29, 9, 10), const Radius.circular(2)));
    final bell = Path()..addOval(Rect.fromCenter(center: const Offset(66, 26), width: 18, height: 41));
    final strap = Path()
      ..moveTo(20, 40)
      ..quadraticBezierTo(38, 62, 58, 44);
    final sound = Path()
      ..moveTo(83, 15)
      ..quadraticBezierTo(90, 26, 83, 37)
      ..moveTo(92, 7)
      ..quadraticBezierTo(103, 26, 92, 45);

    Paint line(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The bright lip first, a touch down and right, then the sunk shape.
    const lip = Offset(1.4, 1.6);
    for (final shape in [cone, mouthpiece, bell]) {
      canvas.drawPath(shape.shift(lip), Paint()..color = _goldLight);
    }
    canvas.drawPath(strap.shift(lip), line(_goldLight, 4));
    canvas.drawPath(sound.shift(lip), line(_goldLight, 4.5));

    for (final shape in [cone, mouthpiece, bell]) {
      canvas.drawPath(shape, Paint()..color = _goldDeep);
      canvas.drawPath(shape, line(_goldDark, 2.4));
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(67.5, 26), width: 10, height: 28), Paint()..color = _goldDark);
    canvas.drawPath(
      Path()
        ..moveTo(25, 27.5)
        ..lineTo(25, 39.5)
        ..moveTo(45, 18.5)
        ..lineTo(45, 42),
      line(_goldDark, 2.2),
    );
    canvas.drawPath(strap, line(_goldDark, 3.4));
    canvas.drawPath(sound, line(_goldDark, 4));
    canvas.restore();
  }

  /// The other side: Pip's paw, as on the seal.
  void _paw(Canvas canvas, double r) {
    final sunk = Paint()..color = _goldDeep;
    final lip = Paint()..color = _goldLight;
    final shapes = <Rect>[
      Rect.fromCenter(center: Offset(0, r * 0.2), width: r * 0.62, height: r * 0.5),
      for (final (dx, dy) in [(-0.4, -0.12), (-0.14, -0.36), (0.14, -0.36), (0.4, -0.12)])
        Rect.fromCenter(center: Offset(r * dx, r * dy), width: r * 0.24, height: r * 0.28),
    ];
    for (final shape in shapes) {
      canvas.drawOval(shape.shift(Offset(1.2 * s, 1.4 * s)), lip);
      canvas.drawOval(shape, sunk);
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final w = r * 0.2;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
        ..close(),
      Paint()..color = color,
    );
  }

  static double _chance(int a, [int b = 0]) {
    final x = sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  // Where each tongue of flame stands, how wide and how tall, from the back
  // of the fire to its white-hot middle: (offset, width, height).
  static const _outer = [
    (-62.0, 44.0, 78.0),
    (-36.0, 56.0, 112.0),
    (-6.0, 70.0, 138.0),
    (26.0, 58.0, 120.0),
    (54.0, 46.0, 86.0),
    (4.0, 96.0, 96.0),
  ];
  static const _middle = [(-34.0, 40.0, 76.0), (-8.0, 52.0, 104.0), (20.0, 44.0, 88.0), (40.0, 30.0, 58.0)];
  static const _inner = [(-14.0, 30.0, 52.0), (4.0, 36.0, 70.0), (20.0, 24.0, 44.0)];

  /// The fire catching. [size] is how tall it stands (it overshoots as it
  /// catches); [heat] is the plain 0..1 behind it, for the light it throws.
  ///
  /// Built the way a fire looks rather than the way one is usually drawn:
  /// many tongues, each writhing in its own time, bright at the root and
  /// thinning to nothing at the tip, with scraps of flame tearing off the
  /// top, sparks streaking up and a little smoke above. No outlines and no
  /// blur: gradients and additive light only, which a phone draws quickly.
  void _flames(Canvas canvas, Offset heart, double size, double heat, double t) {
    if (heat <= 0) return;
    final base = heart + Offset(0, 16 * s);
    // The fire answers the voice: low and steady in a silence, leaping at a
    // raised voice.
    final loud = voice.value;
    size *= 0.7 + 0.55 * loud;
    heat *= 0.82 + 0.18 * loud;
    final tall = 150 * s * size;

    // The light it throws on the clearing, guttering.
    final gutter = 0.78 + 0.12 * sin(t * 7.1) + 0.06 * sin(t * 13.7 + 1) + 0.04 * sin(t * 23.3);
    final glow = Rect.fromCenter(center: heart - Offset(0, 46 * s), width: 460 * s, height: 360 * s);
    canvas.drawOval(
      glow,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF9A3C).withValues(alpha: 0.46 * heat * gutter),
            const Color(0xFFFF6A24).withValues(alpha: 0.15 * heat * gutter),
            const Color(0x00FF6A24),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(glow),
    );

    // Smoke, above everything and behind it.
    final smoke = Paint();
    for (var i = 0; i < 5; i++) {
      final age = (t / 3.2 + i / 5) % 1;
      smoke.color = const Color(0xFF9AA0BC).withValues(alpha: 0.075 * heat * sin(age * pi));
      canvas.drawCircle(
        base + Offset((sin(t * 0.7 + i * 2.2) * 16 + (i - 2) * 9) * s, -tall * 0.8 - age * 150 * s),
        (13 + 26 * age) * s,
        smoke,
      );
    }

    // One colour ramp per layer, root to tip, shared by all its tongues so
    // that where they overlap they read as one body of flame.
    final ramp = Rect.fromLTRB(base.dx - 100 * s, base.dy - tall, base.dx + 100 * s, base.dy + 14 * s);
    Paint layer(List<Color> colours, List<double> stops) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: colours,
        stops: stops,
      ).createShader(ramp);

    Path tongue((double, double, double) shape, int seed, double quickness) {
      final (dx, width, height) = shape;
      final a = seed * 1.7;
      // Height, lean and waist each on their own pair of rhythms.
      final lick = 0.8 + 0.14 * sin(t * quickness * 1.9 + a) + 0.08 * sin(t * quickness * 4.3 + a * 2.3);
      final h = height * s * size * lick;
      final w = width * s * (0.78 + 0.22 * heat);
      final lean = (sin(t * quickness + a) * 11 + sin(t * quickness * 2.6 + a * 1.3) * 6) * s;
      final waist = sin(t * quickness * 1.4 + a * 0.7) * w * 0.16;
      final x = base.dx + dx * s;
      final y = base.dy;
      return Path()
        ..moveTo(x - w / 2, y)
        ..cubicTo(x - w * 0.66, y - h * 0.3, x - w * 0.2 + waist, y - h * 0.62, x + lean, y - h)
        ..cubicTo(x + w * 0.24 + waist, y - h * 0.6, x + w * 0.66, y - h * 0.28, x + w / 2, y)
        ..quadraticBezierTo(x, y + 14 * s, x - w / 2, y)
        ..close();
    }

    final red = layer(
      [const Color(0xFFF07A26), const Color(0xFFE24A26), const Color(0xFFB8281C), const Color(0x00A02018)],
      const [0, 0.35, 0.72, 1],
    );
    for (var i = 0; i < _outer.length; i++) {
      canvas.drawPath(tongue(_outer[i], i, 3.1), red);
    }
    final orange = layer(
      [const Color(0xFFFFC24A), const Color(0xFFFF9A30), const Color(0xFFF2682A), const Color(0x00F2682A)],
      const [0, 0.3, 0.6, 0.86],
    );
    for (var i = 0; i < _middle.length; i++) {
      canvas.drawPath(tongue(_middle[i], i + 11, 3.9), orange);
    }
    final yellow = layer(
      [const Color(0xFFFFF6D0), const Color(0xFFFFE07A), const Color(0xFFFFB84A), const Color(0x00FFB84A)],
      const [0, 0.22, 0.44, 0.62],
    );
    for (var i = 0; i < _inner.length; i++) {
      canvas.drawPath(tongue(_inner[i], i + 23, 4.7), yellow);
    }

    // The white heat at the root.
    final additive = Paint()..blendMode = BlendMode.plus;
    final core = Rect.fromCenter(center: base - Offset(0, 12 * s), width: 150 * s, height: 62 * s);
    canvas.drawOval(
      core,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF0B8).withValues(alpha: 0.55 * heat * gutter),
            const Color(0x00FFC060),
          ],
        ).createShader(core),
    );

    // Scraps of flame that tear off the tips, rise and go out.
    for (var i = 0; i < 6; i++) {
      final life = 0.65 + 0.5 * _chance(i, 40);
      final age = (t + life * _chance(i, 41)) / life;
      final born = age.floor();
      final p = age - born;
      final from = base + Offset((_chance(i, born) - 0.5) * 90 * s, -tall * (0.5 + 0.3 * _chance(born, i)));
      final c = from + Offset(sin(p * 4 + i) * 7 * s, -p * 58 * s);
      final r = (9 - 7 * p) * s * heat;
      additive.color = const Color(0xFFFF8A30).withValues(alpha: 0.55 * (1 - p) * heat);
      canvas.drawOval(Rect.fromCenter(center: c, width: r * 1.1, height: r * 2.1), additive);
    }

    // Sparks: fast, bright, streaking the way they are going.
    final streak = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 20; i++) {
      final life = 0.8 + 1.1 * _chance(i, 50);
      final age = (t + life * _chance(i, 51)) / life;
      final born = age.floor();
      final p = age - born;
      final from = base + Offset((_chance(i, born + 3) - 0.5) * 80 * s, -20 * s);
      final rise = (130 + 190 * _chance(i + 7, born)) * s;
      final side = (_chance(i, born + 5) - 0.5) * 120 * s;
      Offset at(double q) => from + Offset(side * q + sin(q * 7 + i) * 9 * s, -rise * (1 - (1 - q) * (1 - q)));
      final fade = (p < 0.1 ? p / 0.1 : 1 - p) * heat;
      streak
        ..color = Color.lerp(const Color(0xFFFFE08A), const Color(0xFFFF6A2A), p)!.withValues(alpha: 0.95 * fade)
        ..strokeWidth = (2.2 - 1.2 * p) * s;
      canvas.drawLine(at(max(0, p - 0.035)), at(p), streak);
    }
  }

  @override
  bool shouldRepaint(_CoinPainter old) =>
      old.tossed != tossed || old.present != present || old.dim != dim || old.s != s || old.time != time;
}
