import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/guild_feedback.dart';
import '../../guildhall/widgets/guild_icons.dart';
import '../../guildhall/widgets/guild_scaffold.dart';
import '../../guildhall/widgets/ornaments.dart';
import '../../guildhall/widgets/painted_wall.dart';
import '../../guildhall/widgets/pressable.dart';
import '../../guildhall/widgets/quest_cards.dart' show Fastener, FastenerKind;
import '../../guildhall/widgets/sketch.dart';
import '../../guildhall/widgets/torn_paper.dart';
import '../data/bazaar_repository.dart';
import '../data/models.dart';
import '../state/bazaar_controller.dart';
import '../widgets/bargain_scroll.dart';
import '../widgets/bazaar_widgets.dart';
import '../widgets/shop_shelves.dart' show WareHero;

class WarePage extends StatefulWidget {
  const WarePage({
    super.key,
    required this.controller,
    required this.wareId,
    this.shelf = const [],
  });

  final BazaarController controller;
  final String wareId;

  final List<String> shelf;

  @override
  State<WarePage> createState() => _WarePageState();
}

class _WarePageState extends State<WarePage> {
  late final List<String> _shelf = widget.shelf.contains(widget.wareId)
      ? widget.shelf
      : [widget.wareId];
  late int _index = _shelf.indexOf(widget.wareId);
  late final PageController _pages = PageController(initialPage: _index);
  final _dyes = <String, WareDye>{};

  BazaarController get _controller => widget.controller;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
    } on BazaarException catch (e) {
      if (mounted) showGuildToast(context, e.message);
    }
  }

  Future<void> _buy(Ware ware) async {
    final before = _controller.data!.purse;
    await _guarded(() => _controller.buy(ware.id, dye: _dyes[ware.id]));
    if (!mounted) return;
    final bought = _controller.wareById(ware.id);
    if (bought == null || !bought.owned) return;

    final choice = await showBargainSealed(
      context,
      ware: bought,
      before: before,
      after: _controller.data!.purse,
    );
    if (!mounted) return;
    switch (choice) {
      case BargainChoice.wear:
        await _setWorn(bought, true);
      case BargainChoice.browse:
        Navigator.of(context).maybePop();
      case null:
        break;
    }
  }

  Future<void> _setWorn(Ware ware, bool worn) async {
    await _guarded(() => _controller.setWorn(ware.id, worn));
    if (!mounted || _controller.wareById(ware.id)?.worn != worn) return;
    showGuildToast(context, _wornToast(ware, worn));
  }

  static String _wornToast(Ware ware, bool worn) => switch (ware.category) {
    WareCategory.buddy =>
      worn
          ? '${ware.name} is at your side.'
          : '${ware.name} is resting in your chest.',
    WareCategory.title =>
      worn
          ? 'You now go by ${ware.name.replaceFirst('Title: ', '')}.'
          : 'Title set aside.',
    _ =>
      worn
          ? 'You are wearing the ${ware.name}.'
          : '${ware.name} is back in your chest.',
  };

  void _step(int by) {
    final to = _index + by;
    if (to < 0 || to >= _shelf.length) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(to);
    } else {
      _pages.animateToPage(
        to,
        duration: const Duration(milliseconds: 380),
        curve: GuildMotion.easeOut,
      );
    }
  }

  double _offsetOf(int i) {
    if (!_pages.hasClients || !_pages.position.haveDimensions) {
      return (i - _index).toDouble();
    }
    return i - (_pages.page ?? _index.toDouble());
  }

  WareDye? _dyeFor(Ware ware) => ware.owned
      ? ware.dye
      : (_dyes[ware.id] ?? (ware.dyes.isEmpty ? null : ware.dyes.first));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final ware = _controller.wareById(_shelf[_index]);
        final purse = _controller.data?.purse;
        if (ware == null || purse == null) {
          return GuildScaffold(
            wall: WallVariant.quest,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: GuildNote(
                  title: 'Gone from the stall',
                  message: 'This ware is no longer for sale.',
                  action: GuildButton(
                    label: 'Back to the stall',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final still = MediaQuery.disableAnimationsOf(context);

        return GuildScaffold(
          wall: WallVariant.quest,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 20, 0),
                child: Row(
                  children: [
                    GuildBackLink(
                      label: 'Bazaar',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    Text(
                      _shelf.length > 1
                          ? '${ware.shelf}  ·  ${_index + 1} of ${_shelf.length}'
                          : ware.shelf,
                      style: GuildText.label(
                        GuildType.xs,
                        color: GuildColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pages,
                      itemCount: _shelf.length,
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _index = i);
                      },
                      itemBuilder: (context, i) {
                        final w = _controller.wareById(_shelf[i]);
                        if (w == null) return const SizedBox.shrink();
                        final poster = SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
                          child: RepaintBoundary(
                            child: _WarePoster(
                              ware: w,
                              dye: _dyeFor(w),
                              now: now,
                              onDye: w.owned
                                  ? null
                                  : (d) => setState(() => _dyes[w.id] = d),
                            ),
                          ),
                        );
                        if (still) return poster;
                        return AnimatedBuilder(
                          animation: _pages,
                          builder: (context, child) {
                            final d = _offsetOf(i).clamp(-1.0, 1.0);
                            return Opacity(
                              opacity: 1 - d.abs() * 0.55,
                              child: Transform(
                                alignment: Alignment.bottomCenter,
                                transform: Matrix4.translationValues(
                                  0,
                                  d.abs() * 26,
                                  0,
                                )..rotateZ(d * 0.06),
                                child: child,
                              ),
                            );
                          },
                          child: poster,
                        );
                      },
                    ),
                    if (_index > 0)
                      Positioned(
                        left: 0,
                        top: 236,
                        child: _ShelfArrow(
                          forward: false,
                          onTap: () => _step(-1),
                        ),
                      ),
                    if (_index < _shelf.length - 1)
                      Positioned(
                        right: 0,
                        top: 236,
                        child: _ShelfArrow(
                          forward: true,
                          onTap: () => _step(1),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottom: AnimatedSwitcher(
            duration: still ? Duration.zero : GuildMotion.quick,
            child: _BuyBar(
              key: ValueKey(ware.id),
              ware: ware,
              purse: purse,
              busy: _controller.busy,
              onBuy: () => _buy(ware),
              onWear: (worn) => _setWorn(ware, worn),
              onWish: () => _guarded(
                () => _controller.setWishlisted(ware.id, !ware.wishlisted),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShelfArrow extends StatelessWidget {
  const _ShelfArrow({required this.forward, required this.onTap});

  final bool forward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: forward ? 'Next ware' : 'Previous ware',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        haptic: true,
        pressedScale: 0.9,
        child: SizedBox(
          width: 44,
          height: 56,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: GuildColors.indigoDeep,
                shape: BoxShape.circle,
                border: Border.all(color: GuildColors.chalk, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: GuildColors.shadow.withValues(alpha: 0.5),
                    offset: const Offset(1.5, 2.5),
                  ),
                ],
              ),
              child: Center(
                child: GuildIcon(
                  forward ? GuildGlyph.chevronRight : GuildGlyph.chevronLeft,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarePoster extends StatelessWidget {
  const _WarePoster({
    required this.ware,
    required this.dye,
    required this.now,
    required this.onDye,
  });

  final Ware ware;
  final WareDye? dye;
  final DateTime now;
  final ValueChanged<WareDye>? onDye;

  String get _mirrorLabel {
    if (ware.owned) return ware.worn ? 'In use' : 'In your chest';
    if (ware.tryOnAsset != null) return 'Trying it on';
    return ware.category == WareCategory.avatar && ware.slot == 'hero'
        ? 'Your new look'
        : 'On display';
  }

  @override
  Widget build(BuildContext context) {
    final shown = ware.tryOnFor(dye) ?? ware.artFor(dye);
    final fills = ware.tryOnAsset != null;
    final leaves = ware.leavesAt;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TornPaper(
          seed: stableSeed(ware.id) % 89 + 3,
          tear: 5,
          tearBottom: 12,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
          child: RuledFrame(
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 22),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Semantics(
                    header: true,
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            ware.name,
                            textAlign: TextAlign.center,
                            style: GuildText.title(
                              GuildType.xxl,
                              color: GuildColors.brick,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const InkUnderline(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    RarityMark(ware.rarity),
                    Text(
                      '·',
                      style: GuildText.hand(
                        GuildType.sm,
                        color: GuildColors.pencil,
                      ),
                    ),
                    Text(
                      'sold ${formatAmount(ware.sold)} times',
                      style: GuildText.hand(GuildType.sm),
                    ),
                  ],
                ),
                if (leaves != null && !ware.owned) ...[
                  const SizedBox(height: 4),
                  Text(
                    leavesLabel(leaves, now),
                    style: GuildText.hand(
                      GuildType.sm,
                      color: GuildColors.brick,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: MirrorFrame(
                        child: Padding(
                          padding: fills
                              ? const EdgeInsets.only(top: 10)
                              : const EdgeInsets.all(26),
                          child: Semantics(
                            image: true,
                            label: dye == null
                                ? ware.name
                                : '${ware.name}, dyed ${dye!.label}',
                            child: WareHero(
                              ware: ware,
                              dye: dye,
                              child: AnimatedSwitcher(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : GuildMotion.quick,
                                child: Image.asset(
                                  shown,
                                  key: ValueKey(shown),
                                  fit: BoxFit.contain,
                                  alignment: fills
                                      ? Alignment.bottomCenter
                                      : Alignment.center,
                                  filterQuality: FilterQuality.medium,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SketchBox(
                      color: GuildColors.vellum,
                      borderColor: GuildColors.ink,
                      borderWidth: 1.5,
                      shadow: const Offset(1.5, 2),
                      seed: 19,
                      padding: const EdgeInsets.fromLTRB(12, 3, 12, 4),
                      child: Text(
                        _mirrorLabel,
                        style: GuildText.hand(GuildType.sm),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  ware.description,
                  textAlign: TextAlign.center,
                  style: GuildText.hand(GuildType.lg),
                ),
                if (ware.dyes.length > 1 && onDye != null) ...[
                  const SizedBox(height: 14),
                  _DyePicker(
                    dyes: ware.dyes,
                    selected: dye ?? ware.dyes.first,
                    onPick: onDye!,
                  ),
                ] else if (ware.owned && dye != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Dyed ${dye!.label.toLowerCase()}',
                    style: GuildText.hand(
                      GuildType.sm,
                      color: GuildColors.inkSoft,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: GuildIcon(
                        GuildGlyph.check,
                        size: 18,
                        color: GuildColors.brick,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ware.perk,
                        style: GuildText.hand(GuildType.sm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          top: -9,
          left: 0,
          right: 0,
          child: Center(child: Fastener(kind: FastenerKind.tape)),
        ),
        Positioned(
          top: -16,
          right: -8,
          child: RoundBadge(asset: ware.artFor(dye), size: 62),
        ),
      ],
    );
  }
}

class _DyePicker extends StatelessWidget {
  const _DyePicker({
    required this.dyes,
    required this.selected,
    required this.onPick,
  });

  final List<WareDye> dyes;
  final WareDye selected;
  final ValueChanged<WareDye> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Dye', style: GuildText.hand(GuildType.sm)),
        const SizedBox(width: 6),
        for (final dye in dyes)
          Semantics(
            button: true,
            selected: dye == selected,
            label: '${dye.label} dye',
            excludeSemantics: true,
            child: GuildPressable(
              onTap: () => onPick(dye),
              haptic: true,
              pressedScale: 0.9,
              child: SizedBox.square(
                dimension: 46,
                child: Center(
                  child: AnimatedContainer(
                    duration: GuildMotion.press,
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: dye == selected
                            ? GuildColors.brick
                            : Colors.transparent,
                        width: 2.2,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: dye.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: GuildColors.ink, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BuyBar extends StatelessWidget {
  const _BuyBar({
    super.key,
    required this.ware,
    required this.purse,
    required this.busy,
    required this.onBuy,
    required this.onWear,
    required this.onWish,
  });

  final Ware ware;
  final Purse purse;
  final bool busy;
  final VoidCallback onBuy;
  final ValueChanged<bool> onWear;
  final VoidCallback onWish;

  static String _unwearLabel(Ware ware) => switch (ware.category) {
    WareCategory.buddy => 'Send it to rest',
    WareCategory.title => 'Set the title aside',
    _ => 'Take it off',
  };

  @override
  Widget build(BuildContext context) {
    final price = ware.price;
    final have = purse.of(price.currency);
    final affordable = purse.canAfford(price);

    final Widget action;
    final String caption;
    if (ware.owned) {
      caption = ware.worn
          ? 'In use. It stays in your chest when you take it off.'
          : 'Bought, and kept in your chest.';
      action = !ware.wearable
          ? const GuildButton(label: 'In your chest', onPressed: null)
          : ware.worn
          ? GuildButton(
              label: _unwearLabel(ware),
              kind: GuildButtonKind.quiet,
              onPressed: busy ? null : () => onWear(false),
            )
          : GuildButton(
              label: wearLabel(ware),
              onPressed: busy ? null : () => onWear(true),
            );
    } else {
      caption = affordable
          ? 'You have ${formatAmount(have)} ${price.currency.label}. '
                '${formatAmount(have - price.amount)} left after this.'
          : 'You have ${formatAmount(have)} ${price.currency.label}. '
                '${formatAmount(price.amount - have)} more to go.';
      action = _BuyButton(
        price: price,
        onPressed: affordable && !busy ? onBuy : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!ware.owned) ...[
                Semantics(
                  button: true,
                  toggled: ware.wishlisted,
                  label: 'Wish for ${ware.name}',
                  excludeSemantics: true,
                  child: GuildPressable(
                    onTap: onWish,
                    haptic: true,
                    pressedScale: 0.92,
                    child: SketchBox(
                      color: GuildColors.indigoDeep,
                      borderColor: GuildColors.chalk.withValues(alpha: 0.8),
                      borderWidth: 2,
                      seed: 71,
                      child: SizedBox.square(
                        dimension: 56,
                        child: Center(
                          child: HeartMark(filled: ware.wishlisted),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: action),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: GuildText.aside(GuildType.sm),
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.price, required this.onPressed});

  final Price price;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final text = enabled
        ? GuildColors.cream
        : GuildColors.cream.withValues(alpha: 0.72);
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Buy for ${formatPrice(price)}',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onPressed,
        haptic: true,
        child: SketchBox(
          color: enabled ? GuildColors.brick : GuildColors.indigoDeep,
          borderColor: enabled ? GuildColors.brickDeep : GuildColors.chalkLine,
          shadow: enabled ? const Offset(2, 3) : null,
          seed: 47,
          padding: const EdgeInsets.all(5),
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            decoration: BoxDecoration(
              border: Border.all(
                color: text.withValues(alpha: text.a * 0.8),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: enabled ? 1 : 0.6,
                    child: CurrencyIcon(price.currency, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Buy for ${formatPrice(price)}',
                    style: GuildText.label(
                      GuildType.lg,
                      color: text,
                      spacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
