import 'package:material_ui/material_ui.dart';

import '../../guildhall/theme/guild_theme.dart';
import '../../guildhall/widgets/guild_feedback.dart';
import '../../guildhall/widgets/guild_scaffold.dart';
import '../../guildhall/widgets/ornaments.dart';
import '../../guildhall/widgets/painted_wall.dart';
import '../state/bazaar_controller.dart';
import '../theme/bazaar_assets.dart';
import '../widgets/bazaar_widgets.dart';

class ChestPage extends StatelessWidget {
  const ChestPage({
    super.key,
    required this.controller,
    required this.onOpenWare,
  });

  final BazaarController controller;
  final OpenWare onOpenWare;

  @override
  Widget build(BuildContext context) {
    return GuildScaffold(
      wall: WallVariant.journey,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final chest = controller.data?.chest ?? const [];
          final wearing = chest.where((w) => w.worn).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                child: GuildBackLink(
                  label: 'Bazaar',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 18),
                      child: Row(
                        children: [
                          const GuildArt(BazaarAssets.chestPouch, height: 50),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'My chest',
                                    style: GuildText.title(
                                      GuildType.xxl,
                                      color: GuildColors.cream,
                                    ),
                                  ),
                                ),
                                Text(
                                  chest.isEmpty
                                      ? 'Empty, for now.'
                                      : '${chest.length} ${chest.length == 1 ? 'ware' : 'wares'} kept, $wearing in use.',
                                  style: GuildText.aside(GuildType.md),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (chest.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 30, 14, 0),
                        child: Center(
                          child: GuildNote(
                            title: 'Your chest is empty',
                            message:
                                'Whatever you buy at the stall is kept here.',
                            action: GuildButton(
                              label: 'Back to the stall',
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ),
                      )
                    else
                      WareTable(
                        wares: chest,
                        onOpen: onOpenWare,
                        markOwned: false,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
