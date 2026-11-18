import 'package:flutter/material.dart';

import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/guild_feedback.dart';
import '../../guildhall/widgets/guild_scaffold.dart';
import '../../guildhall/widgets/painted_wall.dart';
import '../../guildhall/widgets/pressable.dart';
import '../../guildhall/widgets/tag_rail.dart';
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
                        const SizedBox(height: GuildSpace.md),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedTagRail(
                      tags: [
                        TagRailItem(
                          label: 'All wares',
                          selected: category == null,
                          onTap: () => controller.setCategory(null),
                        ),
                        for (final c in WareCategory.values)
                          TagRailItem(
                            label: c.plural,
                            selected: category == c,
                            onTap: () => controller.setCategory(c),
                          ),
                      ],
                      extent: PinnedTagRail.extentFor(context),
                      pinned: _railPinned,
                    ),
                  ),
                  if (featured != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.xxl, GuildSpace.gutter, 0),
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
                    padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.xxl, GuildSpace.gutter, GuildSpace.sm),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                category == null ? 'On the shelves' : category.plural,
                                style: GuildText.title(GuildTitle.xl, color: GuildColors.cream),
                              ),
                            ),
                          ),
                          GuildPressable(
                            semanticLabel: 'Sorted ${controller.sort.label}. Change order.',
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
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: GuildSpace.lg),
                    sliver: SliverToBoxAdapter(
                      child: table.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(GuildSpace.xs, GuildSpace.xxl, GuildSpace.xs, 0),
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
                  if (category != null && table.isNotEmpty && table.every((w) => w.owned))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.lg, GuildSpace.gutter, 0),
                        child: Text(
                          'Everything here is already yours. More ${category.plural.toLowerCase()} '
                          'will reach the stall in time.',
                          textAlign: TextAlign.center,
                          style: GuildText.aside(GuildType.sm),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: GuildSpace.huge)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
