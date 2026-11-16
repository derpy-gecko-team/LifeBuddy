import 'package:flutter/material.dart';

import '../bazaar/data/bazaar_repository.dart';
import '../bazaar/data/mock_bazaar_repository.dart';
import '../bazaar/pages/chest_page.dart';
import '../bazaar/pages/stall_page.dart';
import '../bazaar/pages/ware_page.dart';
import '../bazaar/state/bazaar_controller.dart';
import '../guildhall/theme/guild_theme.dart';
import '../guildhall/widgets/notice_route.dart';

class BazaarPage extends StatefulWidget {
  const BazaarPage({super.key, this.repository});

  final BazaarRepository? repository;

  @override
  State<BazaarPage> createState() => _BazaarPageState();
}

class _BazaarPageState extends State<BazaarPage> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final BazaarController _controller =
      BazaarController(widget.repository ?? MockBazaarRepository(), beforeFirstLoad: GuildText.preload)..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openWare(String wareId, {List<String> shelf = const []}) {
    Navigator.of(context, rootNavigator: true).push(NoticeRoute<void>(
      builder: (_) => WarePage(controller: _controller, wareId: wareId, shelf: shelf),
    ));
  }

  void _openChest() {
    _navigatorKey.currentState!.push(PlaqueRoute<void>(
      builder: (_) => ChestPage(controller: _controller, onOpenWare: _openWare),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: _navigatorKey,
        onGenerateInitialRoutes: (_, _) => [
          MaterialPageRoute<void>(
            builder: (_) => StallPage(controller: _controller, onOpenWare: _openWare, onOpenChest: _openChest),
          ),
        ],
      ),
    );
  }
}
