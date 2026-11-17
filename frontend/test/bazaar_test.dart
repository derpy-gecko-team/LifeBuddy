import 'package:flutter_test/flutter_test.dart';
import 'package:lifebuddy/bazaar/data/bazaar_repository.dart';
import 'package:lifebuddy/bazaar/data/mock_bazaar_repository.dart';
import 'package:lifebuddy/bazaar/data/models.dart';
import 'package:lifebuddy/bazaar/state/bazaar_controller.dart';
import 'package:lifebuddy/bazaar/widgets/bazaar_widgets.dart';
import 'package:lifebuddy/buddy/active_buddy.dart';

void main() {
  late BazaarController controller;

  setUp(() async {
    controller = BazaarController(MockBazaarRepository(latency: Duration.zero));
    await controller.load();
  });

  test('buying takes the price from the purse and puts the ware in the chest', () async {
    await controller.buy('wizards-hat', dye: WareDye.moss);

    final hat = controller.wareById('wizards-hat')!;
    expect(hat.owned, isTrue);
    expect(hat.dye, WareDye.moss);
    expect(hat.artFor(hat.dye), endsWith('wizard_hat_moss.png'));
    expect(controller.data!.purse.gold, 1240 - 450);
    expect(controller.data!.purse.moonstones, 35);
    expect(controller.data!.chest.map((w) => w.id), containsAll(['wizards-hat', 'ironclad-helm']));
  });

  test('a ware that costs more than the purse holds cannot be bought', () async {
    await expectLater(controller.buy('moon-owl'), throwsA(isA<BazaarException>()));
    expect(controller.wareById('moon-owl')!.owned, isFalse);
    expect(controller.data!.purse.gold, 1240);
    expect(controller.busy, isFalse);
  });

  test('a ware cannot be bought twice', () async {
    await expectLater(controller.buy('ironclad-helm'), throwsA(isA<BazaarException>()));
    expect(controller.data!.purse.gold, 1240);
  });

  test('wearing a ware takes off whatever shared its slot', () async {
    await controller.buy('wizards-hat');
    await controller.setWorn('ironclad-helm', true);
    await controller.setWorn('wizards-hat', true);

    expect(controller.wareById('wizards-hat')!.worn, isTrue);
    expect(controller.wareById('ironclad-helm')!.worn, isFalse);
  });

  test('wares that are only kept cannot be worn', () async {
    await controller.buy('potion-ruby');
    await expectLater(controller.setWorn('potion-ruby', true), throwsA(isA<BazaarException>()));
  });

  test('the table is sorted by price with owned wares last, and leaves out the featured ware', () {
    final table = controller.table;
    expect(table.map((w) => w.id), isNot(contains('moon-owl')));
    expect(table.last.id, 'ironclad-helm');
    expect(table.first.id, 'potion-ruby');

    controller.cycleSort();
    expect(controller.sort, WareSort.dearest);
    expect(controller.table.first.id, 'dragon-egg');
  });

  test('a category shows only its wares, the featured one included', () {
    controller.setCategory(WareCategory.creature);
    expect(controller.table.map((w) => w.id), unorderedEquals(['moon-owl', 'dragon-egg']));

    controller.setCategory(WareCategory.buddy);
    expect(controller.table.map((w) => w.id), ['tower-princess', 'old-wizard']);
  });

  test('a bought Buddy can become your guide, and the old one steps back', () async {
    expect(controller.activeBuddyId, 'old-wizard');

    await controller.buy('tower-princess');
    expect(controller.data!.purse.gold, 1240 - 600);
    expect(controller.activeBuddyId, 'old-wizard');

    await controller.setWorn('tower-princess', true);
    expect(controller.activeBuddyId, 'tower-princess');
    expect(controller.wareById('old-wizard')!.worn, isFalse);

    await controller.setWorn('old-wizard', true);
    expect(controller.activeBuddyId, 'old-wizard');
    expect(controller.wareById('tower-princess')!.worn, isFalse);
  });

  test('each Buddy ware has its own portrait and cameo', () {
    expect(BuddyLook.forWare('tower-princess'), BuddyLook.towerPrincess);
    expect(BuddyLook.forWare('tower-princess').portrait, controller.wareById('tower-princess')!.asset);
    expect(BuddyLook.forWare(null), BuddyLook.oldWizard);
  });

  test('amounts and deadlines are written out for reading', () {
    expect(formatAmount(790), '790');
    expect(formatAmount(1240), '1,240');
    expect(formatAmount(1234567), '1,234,567');
    final now = DateTime(2026, 1, 1, 12);
    expect(leavesLabel(now.add(const Duration(hours: 6, minutes: 20)), now), 'Leaves the stall in 6h');
    expect(leavesLabel(now.add(const Duration(minutes: 40)), now), 'Leaves the stall in 40 min');
  });
}
