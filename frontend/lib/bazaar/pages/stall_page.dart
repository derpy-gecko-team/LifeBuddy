import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/board_header.dart' show HangingTag;
import '../../guildhall/widgets/guild_feedback.dart';
import '../../guildhall/widgets/guild_scaffold.dart';
import '../../guildhall/widgets/painted_wall.dart';
import '../../guildhall/widgets/pressable.dart';
import '../data/models.dart';
import '../state/bazaar_controller.dart';
import '../widgets/shop_entrance.dart';
import '../widgets/bazaar_widgets.dart';
import '../widgets/shop_shelves.dart';

class StallPage extends StatefulWidget {
  const StallPage({super.key, required this.controller, required this.onOpenWare, required this.onOpenChest});

  final BazaarController controller;
  final OpenWare onOpenWare;
  final VoidCallback onOpenChest;

  @override
  State<StallPage> createState() => _StallPageState();
}

class _StallPageState extends State<StallPage> {
  final _topKey = GlobalKey();
  final _railPinned = ValueNotifier<bool>(false);
  final _scroll = ScrollController();
  WareCategory? _shownCategory;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scroll.dispose();
    _railPinned.dispose();
    super.dispose();
  }

  /// A new category is a new table: if the old one had been scrolled down,
  /// start the new one from its first row, just under the rail.
  void _onControllerChanged() {
    final category = widget.controller.category;
    if (category == _shownCategory) return;
    _shownCategory = category;
    if (!_scroll.hasClients) return;
    final top = _topKey.currentContext?.size?.height;
    if (top != null && _scroll.offset > top) _scroll.jumpTo(top);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      final topHeight = _topKey.currentContext?.size?.height ?? 260;
      _railPinned.value = n.metrics.pixels > topHeight - 2;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GuildScaffold(
      wall: WallVariant.bazaar,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final data = controller.data;
          if (data == null) {
            return Column(
              children: [
                const ShopEntrance(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: controller.error != null
                          ? GuildNote(
                              title: 'The stall is shut',
                              message: 'The wares could not be laid out. Check your connection and try again.',
                              action: GuildButton(label: 'Try again', onPressed: controller.load),
                            )
                          : const GuildNote(title: 'Laying out the wares', busy: true),
                    ),
                  ),
                ),
              ],
            );
          }

          final now = DateTime.now();
          final category = controller.category;
          final featured = category == null ? data.featured : null;
          final table = controller.table;
          final railExtent = 62 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 1.6;

          return NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: RefreshIndicator(
              color: GuildColors.gold,
              backgroundColor: GuildColors.indigoDeep,
              onRefresh: controller.load,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      key: _topKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RepaintBoundary(child: ShopEntrance(purse: data.purse, onOpenChest: widget.onOpenChest)),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _RailDelegate(controller: controller, extent: railExtent, pinned: _railPinned),
                  ),
                  if (featured != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 26, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: FeaturedNiche(
                            ware: featured,
                            now: now,
                            onOpen: () => widget.onOpenWare(
                              featured.id,
                              shelf: [featured.id, for (final w in table) w.id],
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                category == null ? 'On the shelves' : category.plural,
                                style: GuildText.title(GuildType.xl, color: GuildColors.cream),
                              ),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Sorted ${controller.sort.label}. Change order.',
                            excludeSemantics: true,
                            child: GuildPressable(
                              onTap: controller.cycleSort,
                              haptic: true,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 44),
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  widthFactor: 1,
                                  child: Text(
                                    controller.sort.label,
                                    style: GuildText.aside(GuildType.sm).copyWith(
                                      decoration: TextDecoration.underline,
                                      decorationColor: GuildColors.chalkLine,
                                      decorationStyle: TextDecorationStyle.dashed,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: table.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                              child: Center(
                                child: GuildNote(
                                  title: 'The shelves are bare',
                                  message: 'No ${category?.plural.toLowerCase() ?? 'wares'} today. New wares '
                                      'arrive at every dawn.',
                                  action: GuildButton(
                                    label: 'Show all wares',
                                    kind: GuildButtonKind.quiet,
                                    onPressed: () => controller.setCategory(null),
                                  ),
                                ),
                              ),
                            )
                          : ShopShelves(
                              wares: table,
                              onOpen: widget.onOpenWare,
                              restockKey: (category, controller.sort),
                            ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RailDelegate extends SliverPersistentHeaderDelegate {
  _RailDelegate({required this.controller, required this.extent, required this.pinned});

  final BazaarController controller;
  final double extent;
  final ValueListenable<bool> pinned;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    Widget tag(String label, WareCategory? category) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: HangingTag(
            label: label,
            selected: controller.category == category,
            onTap: () => controller.setCategory(category),
          ),
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: pinned,
          builder: (context, isPinned, child) => AnimatedOpacity(
            opacity: isPinned ? 1 : 0,
            duration: GuildMotion.quick,
            child: child,
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: GuildColors.indigo,
              border: Border(bottom: BorderSide(color: GuildColors.chalkLine, width: 1.5)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Stack(
            children: [
              Positioned(left: 0, right: 0, top: 4, child: Container(height: 2, color: GuildColors.chalkLine)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tag('All wares', null),
                    for (final c in WareCategory.values) tag(c.plural, c),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_RailDelegate old) => true;
}
