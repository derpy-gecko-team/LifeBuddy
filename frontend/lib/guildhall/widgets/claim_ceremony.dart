import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../theme/guild_assets.dart';
import '../theme/guild_theme.dart';
import 'board_header.dart' show toRoman;
import 'ornaments.dart';
import 'wood_sign.dart';

void playClaimCeremony(
  BuildContext context, {
  required HeroProgress before,
  required HeroProgress after,
  required int xpGained,
  String? titleEarned,
  Offset? from,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ClaimCeremony(
      before: before,
      after: after,
      xpGained: xpGained,
      titleEarned: titleEarned,
      from: from,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _ClaimCeremony extends StatefulWidget {
  const _ClaimCeremony({
    required this.before,
    required this.after,
    required this.xpGained,
    required this.onDone,
    this.titleEarned,
    this.from,
  });

  final HeroProgress before;
  final HeroProgress after;
  final int xpGained;
  final String? titleEarned;
  final Offset? from;
  final VoidCallback onDone;

  @override
  State<_ClaimCeremony> createState() => _ClaimCeremonyState();
}

class _ClaimCeremonyState extends State<_ClaimCeremony> with SingleTickerProviderStateMixin {
  bool get _rankUp => widget.after.level > widget.before.level;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _rankUp ? 4600 : 3400),
  );

  static const _signIn = Interval(0.0, 0.10, curve: Curves.easeOutCubic);
  static const _fly = Interval(0.05, 0.24, curve: Curves.easeInOutCubic);
  static const _fill = Interval(0.24, 0.44, curve: Curves.easeOutCubic);
  static const _refill = Interval(0.50, 0.64, curve: Curves.easeOutCubic);
  static const _signOut = Interval(0.92, 1.0, curve: Curves.easeInCubic);

  bool _landed = false;
  bool _ranked = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTick);
    _c.forward().whenComplete(_finish);
  }

  void _onTick() {
    if (!_landed && _c.value >= 0.24) {
      _landed = true;
      HapticFeedback.lightImpact();
    }
    if (_rankUp && !_ranked && _c.value >= 0.46) {
      _ranked = true;
      HapticFeedback.heavyImpact();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final media = MediaQuery.of(context);
    final signTop = media.padding.top + 8;
    final target = Offset(media.size.width / 2, signTop + 44);

    final announcement = [
      'Quest fulfilled. Plus ${widget.xpGained} XP.',
      if (_rankUp) 'Rank up: ${widget.after.rankTitle} ${widget.after.level}.',
      if (widget.titleEarned != null) 'Title earned: ${widget.titleEarned}.',
    ].join(' ');

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final slideIn = reduced ? 1.0 : _signIn.transform(t);
            final slideOut = reduced ? 0.0 : _signOut.transform(t);
            final dy = -140 * (1 - slideIn) - 140 * slideOut;

            final shownRankedUp = _rankUp && t >= 0.46;
            double bar;
            if (reduced) {
              bar = widget.after.progress;
            } else if (_rankUp) {
              bar = t < 0.46
                  ? _lerp(widget.before.progress, 1, _fill.transform(t))
                  : _lerp(0, widget.after.progress, _refill.transform(t));
            } else {
              bar = _lerp(widget.before.progress, widget.after.progress, _fill.transform(t));
            }
            final hero = reduced || shownRankedUp || !_rankUp ? widget.after : widget.before;

            final fly = _fly.transform(t);
            final showToken = !reduced && widget.from != null && t > 0.05 && t < 0.25;

            return Stack(
              children: [
                Positioned(
                  top: signTop + dy,
                  left: 20,
                  right: 20,
                  child: Semantics(
                    liveRegion: true,
                    label: announcement,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: _finish,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: WoodSign(
                            hanging: false,
                            child: _SignContent(
                              hero: hero,
                              bar: bar,
                              xpGained: widget.xpGained,
                              rankedUp: reduced ? _rankUp : shownRankedUp,
                              titleEarned: widget.titleEarned,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showToken)
                  Positioned(
                    left: _lerp(widget.from!.dx, target.dx, fly) - 60,
                    top: _lerp(widget.from!.dy, target.dy, fly) - 16,
                    width: 120,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 - (fly - 0.8).clamp(0.0, 0.2) * 5).clamp(0.0, 1.0).toDouble(),
                        child: Text(
                          '+${widget.xpGained} XP',
                          textAlign: TextAlign.center,
                          style: GuildText.label(GuildType.xl, color: GuildColors.goldBright).copyWith(
                            shadows: const [Shadow(color: GuildColors.shadow, offset: Offset(2, 2))],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

class _SignContent extends StatelessWidget {
  const _SignContent({
    required this.hero,
    required this.bar,
    required this.xpGained,
    required this.rankedUp,
    this.titleEarned,
  });

  final HeroProgress hero;
  final double bar;
  final int xpGained;
  final bool rankedUp;
  final String? titleEarned;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rankedUp)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Rank up!',
              textAlign: TextAlign.center,
              style: GuildText.title(GuildType.xl, color: GuildColors.goldBright),
            ),
          ),
        Row(
          children: [
            Image.asset(GuildAssets.rankShield, height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${hero.rankTitle} ${toRoman(hero.level)}',
                          style: GuildText.label(GuildType.md),
                        ),
                      ),
                      Text('+$xpGained XP', style: GuildText.label(GuildType.md, color: GuildColors.goldBright)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Bar(value: bar),
                ],
              ),
            ),
          ],
        ),
        if (titleEarned != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Title earned: “$titleEarned”',
              textAlign: TextAlign.center,
              style: GuildText.aside(GuildType.md),
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 9,
      decoration: BoxDecoration(
        color: GuildColors.ink,
        border: Border.all(color: GuildColors.shadow),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0, 1),
        heightFactor: 1,
        child: const ColoredBox(color: GuildColors.goldBright),
      ),
    );
  }
}

class StampedSeal extends StatefulWidget {
  const StampedSeal({super.key, required this.animate, this.size = 64});

  final bool animate;
  final double size;

  @override
  State<StampedSeal> createState() => _StampedSealState();
}

class _StampedSealState extends State<StampedSeal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420), value: 1);

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 2.6, end: 0.9).chain(CurveTween(curve: Curves.easeInCubic)), weight: 68),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 32),
  ]);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
        _c.forward(from: 0);
        Future<void>.delayed(const Duration(milliseconds: 285), HapticFeedback.mediumImpact);
      });
    }
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
      child: ScaleTransition(
        scale: _c.drive(_scale),
        child: Transform.rotate(
          angle: -0.18,
          child: WaxSeal(size: widget.size, kind: SealKind.claimed),
        ),
      ),
    );
  }
}
