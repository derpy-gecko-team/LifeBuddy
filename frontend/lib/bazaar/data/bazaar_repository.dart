import 'models.dart';

abstract interface class BazaarRepository {
  Future<BazaarData> fetchBazaar();

  Future<BazaarData> buy(String wareId, {WareDye? dye});

  Future<BazaarData> setWorn(String wareId, {required bool worn});

  Future<BazaarData> setWishlisted(String wareId, {required bool wishlisted});
}

class BazaarException implements Exception {
  BazaarException(this.message);
  final String message;

  @override
  String toString() => message;
}
