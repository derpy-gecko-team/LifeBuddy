import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/buddy_theme.dart';

/// What Pip is up to, which shows in how it holds itself.
enum PipMood {
  /// Lounging: slow tail, the odd blink, an ear flick now and then.
  idle,

  /// The hero is speaking: head cocked, ears pricked, tail still.
  listening,

  /// Working on an answer: the tail lashes.
  thinking,
}

/// Pip, alive: it breathes, blinks, swishes its tail and flicks an ear.
///
/// The cat is drawn in layers, each the full 334 x 242 drawing with only one
/// part on it (see `assets/images/buddy/svg/pip_*.svg`), so that the parts
/// can move on their own. All the motion follows from [time], so there is
/// nothing to start or stop: hold the clock and Pip holds still.
class PipCat extends StatelessWidget {
  const PipCat({super.key, required this.time, required this.s, this.mood = PipMood.idle});

  /// Seconds.
  final ValueListenable<double> time;

  /// The scale of the scene (see `HearthPage`).
  final double s;

  final PipMood mood;

  static const _width = 334.0;
  static const _height = 242.0;

  // Where each part hinges, in the drawing's own units.
  static const _tailRoot = Offset(290, 158);
  static const _leftEarRoot = Offset(68, 62);
  static const _rightEarRoot = Offset(152, 79);
  static const _neck = Offset(128, 150);
  static const _belly = Offset(202, 176);

  /// A steady pseudo-random number in 0..1.
  static double _chance(int n) {
    final x = sin(n * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
  }

  /// Whether something that happens once per [every] seconds, at a different
  /// moment each time and lasting [lasting], is happening now; and if so how
  /// far through it is (0..1). Otherwise -1.
  static double _now(double t, {required double every, required double lasting, required int salt}) {
    final turn = (t / every).floor();
    final start = _chance(turn * 7 + salt) * (every - lasting);
    final into = t - turn * every - start;
    return into >= 0 && into < lasting ? into / lasting : -1;
  }

  @override
  Widget build(BuildContext context) {
    Widget layer(String asset) => Image.asset(asset, width: _width * s, height: _height * s, gaplessPlayback: true);
    final tail = layer(BuddyAssets.pipTail);
    final body = layer(BuddyAssets.pipBody);
    final leftEar = layer(BuddyAssets.pipEarLeft);
    final rightEar = layer(BuddyAssets.pipEarRight);
    final head = layer(BuddyAssets.pipHead);
    final eyes = layer(BuddyAssets.pipEyes);
    final eyesShut = layer(BuddyAssets.pipEyesShut);
    final paws = layer(BuddyAssets.pipPaws);

    Widget hinged(Offset at, double angle, Widget child) =>
        Transform.rotate(angle: angle, origin: at * s - Offset(_width, _height) * s / 2, child: child);

    return Semantics(
      label: 'Pip, a black cat in a feathered cap',
      image: true,
      child: ExcludeSemantics(
        // The mood eases in and out rather than snapping.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: mood == PipMood.listening ? 1 : 0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, alert, _) => TweenAnimationBuilder<double>(
            tween: Tween(end: mood == PipMood.thinking ? 1 : 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, restless, _) => AnimatedBuilder(
              animation: time,
              builder: (context, _) {
                final t = time.value;
                final breath = sin(t * 1.5);

                // The tail: a lazy sway, a lash when thinking, held when listening.
                final sway = 0.075 * sin(t * 1.1) + 0.03 * sin(t * 2.3 + 1);
                final lash = 0.15 * sin(t * 4.4);
                final tailAngle = (sway * (1 - restless) + lash * restless) * (1 - 0.8 * alert);

                // A blink every few seconds, sometimes two in a row.
                final blink = _now(t, every: 4.3, lasting: 0.14, salt: 1);
                final again = _now(t - 0.3, every: 4.3, lasting: 0.12, salt: 1);
                final twice = _chance((t / 4.3).floor() * 3 + 5) > 0.7;
                final shut = blink >= 0 || (twice && again >= 0);

                // An ear flicks, as at a midge; the other one less often.
                double flick(double progress) => progress < 0 ? 0 : sin(progress * pi * 2) * (1 - progress);
                final rightFlick = flick(_now(t, every: 6.1, lasting: 0.45, salt: 11));
                final leftFlick = flick(_now(t, every: 9.7, lasting: 0.4, salt: 23));

                return SizedBox(
                  width: _width * s,
                  height: _height * s,
                  child: Stack(
                    children: [
                      hinged(_tailRoot, tailAngle, tail),
                      // Breathing: the back rises and falls from the ground up.
                      Transform(
                        transform: Matrix4.diagonal3Values(1, 1 + 0.016 * breath, 1),
                        origin: _belly * s,
                        child: body,
                      ),
                      // The head rides the breath, and cocks to one side to listen.
                      Transform.translate(
                        offset: Offset(0, -1.5 * breath * s),
                        child: hinged(
                          _neck,
                          -0.055 * alert,
                          Stack(
                            children: [
                              hinged(_leftEarRoot, -0.16 * leftFlick - 0.07 * alert, leftEar),
                              hinged(_rightEarRoot, 0.2 * rightFlick + 0.07 * alert, rightEar),
                              head,
                              Opacity(opacity: shut ? 0 : 1, child: eyes),
                              Opacity(opacity: shut ? 1 : 0, child: eyesShut),
                            ],
                          ),
                        ),
                      ),
                      paws,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
