import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../theme/buddy_theme.dart';

/// The two moments worth a little ceremony at the fire.
///
/// A quest fulfilled: gold flies up out of the flames, with what it was
/// worth. A quest posted: a notice is written, held up for a beat, and sent
/// off towards the Guild Hall's tab, so the hero sees where it went.
///
/// Both are drawn over the whole scene and play once, on [cheer] and
/// [arrival] going from 0 to 1.
class QuestMoments extends StatelessWidget {
  const QuestMoments({
    super.key,
    required this.cheer,
    required this.arrival,
    required this.s,
    required this.frameTop,
    this.fulfilled,
    this.reward,
    this.posted,
  });

  /// 0..1 over the reward for a fulfilled quest.
  final Animation<double> cheer;

  /// 0..1 over a new quest's notice appearing and leaving for the board.
  final Animation<double> arrival;

  /// The scale of the scene (see `HearthPage`).
  final double s;

  /// Where the frame's y = 0 falls on the screen.
  final double frameTop;

  /// The quest just fulfilled, and its bounty if known.
  final String? fulfilled;
  final int? reward;

  /// The quest just posted.
  final String? posted;

  /// The middle of the fire, in the frame's units up from the page's foot.
  static const _heart = 150.0;

  /// Where the Guild Hall's tab sits along the tab bar: second of four.
  static const guildHallTab = 0.375;

  /// How far through [arrival] the notice reaches the tab bar.
  static const landsAt = 0.9;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final heart = Offset(size.width / 2, size.height - _heart * s);
        final frameLeft = (size.width - 393 * s) / 2;
        // The notice appears just under Pip's card, below where the quest is
        // named, so that it does not cover what Pip is saying.
        final pinned = Offset(frameLeft + 70 * s, frameTop + 470 * s);
        final tab = Offset(size.width * guildHallTab, size.height + 34 * s);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _MomentsPainter(
                    cheer: cheer,
                    arrival: arrival,
                    heart: heart,
                    pinned: pinned,
                    tab: tab,
                    s: s,
                  ),
                ),
              ),
            ),
            // "Quest fulfilled! +40 XP", rising out of the fire.
            AnimatedBuilder(
              animation: cheer,
              builder: (context, child) {
                final p = cheer.value;
                if (p <= 0 || p >= 1) return const SizedBox.shrink();
                final pop = Curves.easeOutBack.transform((p / 0.18).clamp(0.0, 1.0));
                final fade = p > 0.8 ? (1 - p) / 0.2 : 1.0;
                return Positioned(
                  left: 0,
                  right: 0,
                  top: heart.dy - (118 + 54 * Curves.easeOutCubic.transform(p)) * s,
                  child: Opacity(
                    opacity: fade,
                    child: Transform.scale(scale: 0.5 + 0.5 * pop, child: child),
                  ),
                );
              },
              child: Center(
                child: _Banner(
                  s: s,
                  title: 'Quest fulfilled!',
                  detail: reward == null ? null : '+$reward XP',
                  colour: const Color(0xFFEBC25A),
                ),
              ),
            ),
            // "New quest!", beside the notice while it is held up.
            AnimatedBuilder(
              animation: arrival,
              builder: (context, child) {
                final p = arrival.value;
                if (p <= 0.04 || p >= 0.62) return const SizedBox.shrink();
                final pop = Curves.easeOutBack.transform(((p - 0.04) / 0.14).clamp(0.0, 1.0));
                final fade = p > 0.5 ? (0.62 - p) / 0.12 : 1.0;
                return Positioned(
                  left: pinned.dx + 34 * s,
                  top: pinned.dy - 30 * s,
                  child: Opacity(
                    opacity: fade,
                    child: Transform.scale(scale: 0.5 + 0.5 * pop, alignment: Alignment.centerLeft, child: child),
                  ),
                );
              },
              child: _Banner(s: s, title: 'New quest!', colour: BuddyColors.card),
            ),
          ],
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.s, required this.title, required this.colour, this.detail});

  final double s;
  final String title;
  final String? detail;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16 * s, 7 * s, 16 * s, 8 * s),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: BuddyColors.outline, width: 3 * s),
        boxShadow: [BoxShadow(color: BuddyColors.outline, offset: Offset(0, 4 * s))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: BuddyText.serif(19 * s)),
          if (detail != null) ...[
            SizedBox(width: 10 * s),
            Text(detail!, style: BuddyText.serif(19 * s, color: BuddyColors.name)),
          ],
        ],
      ),
    );
  }
}

class _MomentsPainter extends CustomPainter {
  _MomentsPainter({
    required this.cheer,
    required this.arrival,
    required this.heart,
    required this.pinned,
    required this.tab,
    required this.s,
  }) : super(repaint: Listenable.merge([cheer, arrival]));

  final Animation<double> cheer;
  final Animation<double> arrival;
  final Offset heart;
  final Offset pinned;
  final Offset tab;
  final double s;

  static double _chance(int a, [int b = 0]) {
    final x = sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cheer.value > 0 && cheer.value < 1) _reward(canvas, cheer.value);
    if (arrival.value > 0 && arrival.value < 1) _notice(canvas, arrival.value);
  }

  /// Gold out of the fire: a fountain of coins, each on its own arc, and
  /// stars of light among them.
  void _reward(Canvas canvas, double p) {
    const seconds = 2.4;
    final t = p * seconds;

    // The flash as it goes up.
    final flash = (1 - p / 0.35).clamp(0.0, 1.0);
    if (flash > 0) {
      final glow = Rect.fromCircle(center: heart - Offset(0, 30 * s), radius: 230 * s);
      canvas.drawOval(
        glow,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE08A).withValues(alpha: 0.5 * flash),
              const Color(0x00FFC040),
            ],
          ).createShader(glow),
      );
    }

    final outline = Paint()
      ..color = BuddyColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s;
    for (var i = 0; i < 16; i++) {
      // Thrown up and out, then gravity has it.
      final late = 0.22 * _chance(i, 1);
      final age = t - late;
      if (age <= 0) continue;
      final vx = (_chance(i, 2) - 0.5) * 330 * s;
      final vy = -(430 + 260 * _chance(i, 3)) * s;
      final at = heart + Offset(vx * age, vy * age + 520 * s * age * age);
      final fade = ((seconds - 0.25 - t) / 0.5).clamp(0.0, 1.0);
      if (fade <= 0) continue;
      final r = (6.5 + 3 * _chance(i, 4)) * s;
      final wide = cos(age * (7 + 5 * _chance(i, 5)) + i).abs().clamp(0.12, 1.0);
      final coin = Rect.fromCenter(center: at, width: r * 2 * wide, height: r * 2);
      canvas.drawOval(coin, Paint()..color = const Color(0xFFEBC25A).withValues(alpha: fade));
      canvas.drawOval(coin.deflate(r * 0.32), Paint()..color = const Color(0xFFF9E7A8).withValues(alpha: 0.7 * fade));
      canvas.drawOval(coin, outline..color = BuddyColors.outline.withValues(alpha: fade));
    }

    final star = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 12; i++) {
      final born = 0.9 * _chance(i, 11);
      final age = (t - born) / 0.7;
      if (age <= 0 || age >= 1) continue;
      final at = heart + Offset((_chance(i, 12) - 0.5) * 300 * s, -(40 + 230 * _chance(i, 13)) * s);
      star.color = Colors.white.withValues(alpha: sin(age * pi));
      _sparkle(canvas, at, (5 + 8 * _chance(i, 14)) * s * sin(age * pi), star);
    }
  }

  /// A new quest's notice: it pops up where the quest was named, is held up
  /// a moment, then flutters off to the Guild Hall's tab.
  void _notice(Canvas canvas, double p) {
    const held = 0.5;
    final Offset at;
    final double scale;
    final double turn;
    if (p < held) {
      scale = Curves.easeOutBack.transform((p / 0.16).clamp(0.0, 1.0));
      at = pinned - Offset(0, 8 * s * sin(p / held * pi));
      turn = -0.14 + 0.06 * sin(p * 26);
    } else {
      final q = Curves.easeInCubic.transform(((p - held) / (QuestMoments.landsAt - held)).clamp(0.0, 1.0));
      // Up and over, then down to the tab.
      final over = Offset(lerpDouble(pinned.dx, tab.dx, 0.3)! - 30 * s, pinned.dy - 90 * s);
      at = Offset.lerp(Offset.lerp(pinned, over, q), Offset.lerp(over, tab, q), q)!;
      scale = 1 - 0.5 * q;
      turn = -0.14 - 1.2 * q;
    }
    if (scale <= 0) return;

    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(turn);
    canvas.scale(scale);
    final sheet = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 44 * s, height: 54 * s),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(sheet.shift(Offset(0, 4 * s)), Paint()..color = BuddyColors.outline);
    canvas.drawRRect(sheet, Paint()..color = BuddyColors.cardLight);
    canvas.drawRRect(
      sheet,
      Paint()
        ..color = BuddyColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s,
    );
    // A few lines of writing, and the pin it will hang from.
    final ink = Paint()
      ..color = BuddyColors.inkFaded
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round;
    for (final (y, w) in [(-6.0, 26.0), (3.0, 22.0), (12.0, 26.0), (20.0, 14.0)]) {
      canvas.drawLine(Offset(-13 * s, y * s), Offset((-13 + w) * s, y * s), ink);
    }
    canvas.drawCircle(Offset(0, -19 * s), 5.5 * s, Paint()..color = BuddyColors.name);
    canvas.drawCircle(
      Offset(0, -19 * s),
      5.5 * s,
      Paint()
        ..color = BuddyColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s,
    );
    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset c, double r, Paint paint) {
    if (r <= 0) return;
    final w = r * 0.2;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MomentsPainter old) => old.heart != heart || old.pinned != pinned || old.tab != tab || old.s != s;
}
