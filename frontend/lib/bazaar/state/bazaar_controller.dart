import 'package:flutter/foundation.dart';

import '../data/bazaar_repository.dart';
import '../data/models.dart';

enum WareSort {
  cheapest('cheapest first'),
  dearest('dearest first'),
  rarest('rarest first');

  const WareSort(this.label);
  final String label;

  WareSort get next => values[(index + 1) % values.length];
}

/// What one moonstone is counted as when wares priced in different coin are
/// put in order of price.
const _moonstoneInGold = 100;

int _worth(Price p) => p.currency == Currency.gold ? p.amount : p.amount * _moonstoneInGold;

class BazaarController extends ChangeNotifier {
  BazaarController(this._repository, {Future<void> Function()? beforeFirstLoad})
      : _beforeFirstLoad = beforeFirstLoad;

  final BazaarRepository _repository;
  Future<void> Function()? _beforeFirstLoad;

  BazaarData? _data;
  BazaarData? get data => _data;

  Object? _error;
  Object? get error => _error;

  /// Null shows every ware.
  WareCategory? _category;
  WareCategory? get category => _category;

  WareSort _sort = WareSort.cheapest;
  WareSort get sort => _sort;

  bool _busy = false;
  bool get busy => _busy;

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      final warmUp = _beforeFirstLoad?.call();
      _beforeFirstLoad = null;
      final data = await _repository.fetchBazaar();
      await warmUp;
      _data = data;
    } catch (e) {
      _error = e;
    } finally {
      notifyListeners();
    }
  }

  void setCategory(WareCategory? category) {
    if (category == _category) return;
    _category = category;
    notifyListeners();
  }

  void cycleSort() {
    _sort = _sort.next;
    notifyListeners();
  }

  Ware? wareById(String id) {
    for (final w in _data?.wares ?? const <Ware>[]) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// The wares laid out on the table: the chosen category, in the chosen
  /// order, with what is already owned moved to the end. The featured ware
  /// has its own card while every category is shown.
  List<Ware> get table {
    final data = _data;
    if (data == null) return const [];
    final wares = data.wares
        .where((w) => _category == null ? w.id != data.featuredId : w.category == _category)
        .toList();
    int byPrice(Ware a, Ware b) => _worth(a.price).compareTo(_worth(b.price));
    wares.sort((a, b) {
      if (a.owned != b.owned) return a.owned ? 1 : -1;
      return switch (_sort) {
        WareSort.cheapest => byPrice(a, b),
        WareSort.dearest => byPrice(b, a),
        WareSort.rarest => switch (b.rarity.index.compareTo(a.rarity.index)) {
            0 => byPrice(b, a),
            final byRarity => byRarity,
          },
      };
    });
    return wares;
  }

  Future<void> buy(String wareId, {WareDye? dye}) => _run(() => _repository.buy(wareId, dye: dye));

  Future<void> setWorn(String wareId, bool worn) => _run(() => _repository.setWorn(wareId, worn: worn));

  Future<void> setWishlisted(String wareId, bool wishlisted) =>
      _run(() => _repository.setWishlisted(wareId, wishlisted: wishlisted));

  Future<void> _run(Future<BazaarData> Function() action) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      _data = await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
