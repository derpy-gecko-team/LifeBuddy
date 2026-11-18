import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/ornaments.dart';
import '../../guildhall/widgets/pressable.dart';
import '../../guildhall/widgets/sketch.dart';
import '../../guildhall/widgets/torn_paper.dart';
import '../data/models.dart';
import '../theme/bazaar_assets.dart';
import 'shop_shelves.dart' show WareHero;

String formatAmount(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

String formatPrice(Price price) => '${formatAmount(price.amount)} ${price.currency.label}';

String leavesLabel(DateTime leavesAt, DateTime now) {
  final left = leavesAt.difference(now);
  if (left.inMinutes < 1) return 'Leaving the stall now';
  if (left.inHours < 1) return 'Leaves the stall in ${left.inMinutes} min';
  if (left.inHours < 48) return 'Leaves the stall in ${left.inHours}h';
  return 'Leaves the stall in ${left.inDays} days';
}

String currencyAsset(Currency currency) => switch (currency) {
      Currency.gold => BazaarAssets.coin,
      Currency.moonstones => BazaarAssets.moonstone,
    };

class CurrencyIcon extends StatelessWidget {
  const CurrencyIcon(this.currency, {super.key, this.size = 20});

  final Currency currency;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Image.asset(currencyAsset(currency), width: size, height: size, filterQuality: FilterQuality.medium),
      );
}

class WareArt extends StatelessWidget {
  const WareArt(this.asset, {super.key, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        ),
      );
}

class RarityMark extends StatelessWidget {
  const RarityMark(this.rarity, {super.key, this.size = GuildType.sm, this.color = GuildColors.ink});

  final Rarity rarity;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(dimension: size * 0.8, child: CustomPaint(painter: _DiamondPainter(rarity, color))),
        SizedBox(width: size * 0.4),
        Flexible(child: Text(rarity.label, style: GuildText.hand(size, color: color))),
      ],
    );
  }
}

class _DiamondPainter extends CustomPainter {
  _DiamondPainter(this.rarity, this.ink);
  final Rarity rarity;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    final fill = switch (rarity) {
      Rarity.common => null,
      Rarity.rare => GuildColors.rare,
      Rarity.legendary => GuildColors.gold,
    };
    if (fill != null) canvas.drawPath(path, Paint()..color = fill.withValues(alpha: ink.a));
    canvas.drawPath(path, Sketch.pen(rarity == Rarity.legendary ? GuildColors.bronze.withValues(alpha: ink.a) : ink, 1.6));
  }

  @override
  bool shouldRepaint(_DiamondPainter old) => old.rarity != rarity || old.ink != ink;
}

class PriceTag extends StatelessWidget {
  const PriceTag(this.price, {super.key, this.size = 16});

  final Price price;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PriceTagPainter(stableSeed('${price.amount}${price.currency.name}')),
      child: Padding(
        padding: EdgeInsets.fromLTRB(size * 1.75, size * 0.34, size * 1.1, size * 0.34),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CurrencyIcon(price.currency, size: size * 1.2),
            SizedBox(width: size * 0.4),
            Text(formatAmount(price.amount), style: GuildText.title(size, color: GuildColors.ink)),
          ],
        ),
      ),
    );
  }
}

class _PriceTagPainter extends CustomPainter {
  _PriceTagPainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final point = min(size.height * 0.5, 15.0);
    final sketch = Sketch.of([
      Offset(0, size.height / 2),
      Offset(point, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(point, size.height),
    ], seed);
    sketch.paintFill(canvas, GuildColors.vellum, shadow: GuildShadow.small);
    sketch.paintBorder(canvas, color: GuildColors.ink, width: 1.7);
    canvas.drawCircle(Offset(point + 2, size.height / 2), 2.8, Paint()..color = GuildColors.indigoDeep);
  }

  @override
  bool shouldRepaint(_PriceTagPainter old) => old.seed != seed;
}

class OwnedStamp extends StatelessWidget {
  const OwnedStamp({super.key, this.label = 'OWNED'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.2,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: GuildColors.brickDeep, width: 2),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 1, 6, 1),
          decoration: BoxDecoration(
            border: Border.all(color: GuildColors.brickDeep.withValues(alpha: 0.6), width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            style: GuildText.title(GuildTitle.md, color: GuildColors.brickDeep).copyWith(letterSpacing: 2.4),
          ),
        ),
      ),
    );
  }
}

class InkUnderline extends StatelessWidget {
  const InkUnderline({super.key, this.color = GuildColors.brick});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 6, child: ExcludeSemantics(child: CustomPaint(painter: _UnderlinePainter(color))));
}

class _UnderlinePainter extends CustomPainter {
  _UnderlinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final from = Offset(0, size.height * 0.75);
    final to = Offset(size.width, size.height * 0.4);
    final bow = Offset(size.width * 0.45, size.height * 0.2);
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(bow.dx, bow.dy - 1.2, to.dx, to.dy)
        ..quadraticBezierTo(bow.dx, bow.dy + 1.6, from.dx, from.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_UnderlinePainter old) => old.color != color;
}

class _RingedArt extends StatelessWidget {
  const _RingedArt({required this.ware, required this.size});

  final Ware ware;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      circle: true,
      color: GuildColors.tan,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: GuildColors.vellum, shape: BoxShape.circle),
        child: WareHero(ware: ware, child: WareArt(ware.artFor(ware.dye), size: size * 0.8)),
      ),
    );
  }
}

typedef OpenWare = void Function(String wareId, {List<String> shelf});

String wareSemantics(Ware ware) => ware.owned
    ? '${ware.name}, ${ware.shelf}, ${ware.rarity.label}, in your chest'
    : '${ware.name}, ${ware.shelf}, ${ware.rarity.label}, ${formatPrice(ware.price)}';

class WareNote extends StatelessWidget {
  const WareNote({super.key, required this.ware, required this.onOpen, this.tilt = 0, this.markOwned = true});

  final Ware ware;
  final VoidCallback onOpen;
  final double tilt;

  final bool markOwned;

  @override
  Widget build(BuildContext context) {
    final seed = stableSeed(ware.id);
    final taped = seed % 3 != 0;
    final owned = ware.owned && markOwned;

    return GuildPressable(
      semanticLabel: wareSemantics(ware),
      onTap: onOpen,
      pressedScale: 0.97,
      haptic: true,
      child: Transform.rotate(
        angle: tilt,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            TornPaper(
              seed: seed % 97 + 2,
              tear: 4,
              tearBottom: 9,
              padding: const EdgeInsets.fromLTRB(13, 20, 11, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(opacity: owned ? 0.7 : 1, child: _RingedArt(ware: ware, size: 70)),
                  const SizedBox(height: GuildSpace.sm),
                  Text(
                    ware.shelf,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GuildText.label(GuildType.xs, color: GuildColors.inkSoft, spacing: 0.4),
                  ),
                  const SizedBox(height: GuildSpace.hair),
                  Text(
                    ware.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GuildText.title(GuildTitle.lg, color: GuildColors.brickDeep),
                  ),
                  const SizedBox(height: GuildSpace.xs),
                  RarityMark(ware.rarity),
                  const SizedBox(height: GuildSpace.sm),
                  if (ware.owned)
                    Text(
                      ware.worn ? (ware.category == WareCategory.buddy ? 'Your guide' : 'In use') : 'In your chest',
                      style: GuildText.hand(GuildType.sm, color: GuildColors.inkSoft),
                    )
                  else
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: PriceTag(ware.price, size: 14)),
                ],
              ),
            ),
            if (taped)
              const Positioned(top: -8, left: 0, right: 0, child: Center(child: Fastener(kind: FastenerKind.tape)))
            else
              const Positioned(top: 6, right: 30, child: Fastener(kind: FastenerKind.pin)),
            if (owned) const Positioned(top: 24, right: -5, child: OwnedStamp()),
          ],
        ),
      ),
    );
  }
}

class MirrorFrame extends StatelessWidget {
  const MirrorFrame({super.key, required this.child, this.width = 196, this.height = 214});

  final Widget child;
  final double width;
  final double height;

  static const _rim = 15.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: const _MirrorPainter(),
        foregroundPainter: const _MirrorShinePainter(),
        child: Padding(
          padding: const EdgeInsets.all(_rim + 1),
          child: ClipOval(child: child),
        ),
      ),
    );
  }
}

class _MirrorPainter extends CustomPainter {
  const _MirrorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = (Offset.zero & size).deflate(2);
    final inner = outer.deflate(MirrorFrame._rim);
    final ink = Sketch.pen(GuildColors.ink, 2.4);
    canvas.drawOval(outer.shift(const Offset(2, 3)), Paint()..color = GuildColors.shadow.withValues(alpha: 0.35));
    canvas.drawOval(outer, Paint()..color = GuildColors.gold);
    canvas.drawOval(outer, ink);
    canvas.drawOval(inner, Paint()..color = GuildColors.mist);
    canvas.drawOval(inner, ink);

    final mid = outer.deflate(MirrorFrame._rim / 2);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 - pi / 2;
      final at = mid.center + Offset(cos(a) * mid.width / 2, sin(a) * mid.height / 2);
      final major = i.isEven;
      canvas.drawCircle(at, major ? 4.6 : 2.8, Paint()..color = major ? GuildColors.brick : GuildColors.vellum);
      canvas.drawCircle(at, major ? 4.6 : 2.8, Sketch.pen(GuildColors.ink, 1.5));
    }
  }

  @override
  bool shouldRepaint(_MirrorPainter old) => false;
}

class _MirrorShinePainter extends CustomPainter {
  const _MirrorShinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Sketch.pen(Colors.white.withValues(alpha: 0.75), 3);
    Offset p(double x, double y) => Offset(size.width * x, size.height * y);
    canvas.drawLine(p(0.22, 0.3), p(0.31, 0.2), pen);
    canvas.drawLine(p(0.25, 0.38), p(0.38, 0.24), pen);
  }

  @override
  bool shouldRepaint(_MirrorShinePainter old) => false;
}

class HeartMark extends StatelessWidget {
  const HeartMark({super.key, required this.filled, this.size = 26});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _HeartPainter(filled)));
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.5, s * 0.86)
      ..cubicTo(s * 0.08, s * 0.58, s * 0.04, s * 0.2, s * 0.3, s * 0.16)
      ..cubicTo(s * 0.42, s * 0.14, s * 0.48, s * 0.24, s * 0.5, s * 0.3)
      ..cubicTo(s * 0.52, s * 0.24, s * 0.58, s * 0.14, s * 0.7, s * 0.16)
      ..cubicTo(s * 0.96, s * 0.2, s * 0.92, s * 0.58, s * 0.5, s * 0.86)
      ..close();
    if (filled) canvas.drawPath(path, Paint()..color = GuildColors.brick);
    canvas.drawPath(path, Sketch.pen(filled ? GuildColors.cream : GuildColors.chalkLine, 2));
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.filled != filled;
}

class WareTable extends StatelessWidget {
  const WareTable({super.key, required this.wares, required this.onOpen, this.markOwned = true});

  final List<Ware> wares;
  final OpenWare onOpen;
  final bool markOwned;

  @override
  Widget build(BuildContext context) {
    final shelf = [for (final w in wares) w.id];
    Widget note(int i) => RepaintBoundary(
          child: WareNote(
            key: ValueKey(wares[i].id),
            ware: wares[i],
            onOpen: () => onOpen(wares[i].id, shelf: shelf),
            markOwned: markOwned,
            tilt: switch (i % 4) { 0 => -0.012, 1 => 0.014, 2 => 0.01, _ => -0.016 },
          ),
        );

    return SketchBox(
      color: GuildColors.indigoDeep,
      borderColor: GuildColors.chalk.withValues(alpha: 0.8),
      borderWidth: 2,
      shadow: GuildShadow.raised,
      seed: 83,
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: GuildColors.chalkLine, width: 1)),
        padding: const EdgeInsets.fromLTRB(9, 20, 9, 14),
        child: Column(
          children: [
            for (var i = 0; i < wares.length; i += 2)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 26),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: note(i)),
                      const SizedBox(width: GuildSpace.lg),
                      Expanded(child: i + 1 < wares.length ? note(i + 1) : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
