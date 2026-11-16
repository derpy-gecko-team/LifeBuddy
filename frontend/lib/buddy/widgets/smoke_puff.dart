import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../guildhall/theme/guild_theme.dart' show stableSeed;
import '../../guildhall/widgets/pressable.dart';
import '../data/models.dart';
import '../theme/buddy_theme.dart';

/// An old message, up in the sky: words held in a puff of campfire smoke.
///
/// The puff hangs where it is and bobs a little; its edge is a ring of
/// billows that swell and sink, so it never holds one outline for long.
class SmokePuff extends StatelessWidget {
  const SmokePuff({
    super.key,
    required this.message,
    required this.time,
    required this.s,
    this.onOpenGuildHall,
    this.onOpenMap,
  });

  final ChatMessage message;

  /// Seconds; drives the bobbing and the billows.
  final ValueListenable<double> time;

  /// The scale of the scene (see `HearthPage`).
  final double s;

  final VoidCallback? onOpenGuildHall;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final mine = !message.fromBuddy;
    final seed = stableSeed(message.id);
    final tile = message.newMapTile;
    final words = BuddyText.hand(19 * s, color: BuddyColors.cream, height: 1.28);
    final small = BuddyText.hand(
      15 * s,
      color: mine ? BuddyColors.smokeRimCool : BuddyColors.smokeRimWarm,
      height: 1.2,
    );

    Widget link(String label, VoidCallback? onTap) => Semantics(
      button: onTap != null,
      child: GuildPressable(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(top: 6 * s),
          child: Text(
            label,
            style: small.copyWith(decoration: TextDecoration.underline, decorationColor: small.color),
          ),
        ),
      ),
    );

    final puff = RepaintBoundary(
      child: CustomPaint(
        painter: _SmokePainter(
          time: time,
          seed: seed,
          s: s,
          body: mine ? BuddyColors.smokeCool : BuddyColors.smokeWarm,
          rim: mine ? BuddyColors.smokeRimCool : BuddyColors.smokeRimWarm,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22 * s, 16 * s, 22 * s, 18 * s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine) ...[
                Text(
                  'PIP',
                  style: BuddyText.serif(12 * s, color: BuddyColors.smokeRimWarm, spacing: 1.4 * s),
                ),
                SizedBox(height: 4 * s),
              ],
              Text(message.text, style: words),
              for (final quest in message.updatedQuests) link('On the board: ${quest.title}', onOpenGuildHall),
              if (tile != null) link('New on your map: a ${tile.typeLabel} tile', onOpenMap),
              if (message.status == DeliveryStatus.failed)
                Padding(
                  padding: EdgeInsets.only(top: 6 * s),
                  child: Text('Lost on the wind', style: small),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: mine ? 'You said' : 'Pip said',
      child: Padding(
        // Room around the puff for the billows and the bobbing.
        padding: EdgeInsets.symmetric(vertical: 24 * s, horizontal: 28 * s),
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300 * s),
            child: MediaQuery.disableAnimationsOf(context)
                ? puff
                : AnimatedBuilder(
                    animation: time,
                    builder: (context, child) {
                      final t = time.value;
                      final phase = seed % 628 / 100;
                      return Transform.translate(
                        offset: Offset(sin(t * 0.45 + phase) * 5 * s, cos(t * 0.6 + phase * 1.7) * 6 * s),
                        child: child,
                      );
                    },
                    child: puff,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SmokePainter extends CustomPainter {
  _SmokePainter({required this.time, required this.seed, required this.s, required this.body, required this.rim})
    : super(repaint: time);

  final ValueListenable<double> time;
  final int seed;
  final double s;
  final Color body;
  final Color rim;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final random = Random(seed);
    final inset = 10 * s;
    final core = RRect.fromRectAndRadius((Offset.zero & size).deflate(inset), Radius.circular(22 * s));

    // Billows all the way round the edge, each swelling at its own pace.
    final billows = <(Offset, double)>[];
    void along(Offset from, Offset to) {
      final count = max(1, ((to - from).distance / (22 * s)).round());
      for (var i = 0; i < count; i++) {
        final phase = random.nextDouble() * 6.28;
        final pace = 0.35 + random.nextDouble() * 0.5;
        final swell = sin(t * pace + phase);
        final centre = Offset.lerp(from, to, (i + 0.5) / count)! + Offset(cos(t * pace * 0.7 + phase), swell) * 2.5 * s;
        billows.add((centre, (17 + random.nextDouble() * 7 + swell * 4) * s));
      }
    }

    final r = core.outerRect;
    along(r.topLeft, r.topRight);
    along(r.topRight, r.bottomRight);
    along(r.bottomRight, r.bottomLeft);
    along(r.bottomLeft, r.topLeft);

    // Twice over: once a little larger in the pale rim colour, once in the
    // body colour on top. What shows of the first is a soft, moving outline.
    final edge = 2.2 * s;
    final rimPaint = Paint()..color = rim;
    for (final (centre, radius) in billows) {
      canvas.drawCircle(centre, radius + edge, rimPaint);
    }
    final bodyPaint = Paint()..color = body;
    for (final (centre, radius) in billows) {
      canvas.drawCircle(centre, radius, bodyPaint);
    }
    canvas.drawRRect(core, bodyPaint);

    // A wisp or two coming away from the top.
    final wisp = Paint()..color = rim.withValues(alpha: 0.55);
    for (var i = 0; i < 2; i++) {
      final phase = random.nextDouble() * 6.28;
      final rise = (t * 0.12 + phase) % 1;
      final x = size.width * (0.25 + 0.5 * random.nextDouble()) + sin(t * 0.5 + phase) * 6 * s;
      wisp.color = rim.withValues(alpha: 0.5 * (1 - rise));
      canvas.drawCircle(Offset(x, -rise * 20 * s), (5 - rise * 3) * s, wisp);
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) => old.seed != seed || old.s != s || old.body != body || old.rim != rim;
}
