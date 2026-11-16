import 'dart:ui' show Color;

enum WareCategory {
  avatar('Avatars', 'Avatar'),
  cosmetic('Cosmetics', 'Cosmetic'),
  buddy('Buddies', 'Buddy'),
  potion('Potions', 'Potion'),
  trinket('Trinkets', 'Trinket'),
  title('Titles', 'Title');

  const WareCategory(this.plural, this.label);
  final String plural;
  final String label;
}

enum Rarity {
  common('Common'),
  rare('Rare'),
  legendary('Legendary');

  const Rarity(this.label);
  final String label;
}

enum Currency {
  gold('gold'),
  moonstones('moonstones');

  const Currency(this.label);
  final String label;
}

enum WareDye {
  indigo('Midnight', Color(0xFF3B4071)),
  brick('Crimson', Color(0xFFB95A54)),
  moss('Moss', Color(0xFF5F7D4E)),
  umber('Umber', Color(0xFF8A6240));

  const WareDye(this.label, this.color);
  final String label;
  final Color color;
}

class Price {
  const Price(this.amount, [this.currency = Currency.gold]);

  final int amount;
  final Currency currency;
}

class Purse {
  const Purse({required this.gold, required this.moonstones});

  final int gold;
  final int moonstones;

  int of(Currency currency) => switch (currency) {
        Currency.gold => gold,
        Currency.moonstones => moonstones,
      };

  bool canAfford(Price price) => of(price.currency) >= price.amount;

  Purse minus(Price price) => switch (price.currency) {
        Currency.gold => Purse(gold: gold - price.amount, moonstones: moonstones),
        Currency.moonstones => Purse(gold: gold, moonstones: moonstones - price.amount),
      };
}

class Ware {
  const Ware({
    required this.id,
    required this.name,
    required this.category,
    required this.kind,
    required this.rarity,
    required this.price,
    required this.blurb,
    required this.description,
    required this.perk,
    required this.asset,
    this.tryOnAsset,
    this.slot,
    this.dyes = const [],
    this.dye,
    this.sold = 0,
    this.owned = false,
    this.worn = false,
    this.wishlisted = false,
    this.leavesAt,
  });

  final String id;
  final String name;
  final WareCategory category;

  final String kind;
  final Rarity rarity;
  final Price price;

  final String blurb;
  final String description;

  final String perk;

  final String asset;

  final String? tryOnAsset;

  final String? slot;

  final List<WareDye> dyes;

  final WareDye? dye;

  final int sold;
  final bool owned;
  final bool worn;
  final bool wishlisted;

  final DateTime? leavesAt;

  bool get wearable => slot != null;

  String get shelf => '${category.label} · $kind';

  String artFor(WareDye? dye) => _dyed(asset, dye);

  String? tryOnFor(WareDye? dye) => tryOnAsset == null ? null : _dyed(tryOnAsset!, dye);

  String _dyed(String path, WareDye? dye) {
    if (dye == null || dyes.isEmpty || dye == dyes.first) return path;
    return path.replaceFirst('.png', '_${dye.name}.png');
  }

  Ware copyWith({bool? owned, bool? worn, bool? wishlisted, WareDye? dye, int? sold}) => Ware(
        id: id,
        name: name,
        category: category,
        kind: kind,
        rarity: rarity,
        price: price,
        blurb: blurb,
        description: description,
        perk: perk,
        asset: asset,
        tryOnAsset: tryOnAsset,
        slot: slot,
        dyes: dyes,
        dye: dye ?? this.dye,
        sold: sold ?? this.sold,
        owned: owned ?? this.owned,
        worn: worn ?? this.worn,
        wishlisted: wishlisted ?? this.wishlisted,
        leavesAt: leavesAt,
      );
}

class BazaarData {
  const BazaarData({required this.purse, required this.wares, this.featuredId});

  final Purse purse;
  final List<Ware> wares;

  final String? featuredId;

  Ware? get featured {
    for (final w in wares) {
      if (w.id == featuredId) return w;
    }
    return null;
  }

  List<Ware> get chest => wares.where((w) => w.owned).toList();
}
