import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class GuildColors {
  static const mortar = Color(0xFF1C201D);
  static const stoneDark = Color(0xFF353E37);
  static const stone = Color(0xFF3D473F);
  static const stoneLight = Color(0xFF424C43);
  static const torchlight = Color(0xFFF2B25C);

  static const panel = Color(0xFF1F231F);
  static const panelBorder = Color(0xFF4A5046);
  static const leather = Color(0xFF2A2F29);
  static const wood = Color(0xFF4E3B28);
  static const woodDark = Color(0xFF3B2C1D);
  static const woodLight = Color(0xFF63503A);

  static const ink = Color(0xFF1B1D19);
  static const inkSoft = Color(0xFF3B3A33);
  static const shadow = Color(0xFF121512);

  static const cream = Color(0xFFEDDDA8);
  static const dangerText = Color(0xFFF0B0A8);

  static const gold = Color(0xFFD9A55B);
  static const goldBright = Color(0xFFEDC27A);
  static const bronze = Color(0xFF6E4B10);

  static const crimson = Color(0xFF8C4743);
  static const crimsonDeep = Color(0xFF7A3B38);
  static const crimsonLight = Color(0xFFA25B56);

  static const verdigris = Color(0xFF4A6A63);
  static const verdigrisDark = Color(0xFF3E5A54);
  static const verdigrisLight = Color(0xFF6E9189);

  static const parchment = Color(0xFFEBDDA2);
  static const parchmentDark = Color(0xFFD9C886);
  static const sage = Color(0xFFD7DEC9);
  static const sageDark = Color(0xFFB9C3A8);
  static const vellum = Color(0xFFE2D2BC);
  static const vellumDark = Color(0xFFC9B598);
}

abstract final class GuildType {
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
  static const double xxl = 36;
  static const double display = 44;
}

abstract final class GuildMotion {
  static const press = Duration(milliseconds: 120);
  static const quick = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 340);
}

abstract final class GuildText {
  static final _hand = GoogleFonts.deliciousHandrawn();

  static Future<void> preload() async {
    _hand;
    try {
      await GoogleFonts.pendingFonts();
    } catch (_) {}
  }

  static double _optical(double size) => size < GuildType.xl ? size * 1.12 : size;

  static double _wordGap(double size) => size * 0.14;

  static TextStyle _style(double size, Color color, {double height = 1.25, double spacing = 0.2}) {
    final fontSize = _optical(size);
    return _hand.copyWith(
      fontSize: fontSize,
      color: color,
      height: height,
      letterSpacing: spacing,
      wordSpacing: _wordGap(fontSize),
    );
  }

  static TextStyle title(double size, {Color color = GuildColors.ink}) =>
      _style(size, color, height: 1.05, spacing: 0.3);

  static TextStyle hand(double size, {Color color = GuildColors.ink}) => _style(size, color, height: 1.2);

  static TextStyle label(double size, {Color color = GuildColors.cream, double spacing = 0.8}) =>
      _style(size, color, height: 1.2, spacing: spacing);

  static TextStyle body(double size, {Color color = GuildColors.inkSoft}) => _style(size, color, height: 1.3);

  static TextStyle aside(double size, {Color color = GuildColors.cream}) => _style(size, color, height: 1.3);
}

int stableSeed(String id) {
  var h = 17;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0x3fffffff;
  }
  return h;
}
