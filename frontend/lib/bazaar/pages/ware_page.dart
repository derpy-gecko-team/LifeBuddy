import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/guild_feedback.dart';
import '../../guildhall/widgets/guild_icons.dart';
import '../../guildhall/widgets/guild_scaffold.dart';
import '../../guildhall/widgets/ornaments.dart';
import '../../guildhall/widgets/painted_wall.dart';
import '../../guildhall/widgets/pressable.dart';
import '../../guildhall/widgets/sketch.dart';
import '../../guildhall/widgets/torn_paper.dart';
import '../data/bazaar_repository.dart';
import '../data/models.dart';
import '../state/bazaar_controller.dart';
import '../widgets/bargain_scroll.dart';
import '../widgets/bazaar_widgets.dart';
import '../widgets/shop_shelves.dart' show WareHero;

class WarePage extends StatefulWidget {
  const WarePage({super.key, required this.controller, required this.wareId, this.shelf = const []});

  final BazaarController controller;
  final String wareId;

  final List<String> shelf;

  @override
  State<WarePage> createState() => _WarePageState();
}

class _WarePageState extends State<WarePage> {
  late final List<String> _shelf =
      widget.shelf.contains(widget.wareId) ? widget.shelf : [widget.wareId];
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

    final choice = await showBargainSealed(context, ware: bought, before: before, after: _controller.data!.purse);
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
        WareCategory.buddy => worn ? '${ware.name} is now your guide.' : '${ware.name} has stepped back.',
        WareCategory.creature => worn ? '${ware.name} is at your side.' : '${ware.name} is resting in your chest.',
        WareCategory.title => worn ? 'You now go by ${ware.name.replaceFirst('Title: ', '')}.' : 'Title set aside.',
        _ => worn ? 'You are wearing the ${ware.name}.' : '${ware.name} is back in your chest.',
      };

  void _step(int by) {
    final to = _index + by;
    if (to < 0 || to >= _shelf.length) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(to);
    } else {
      _pages.animateToPage(to, duration: GuildMotion.slide, curve: GuildMotion.easeOut);
    }
  }

  double _offsetOf(int i) {
    if (!_pages.hasClients || !_pages.position.haveDimensions) return (i - _index).toDouble();
    return i - (_pages.page ?? _index.toDouble());
  }

  WareDye? _dyeFor(Ware ware) =>
      ware.owned ? ware.dye : (_dyes[ware.id] ?? (ware.dyes.isEmpty ? null : ware.dyes.first));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final ware = _controller.wareById(_shelf[_index]);
        final purse = _controller.data?.purse;
        if (ware == null || purse == null) {
          return GuildScaffold(
            wall: WallVariant.poster,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: GuildNote(
                  title: 'Gone from the stall',
                  message: 'This ware is no longer for sale.',
                  action: GuildButton(label: 'Back to the stall', onPressed: () => Navigator.of(context).maybePop()),
                ),
              ),
            ),
          );
        }
        final now = DateTime.now();
        final still = MediaQuery.disableAnimationsOf(context);

        return GuildScaffold(
          wall: WallVariant.poster,
          body: Column(
            children: [
              GuildTopBar(
                back: GuildBackLink(label: 'Bazaar', onTap: () => Navigator.of(context).maybePop()),
                trailing: Text(
                  _shelf.length > 1 ? '${ware.shelf}  ·  ${_index + 1} of ${_shelf.length}' : ware.shelf,
                  style: GuildText.label(GuildType.xs, color: GuildColors.cream),
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
                          padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.huge, GuildSpace.gutter, GuildSpace.xxl),
                          child: RepaintBoundary(
                            child: _WarePoster(
                              ware: w,
                              dye: _dyeFor(w),
                              now: now,
                              onDye: w.owned ? null : (d) => setState(() => _dyes[w.id] = d),
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
                                transform: Matrix4.translationValues(0, d.abs() * 26, 0)..rotateZ(d * 0.06),
                                child: child,
                              ),
                            );
                          },
                          child: poster,
                        );
                      },
                    ),
                    if (_index > 0)
                      Positioned(left: 0, top: 236, child: _ShelfArrow(forward: false, onTap: () => _step(-1))),
                    if (_index < _shelf.length - 1)
                      Positioned(right: 0, top: 236, child: _ShelfArrow(forward: true, onTap: () => _step(1))),
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
              onWish: () => _guarded(() => _controller.setWishlisted(ware.id, !ware.wishlisted)),
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
    return GuildPressable(
      semanticLabel: forward ? 'Next ware' : 'Previous ware',
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
              boxShadow: const [BoxShadow(color: GuildShadow.color, offset: GuildShadow.small)],
            ),
            child: Center(
              child: GuildIcon(forward ? GuildGlyph.chevronRight : GuildGlyph.chevronLeft, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarePoster extends StatelessWidget {
  const _WarePoster({required this.ware, required this.dye, required this.now, required this.onDye});

  final Ware ware;
  final WareDye? dye;
  final DateTime now;
  final ValueChanged<WareDye>? onDye;

  bool get _isBuddy => ware.category == WareCategory.buddy;

  String get _mirrorLabel {
    if (ware.owned) return ware.worn ? (_isBuddy ? 'Your guide' : 'In use') : 'In your chest';
    if (ware.tryOnAsset != null) return 'Trying it on';
    return ware.category == WareCategory.avatar && ware.slot == 'hero' ? 'Your new look' : 'On display';
  }

  @override
  Widget build(BuildContext context) {
    final shown = ware.tryOnFor(dye) ?? ware.artFor(dye);
    final fills = ware.tryOnAsset != null;
    final art = Semantics(
      image: true,
      label: dye == null ? ware.name : '${ware.name}, dyed ${dye!.label}',
      child: WareHero(
        ware: ware,
        dye: dye,
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : GuildMotion.quick,
          child: Image.asset(
            shown,
            key: ValueKey(shown),
            fit: BoxFit.contain,
            alignment: fills ? Alignment.bottomCenter : Alignment.center,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
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
                            style: GuildText.title(GuildTitle.xxl, color: GuildColors.brick),
                          ),
                          const SizedBox(height: GuildSpace.hair),
                          const InkUnderline(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: GuildSpace.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    RarityMark(ware.rarity),
                    if (ware.sold > 0) ...[
                      Text('·', style: GuildText.hand(GuildType.sm, color: GuildColors.inkSoft)),
                      Text('sold ${formatAmount(ware.sold)} times', style: GuildText.hand(GuildType.sm)),
                    ],
                  ],
                ),
                if (leaves != null && !ware.owned) ...[
                  const SizedBox(height: GuildSpace.xs),
                  Text(leavesLabel(leaves, now), style: GuildText.hand(GuildType.sm, color: GuildColors.brickDeep)),
                ],
                const SizedBox(height: GuildSpace.lg),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _isBuddy
                          ? SketchBox(
                              color: GuildColors.indigo,
                              borderColor: GuildColors.ink,
                              seed: 61,
                              child: SizedBox(
                                width: 196,
                                height: 214,
                                child: Padding(padding: const EdgeInsets.all(GuildSpace.md), child: art),
                              ),
                            )
                          : MirrorFrame(
                              child: Padding(
                                padding: fills ? const EdgeInsets.only(top: 10) : const EdgeInsets.all(26),
                                child: art,
                              ),
                            ),
                    ),
                    SketchBox(
                      color: GuildColors.vellum,
                      borderColor: GuildColors.ink,
                      borderWidth: 1.5,
                      shadow: GuildShadow.small,
                      seed: 19,
                      padding: const EdgeInsets.fromLTRB(12, 3, 12, 4),
                      child: Text(_mirrorLabel, style: GuildText.hand(GuildType.sm)),
                    ),
                  ],
                ),
                const SizedBox(height: GuildSpace.lg),
                Text(ware.description, textAlign: TextAlign.center, style: GuildText.hand(GuildType.md)),
                if (ware.dyes.length > 1 && onDye != null) ...[
                  const SizedBox(height: GuildSpace.lg),
                  _DyePicker(dyes: ware.dyes, selected: dye ?? ware.dyes.first, onPick: onDye!),
                ] else if (ware.owned && dye != null) ...[
                  const SizedBox(height: GuildSpace.md),
                  Text('Dyed ${dye!.label.toLowerCase()}', style: GuildText.hand(GuildType.sm, color: GuildColors.inkSoft)),
                ],
                const SizedBox(height: GuildSpace.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: GuildIcon(GuildGlyph.check, size: 18, color: GuildColors.brick),
                    ),
                    const SizedBox(width: GuildSpace.sm),
                    Expanded(child: Text(ware.perk, style: GuildText.hand(GuildType.sm))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Positioned(top: -9, left: 0, right: 0, child: Center(child: Fastener(kind: FastenerKind.tape))),
      ],
    );
  }
}

class _DyePicker extends StatelessWidget {
  const _DyePicker({required this.dyes, required this.selected, required this.onPick});

  final List<WareDye> dyes;
  final WareDye selected;
  final ValueChanged<WareDye> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Dye', style: GuildText.hand(GuildType.sm)),
        const SizedBox(width: GuildSpace.sm),
        for (final dye in dyes)
          GuildPressable(
            selected: dye == selected,
            semanticLabel: '${dye.label} dye',
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
                      color: dye == selected ? GuildColors.brick : Colors.transparent,
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
        WareCategory.creature => 'Send it to rest',
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
    if (ware.owned && ware.worn && ware.category == WareCategory.buddy) {
      caption = '${ware.name} posts your quests. Choose another Buddy to change guides.';
      action = const GuildButton(label: 'Your guide', glyph: GuildGlyph.check, onPressed: null);
    } else if (ware.owned) {
      caption = ware.worn ? 'In use. It stays in your chest when you take it off.' : 'Bought, and kept in your chest.';
      action = !ware.wearable
          ? const GuildButton(label: 'In your chest', onPressed: null)
          : ware.worn
              ? GuildButton(
                  label: _unwearLabel(ware),
                  kind: GuildButtonKind.quiet,
                  onPressed: busy ? null : () => onWear(false),
                )
              : GuildButton(label: wearLabel(ware), onPressed: busy ? null : () => onWear(true));
    } else {
      caption = affordable
          ? 'You have ${formatAmount(have)} ${price.currency.label}. '
              '${formatAmount(have - price.amount)} left after this.'
          : 'You have ${formatAmount(have)} ${price.currency.label}. '
              '${formatAmount(price.amount - have)} more to go.';
      action = _BuyButton(price: price, onPressed: affordable && !busy ? onBuy : null);
    }

    return GuildActionBar(
      leading: ware.owned
          ? null
          : GuildIconButton(
              semanticLabel: 'Wish for ${ware.name}',
              toggled: ware.wishlisted,
              onTap: onWish,
              child: HeartMark(filled: ware.wishlisted),
            ),
      main: action,
      below: GuildFootnote(caption),
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
    final text = enabled ? GuildColors.cream : GuildButton.disabledText;
    return GuildPressable(
      semanticEnabled: enabled,
      semanticLabel: 'Buy for ${formatPrice(price)}',
      onTap: onPressed,
      haptic: true,
      child: SketchBox(
        color: enabled ? GuildColors.brickDeep : GuildButton.disabledFill,
        borderColor: enabled ? GuildColors.brickShade : GuildColors.chalkLine,
        shadow: enabled ? GuildShadow.box : null,
        shading: enabled,
        seed: 47,
        padding: const EdgeInsets.all(5),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          decoration: BoxDecoration(border: Border.all(color: text.withValues(alpha: text.a * 0.8), width: 1.2)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(opacity: enabled ? 1 : 0.6, child: CurrencyIcon(price.currency, size: 24)),
                const SizedBox(width: GuildSpace.sm),
                Text('Buy for ${formatPrice(price)}', style: GuildText.label(GuildType.lg, color: text, spacing: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
