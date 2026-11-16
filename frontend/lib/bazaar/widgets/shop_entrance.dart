import 'package:flutter/material.dart';

import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/guild_icons.dart';
import '../../guildhall/widgets/pressable.dart';
import '../data/models.dart';
import '../theme/bazaar_assets.dart';
import 'bazaar_widgets.dart';

class ShopEntrance extends StatelessWidget {
  const ShopEntrance({super.key, this.purse, this.onOpenChest});

  final Purse? purse;
  final VoidCallback? onOpenChest;

  static const _curtainHeight = 150.0;
  static const _signHeight = 190.0;
  static const _slipTop = 70.0;

  @override
  Widget build(BuildContext context) {
    Widget curtain({required bool mirrored}) => IgnorePointer(
      child: ExcludeSemantics(
        child: Transform.flip(
          flipX: mirrored,
          child: Image.asset(
            BazaarAssets.curtain,
            height: _curtainHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );

    final purse = this.purse;
    return LayoutBuilder(
      builder: (context, constraints) {
        final signWidth = _signHeight * ShopSign.aspect;
        final slipWidth = ((constraints.maxWidth - signWidth) / 2 - 24).clamp(52.0, 120.0);

        return SizedBox(
          height: _signHeight + 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (purse != null) ...[
                Positioned(
                  left: 21,
                  top: _slipTop,
                  width: slipWidth,
                  child: _PurseSlip(purse: purse),
                ),
                Positioned(
                  right: 21,
                  top: _slipTop,
                  width: slipWidth,
                  child: _ChestSlip(onOpen: onOpenChest),
                ),
              ],
              Positioned(left: 3, top: 0, child: curtain(mirrored: false)),
              Positioned(right: 3, top: 0, child: curtain(mirrored: true)),
              const Positioned(
                left: 0,
                right: 0,
                top: 2,
                child: Center(child: ShopSign(height: _signHeight)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Plaque extends StatelessWidget {
  const _Plaque({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 128 / 142,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: Image.asset(BazaarAssets.sidePlaque, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.52),
            child: FractionallySizedBox(
              widthFactor: 0.54,
              heightFactor: 0.44,
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurseSlip extends StatelessWidget {
  const _PurseSlip({required this.purse});

  final Purse purse;

  @override
  Widget build(BuildContext context) {
    Widget row(Currency currency, int amount) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          child: Center(child: CurrencyIcon(currency, size: currency == Currency.gold ? 23 : 21)),
        ),
        const SizedBox(width: 6),
        Text(formatAmount(amount), style: GuildText.title(GuildType.md, color: GuildColors.ink).copyWith(height: 1)),
      ],
    );

    return Semantics(
      label: '${formatAmount(purse.gold)} gold, ${formatAmount(purse.moonstones)} moonstones',
      excludeSemantics: true,
      child: _Plaque(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(Currency.gold, purse.gold),
            const SizedBox(height: 7),
            row(Currency.moonstones, purse.moonstones),
          ],
        ),
      ),
    );
  }
}

class _ChestSlip extends StatelessWidget {
  const _ChestSlip({required this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'My chest',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onOpen,
        haptic: true,
        child: _Plaque(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WareArt(BazaarAssets.chestPouch, size: 30),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('My chest', style: GuildText.hand(GuildType.sm).copyWith(height: 1)),
                  const SizedBox(width: 2),
                  const GuildIcon(GuildGlyph.chevronRight, size: 13, color: GuildColors.ink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopSign extends StatelessWidget {
  const ShopSign({super.key, required this.height});

  final double height;

  static const _artWidth = 260.0;
  static const _artHeight = 340.0;
  static const aspect = _artWidth / _artHeight;

  @override
  Widget build(BuildContext context) {
    final unit = height / _artHeight;
    Widget line(double top, double left, double right, double tall, Widget child) => Positioned(
      top: top * unit,
      left: left * unit,
      right: right * unit,
      height: tall * unit,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );

    return Semantics(
      header: true,
      label: 'The Bazaar. New wares at every dawn.',
      excludeSemantics: true,
      child: SizedBox(
        width: _artWidth * unit,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(BazaarAssets.shopSign, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
            ),
            line(
              166,
              70,
              70,
              22,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 26, height: 1.6, color: GuildColors.ink),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'THE',
                      textScaler: TextScaler.noScaling,
                      style: GuildText.title(20, color: GuildColors.ink).copyWith(letterSpacing: 4, height: 1),
                    ),
                  ),
                  Container(width: 26, height: 1.6, color: GuildColors.ink),
                ],
              ),
            ),
            line(
              186,
              50,
              50,
              56,
              Text(
                'BAZAAR',
                textScaler: TextScaler.noScaling,
                style: GuildText.title(60, color: GuildColors.ink).copyWith(letterSpacing: 2, height: 1),
              ),
            ),
            line(
              264,
              58,
              58,
              23,
              Text(
                'NEW WARES AT EVERY DAWN',
                textScaler: TextScaler.noScaling,
                style: GuildText.title(15, color: GuildColors.ink).copyWith(letterSpacing: 1.4, height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
