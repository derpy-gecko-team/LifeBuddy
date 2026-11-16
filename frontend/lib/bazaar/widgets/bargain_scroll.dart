import 'package:flutter/material.dart';

import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/guild_feedback.dart';
import '../../guildhall/widgets/guild_icons.dart';
import '../../guildhall/widgets/motion.dart';
import '../../guildhall/widgets/ornaments.dart';
import '../../guildhall/widgets/pressable.dart';
import '../data/models.dart';
import 'bazaar_widgets.dart';

enum BargainChoice { wear, browse }

String wearLabel(Ware ware) => switch (ware.category) {
      WareCategory.buddy => 'Call it to your side',
      WareCategory.title => 'Take the title',
      _ => 'Wear it now',
    };

/// The receipt for a purchase, unrolled over the stall. Completes with what
/// the buyer chose to do next, or null if the scroll was simply dismissed.
Future<BargainChoice?> showBargainSealed(
  BuildContext context, {
  required Ware ware,
  required Purse before,
  required Purse after,
}) {
  return showGeneralDialog<BargainChoice>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: GuildColors.shadow.withValues(alpha: 0.72),
    transitionDuration: GuildMotion.quick,
    pageBuilder: (context, _, _) => SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Material(
            type: MaterialType.transparency,
            child: _BargainScroll(ware: ware, before: before, after: after),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );
}

class _BargainScroll extends StatefulWidget {
  const _BargainScroll({required this.ware, required this.before, required this.after});

  final Ware ware;
  final Purse before;
  final Purse after;

  @override
  State<_BargainScroll> createState() => _BargainScrollState();
}

class _BargainScrollState extends State<_BargainScroll> with SingleTickerProviderStateMixin {
  late final AnimationController _unroll = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  bool _animate = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _animate = !MediaQuery.disableAnimationsOf(context);
    _animate ? _unroll.forward() : _unroll.value = 1;
  }

  @override
  void dispose() {
    _unroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ware = widget.ware;
    final currency = ware.price.currency;
    final sheet = Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: const BoxDecoration(
        color: GuildColors.parchment,
        border: Border.symmetric(vertical: BorderSide(color: GuildColors.tan, width: 2)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 20),
        decoration: const BoxDecoration(
          border: Border.symmetric(vertical: BorderSide(color: GuildColors.tan, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bargain sealed!',
                      textAlign: TextAlign.center,
                      style: GuildText.title(GuildType.xxl, color: GuildColors.brick),
                    ),
                    const InkUnderline(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            WareArt(ware.artFor(ware.dye), size: 128),
            const SizedBox(height: 12),
            Text(
              'The ${ware.name} now waits in your chest.',
              textAlign: TextAlign.center,
              style: GuildText.hand(GuildType.lg),
            ),
            const SizedBox(height: 10),
            Semantics(
              label: '${formatAmount(widget.after.of(currency))} ${currency.label} left',
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CurrencyIcon(currency, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    formatAmount(widget.before.of(currency)),
                    style: GuildText.hand(GuildType.md, color: GuildColors.inkSoft).copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: GuildColors.inkSoft,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: GuildIcon(GuildGlyph.chevronRight, size: 14, color: GuildColors.ink),
                  ),
                  Text(
                    '${formatAmount(widget.after.of(currency))} ${currency.label}',
                    style: GuildText.hand(GuildType.md),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (ware.wearable) ...[
              GuildButton(label: wearLabel(ware), onPressed: () => Navigator.pop(context, BargainChoice.wear)),
              const SizedBox(height: 4),
              _InkLink(label: 'Keep browsing the stall', onTap: () => Navigator.pop(context, BargainChoice.browse)),
            ] else
              GuildButton(
                label: 'Keep browsing the stall',
                onPressed: () => Navigator.pop(context, BargainChoice.browse),
              ),
          ],
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Roller(),
              ClipRect(
                child: AnimatedBuilder(
                  animation: _unroll,
                  builder: (context, child) => Align(
                    alignment: Alignment.topCenter,
                    heightFactor: Curves.easeOutCubic.transform(_unroll.value).clamp(0.02, 1.0),
                    child: child,
                  ),
                  child: sheet,
                ),
              ),
              const _Roller(),
            ],
          ),
          Positioned(
            top: -12,
            right: 12,
            child: StampIn(
              animate: _animate,
              delay: const Duration(milliseconds: 380),
              child: const _SealedCheck(),
            ),
          ),
          for (final (i, star) in const [
            (left: 44.0, right: null, top: -34.0, size: 20.0),
            (left: null, right: 62.0, top: -40.0, size: 16.0),
            (left: null, right: -6.0, top: 58.0, size: 24.0),
            (left: -8.0, right: null, top: 96.0, size: 18.0),
          ].indexed)
            Positioned(
              left: star.left,
              right: star.right,
              top: star.top,
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _unroll, curve: Interval(0.35 + i * 0.12, 1)),
                child: ChalkStar(size: star.size, seed: i + 5, color: GuildColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

class _Roller extends StatelessWidget {
  const _Roller();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFE2D0AA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GuildColors.tan, width: 2),
        boxShadow: [BoxShadow(color: GuildColors.shadow.withValues(alpha: 0.5), offset: const Offset(2, 3))],
      ),
      alignment: const Alignment(0, -0.35),
      child: Container(height: 1.2, margin: const EdgeInsets.symmetric(horizontal: 14), color: GuildColors.tan),
    );
  }
}

class _SealedCheck extends StatelessWidget {
  const _SealedCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GuildColors.brick,
        shape: BoxShape.circle,
        border: Border.all(color: GuildColors.cream, width: 2.4),
        boxShadow: [BoxShadow(color: GuildColors.shadow.withValues(alpha: 0.5), offset: const Offset(2, 3))],
      ),
      child: const GuildIcon(GuildGlyph.check, size: 26),
    );
  }
}

class _InkLink extends StatelessWidget {
  const _InkLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Text(
              label,
              style: GuildText.body(GuildType.md, color: GuildColors.brickDeep).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: GuildColors.brickDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
