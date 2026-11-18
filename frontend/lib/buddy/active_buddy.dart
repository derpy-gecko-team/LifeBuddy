import 'package:flutter/widgets.dart';

import '../guildhall/theme/guild_assets.dart';

class BuddyLook {
  const BuddyLook({required this.name, required this.portrait, required this.face});

  final String name;

  final String portrait;

  final String face;

  static const oldWizard = BuddyLook(
    name: 'The Old Wizard',
    portrait: GuildAssets.buddyWizard,
    face: GuildAssets.buddyWizardFace,
  );

  static const towerPrincess = BuddyLook(
    name: 'The Tower Princess',
    portrait: GuildAssets.buddyPrincess,
    face: GuildAssets.buddyPrincessFace,
  );

  static const _byWareId = {
    'old-wizard': oldWizard,
    'tower-princess': towerPrincess,
  };

  static BuddyLook forWare(String? wareId) => _byWareId[wareId] ?? oldWizard;
}

class ActiveBuddy extends InheritedWidget {
  const ActiveBuddy({super.key, required this.look, required super.child});

  final BuddyLook look;

  static BuddyLook of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActiveBuddy>()?.look ?? BuddyLook.oldWizard;

  @override
  bool updateShouldNotify(ActiveBuddy oldWidget) => oldWidget.look != look;
}
