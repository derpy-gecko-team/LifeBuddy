import '../theme/bazaar_assets.dart';
import 'bazaar_repository.dart';
import 'models.dart';

class MockBazaarRepository implements BazaarRepository {
  MockBazaarRepository({DateTime? now, this.latency = const Duration(milliseconds: 280)})
      : _data = _seed(now ?? DateTime.now());

  final Duration latency;
  BazaarData _data;

  Future<BazaarData> _reply() => Future<BazaarData>.delayed(latency, () => _data);

  Ware _find(String id) => _data.wares.firstWhere(
        (w) => w.id == id,
        orElse: () => throw BazaarException('That ware is no longer on the stall.'),
      );

  void _replace(Ware ware) {
    _data = BazaarData(
      purse: _data.purse,
      featuredId: _data.featuredId,
      wares: [for (final w in _data.wares) w.id == ware.id ? ware : w],
    );
  }

  @override
  Future<BazaarData> fetchBazaar() => _reply();

  @override
  Future<BazaarData> buy(String wareId, {WareDye? dye}) {
    final ware = _find(wareId);
    if (ware.owned) throw BazaarException('${ware.name} is already in your chest.');
    if (dye != null && !ware.dyes.contains(dye)) {
      throw BazaarException('${ware.name} does not come in that dye.');
    }
    final purse = _data.purse;
    if (!purse.canAfford(ware.price)) {
      final short = ware.price.amount - purse.of(ware.price.currency);
      throw BazaarException('You are $short ${ware.price.currency.label} short for this one.');
    }
    _data = BazaarData(purse: purse.minus(ware.price), wares: _data.wares, featuredId: _data.featuredId);
    _replace(ware.copyWith(
      owned: true,
      sold: ware.sold + 1,
      dye: dye ?? (ware.dyes.isEmpty ? null : ware.dyes.first),
    ));
    return _reply();
  }

  @override
  Future<BazaarData> setWorn(String wareId, {required bool worn}) {
    final ware = _find(wareId);
    if (!ware.owned) throw BazaarException('Buy ${ware.name} before putting it on.');
    if (!ware.wearable) throw BazaarException('${ware.name} is kept in your chest, not worn.');
    if (worn) {
      for (final other in _data.wares.toList()) {
        if (other.worn && other.slot == ware.slot && other.id != ware.id) {
          _replace(other.copyWith(worn: false));
        }
      }
    }
    _replace(ware.copyWith(worn: worn));
    return _reply();
  }

  @override
  Future<BazaarData> setWishlisted(String wareId, {required bool wishlisted}) {
    _replace(_find(wareId).copyWith(wishlisted: wishlisted));
    return _reply();
  }

  static BazaarData _seed(DateTime now) {
    const allDyes = [WareDye.indigo, WareDye.brick, WareDye.moss, WareDye.umber];
    const worn = 'Shows on your avatar, your guild card and next to your quests.';
    const kept = 'Kept in your chest for all to admire.';
    const creature = 'Keeps you company beside your avatar on your guild card.';

    return BazaarData(
      purse: const Purse(gold: 1240, moonstones: 35),
      featuredId: 'moon-owl',
      wares: [
        Ware(
          id: 'moon-owl',
          name: 'Moon Owl',
          category: WareCategory.creature,
          kind: 'Companion',
          rarity: Rarity.legendary,
          price: const Price(2400),
          blurb: 'A watchful owl that keeps you company at dusk.',
          description: 'Raised in the rafters of the old observatory. It keeps watch over your quests '
              'while you sleep and hoots softly at dusk.',
          perk: creature,
          asset: BazaarAssets.moonOwl,
          slot: 'creature',
          sold: 41,
          leavesAt: now.add(const Duration(hours: 6, minutes: 20)),
        ),
        const Ware(
          id: 'old-wizard',
          name: 'The Old Wizard',
          category: WareCategory.buddy,
          kind: 'Guide',
          rarity: Rarity.common,
          price: Price(0),
          blurb: 'Posts your quests and answers your letters.',
          description: 'He has walked more roads than the guild has maps for. Tell him what you '
              'mean to do and he will pin it to your board, one honest step at a time.',
          perk: 'Your guide. He posts your quests and answers your letters.',
          asset: BazaarAssets.oldWizard,
          slot: 'buddy',
          owned: true,
          worn: true,
        ),
        const Ware(
          id: 'tower-princess',
          name: 'The Tower Princess',
          category: WareCategory.buddy,
          kind: 'Guide',
          rarity: Rarity.rare,
          price: Price(600),
          blurb: 'Sends your quests down from the tower window.',
          description: 'She has read every book in the tower twice and has opinions about all of '
              'them. Tell her what you mean to do and she will write it out neatly, then check '
              'that you did it.',
          perk: 'Your guide. She posts your quests and answers your letters.',
          asset: BazaarAssets.towerPrincess,
          slot: 'buddy',
          sold: 87,
        ),
        const Ware(
          id: 'wizards-hat',
          name: 'Wizard’s Hat',
          category: WareCategory.avatar,
          kind: 'Head',
          rarity: Rarity.rare,
          price: Price(450),
          blurb: 'Midnight silk and a little stardust.',
          description: 'Woven from midnight silk and a little stardust. Worn by apprentices who '
              'finish what they start.',
          perk: worn,
          asset: BazaarAssets.wizardHat,
          tryOnAsset: BazaarAssets.wizardHatTryOn,
          slot: 'head',
          dyes: allDyes,
          sold: 312,
        ),
        const Ware(
          id: 'ironclad-helm',
          name: 'Ironclad Helm',
          category: WareCategory.avatar,
          kind: 'Head',
          rarity: Rarity.common,
          price: Price(180),
          blurb: 'Plain steel, honestly dented.',
          description: 'Plain steel with a brass ridge, dented in all the right places. It has '
              'already seen one adventurer through their first week.',
          perk: worn,
          asset: BazaarAssets.ironcladHelm,
          slot: 'head',
          sold: 1204,
          owned: true,
        ),
        const Ware(
          id: 'dragon-egg',
          name: 'Dragon Egg',
          category: WareCategory.creature,
          kind: 'Hatchling',
          rarity: Rarity.legendary,
          price: Price(35, Currency.moonstones),
          blurb: 'Warm to the touch, and ticking.',
          description: 'Warm to the touch and faintly ticking. Keep your oaths and something '
              'small and fierce will hatch to keep you company.',
          perk: creature,
          asset: BazaarAssets.dragonEgg,
          slot: 'creature',
          sold: 17,
        ),
        const Ware(
          id: 'crimson-cloak',
          name: 'Crimson Cloak',
          category: WareCategory.cosmetic,
          kind: 'Cape',
          rarity: Rarity.rare,
          price: Price(380),
          blurb: 'Heavy wool with a brass clasp.',
          description: 'Heavy wool, a brass clasp, and a hem that has swept the floor of every '
              'tavern between here and the coast.',
          perk: worn,
          asset: BazaarAssets.crimsonCloak,
          slot: 'cape',
          dyes: [WareDye.brick, WareDye.indigo, WareDye.moss, WareDye.umber],
          sold: 268,
        ),
        const Ware(
          id: 'starlit-frame',
          name: 'Starlit Frame',
          category: WareCategory.avatar,
          kind: 'Frame',
          rarity: Rarity.rare,
          price: Price(320),
          blurb: 'A ring of gold for your portrait.',
          description: 'A ring of beaten gold set with four garnets. Hang your portrait in it and '
              'the whole guild will know whose it is.',
          perk: 'Frames your portrait on your guild card.',
          asset: BazaarAssets.starlitFrame,
          slot: 'frame',
          sold: 190,
        ),
        const Ware(
          id: 'title-ironclad',
          name: 'Title: “Ironclad”',
          category: WareCategory.title,
          kind: 'Guild card',
          rarity: Rarity.common,
          price: Price(150),
          blurb: 'A name earned the hard way.',
          description: 'A deed from the guild scribe naming you Ironclad. For those who turned up '
              'on the days they did not feel like it.',
          perk: 'Written under your name on your guild card.',
          asset: BazaarAssets.titleScroll,
          slot: 'title',
          sold: 533,
        ),
        const Ware(
          id: 'avatar-rogue',
          name: 'Hooded Rogue',
          category: WareCategory.avatar,
          kind: 'Hero',
          rarity: Rarity.rare,
          price: Price(900),
          blurb: 'Quick hands, quicker exits.',
          description: 'Quick hands and quicker exits. The rogue is never seen starting a task, '
              'only walking away from it finished.',
          perk: worn,
          asset: BazaarAssets.avatarRogue,
          slot: 'hero',
          sold: 148,
        ),
        const Ware(
          id: 'avatar-forager',
          name: 'Burrow Forager',
          category: WareCategory.avatar,
          kind: 'Hero',
          rarity: Rarity.rare,
          price: Price(850),
          blurb: 'Knows every mushroom by name.',
          description: 'Knows every mushroom in the wood by name and will not be hurried. Small '
              'steps, a full satchel by evening.',
          perk: worn,
          asset: BazaarAssets.avatarForager,
          slot: 'hero',
          sold: 203,
        ),
        const Ware(
          id: 'avatar-mage',
          name: 'Wisp Mage',
          category: WareCategory.avatar,
          kind: 'Hero',
          rarity: Rarity.legendary,
          price: Price(28, Currency.moonstones),
          blurb: 'Three wisps and a borrowed tome.',
          description: 'Followed everywhere by three wisps and one overdue library book. Studies '
              'late, and it shows.',
          perk: worn,
          asset: BazaarAssets.avatarMage,
          slot: 'hero',
          sold: 36,
        ),
        const Ware(
          id: 'avatar-wolf',
          name: 'Wolf Knight',
          category: WareCategory.avatar,
          kind: 'Hero',
          rarity: Rarity.legendary,
          price: Price(2200),
          blurb: 'Scarred, patched, still standing.',
          description: 'Scarred, patched and still standing. The old wolf has never missed a '
              'morning drill and does not plan to start.',
          perk: worn,
          asset: BazaarAssets.avatarWolf,
          slot: 'hero',
          sold: 58,
        ),
        const Ware(
          id: 'avatar-bard',
          name: 'Horned Bard',
          category: WareCategory.avatar,
          kind: 'Hero',
          rarity: Rarity.rare,
          price: Price(950),
          blurb: 'Sings your deeds, loudly.',
          description: 'Sings your deeds back to you, loudly, with a songbird for harmony. Even '
              'the small ones get a verse.',
          perk: worn,
          asset: BazaarAssets.avatarBard,
          slot: 'hero',
          sold: 121,
        ),
        const Ware(
          id: 'avatar-ranger',
          name: 'Frost Ranger',
          category: WareCategory.avatar,
          kind: 'Hero',
          rarity: Rarity.rare,
          price: Price(1000),
          blurb: 'Walks far, packs light.',
          description: 'Walks far, packs light, and always has the lantern lit before dark. '
              'Patient as snowfall.',
          perk: worn,
          asset: BazaarAssets.avatarRanger,
          slot: 'hero',
          sold: 97,
        ),
        const Ware(
          id: 'potion-ruby',
          name: 'Ruby Tonic',
          category: WareCategory.potion,
          kind: 'Brew',
          rarity: Rarity.common,
          price: Price(60),
          blurb: 'Sweet, fizzy, faintly medicinal.',
          description: 'Sweet, fizzy and faintly medicinal. Brewed by the stallkeeper’s aunt for '
              'mornings that start badly.',
          perk: kept,
          asset: BazaarAssets.potionRuby,
          sold: 2410,
        ),
        const Ware(
          id: 'potion-moonlit',
          name: 'Moonlit Draught',
          category: WareCategory.potion,
          kind: 'Brew',
          rarity: Rarity.rare,
          price: Price(260),
          blurb: 'Bottled at midnight, tied with bay.',
          description: 'Bottled at midnight and tied with a sprig of bay. The swirl inside never '
              'quite settles.',
          perk: kept,
          asset: BazaarAssets.potionMoonlit,
          sold: 344,
        ),
        const Ware(
          id: 'potion-amber',
          name: 'Amber Elixir',
          category: WareCategory.potion,
          kind: 'Brew',
          rarity: Rarity.legendary,
          price: Price(12, Currency.moonstones),
          blurb: 'Sunlight, kept in cut glass.',
          description: 'A summer afternoon kept in cut glass. Hold it to a window and the whole '
              'room turns gold.',
          perk: kept,
          asset: BazaarAssets.potionAmber,
          sold: 72,
        ),
        const Ware(
          id: 'crystal-red',
          name: 'Ember Crystal',
          category: WareCategory.trinket,
          kind: 'Curio',
          rarity: Rarity.rare,
          price: Price(240),
          blurb: 'Still warm from the mountain.',
          description: 'Chipped from a seam under the mountain and still a little warm. It hums '
              'when you are close to finishing something.',
          perk: kept,
          asset: BazaarAssets.crystalRed,
          sold: 410,
        ),
        const Ware(
          id: 'chipped-sword',
          name: 'Chipped Sword',
          category: WareCategory.trinket,
          kind: 'Arms',
          rarity: Rarity.common,
          price: Price(120),
          blurb: 'Every notch has a story.',
          description: 'Every notch has a story and the stallkeeper will tell you all of them. '
              'Still sharp where it counts.',
          perk: kept,
          asset: BazaarAssets.chippedSword,
          sold: 876,
        ),
        const Ware(
          id: 'oak-shield',
          name: 'Oak Shield',
          category: WareCategory.trinket,
          kind: 'Arms',
          rarity: Rarity.common,
          price: Price(140),
          blurb: 'Four planks and an iron rim.',
          description: 'Four oak planks and an iron rim. It has stopped worse than a bad Monday.',
          perk: kept,
          asset: BazaarAssets.woodenShield,
          sold: 640,
        ),
        const Ware(
          id: 'brass-key',
          name: 'Brass Key',
          category: WareCategory.trinket,
          kind: 'Curio',
          rarity: Rarity.rare,
          price: Price(300),
          blurb: 'Nobody knows what it opens.',
          description: 'Nobody at the stall knows what it opens. Somebody, somewhere, is missing '
              'a door.',
          perk: kept,
          asset: BazaarAssets.brassKey,
          sold: 215,
        ),
        const Ware(
          id: 'sealed-letter',
          name: 'Sealed Letter',
          category: WareCategory.trinket,
          kind: 'Curio',
          rarity: Rarity.common,
          price: Price(90),
          blurb: 'Addressed to no one in particular.',
          description: 'Addressed to no one in particular and sealed in red wax. Opening it would '
              'spoil it.',
          perk: kept,
          asset: BazaarAssets.sealedLetter,
          sold: 1022,
        ),
        const Ware(
          id: 'mushrooms',
          name: 'Twin Toadstools',
          category: WareCategory.trinket,
          kind: 'Curio',
          rarity: Rarity.common,
          price: Price(70),
          blurb: 'Picked this morning. Do not eat.',
          description: 'Picked this morning from the foot of the old oak. Lovely to look at. Do '
              'not eat them.',
          perk: kept,
          asset: BazaarAssets.mushrooms,
          sold: 1380,
        ),
        const Ware(
          id: 'gem-skull',
          name: 'Gem-eyed Skull',
          category: WareCategory.trinket,
          kind: 'Curio',
          rarity: Rarity.rare,
          price: Price(420),
          blurb: 'It winks when you slack off.',
          description: 'Somebody set an amethyst where the left eye was. It seems to wink when '
              'you put things off.',
          perk: kept,
          asset: BazaarAssets.gemSkull,
          sold: 156,
        ),
        const Ware(
          id: 'ruby-amulet',
          name: 'Ruby Amulet',
          category: WareCategory.trinket,
          kind: 'Curio',
          rarity: Rarity.legendary,
          price: Price(30, Currency.moonstones),
          blurb: 'A garnet the size of a plum.',
          description: 'A garnet the size of a plum on a chain of brass beads. Heavier than it '
              'looks, like most promises.',
          perk: kept,
          asset: BazaarAssets.rubyAmulet,
          sold: 29,
        ),
        const Ware(
          id: 'locked-tome',
          name: 'Locked Tome',
          category: WareCategory.trinket,
          kind: 'Curio',
          rarity: Rarity.rare,
          price: Price(500),
          blurb: 'The lock is the interesting part.',
          description: 'Bound in slate-grey leather with a brass lock and no keyhole on the '
              'outside. The runes on the cover change when nobody is looking.',
          perk: kept,
          asset: BazaarAssets.lockedTome,
          sold: 88,
        ),
      ],
    );
  }
}
