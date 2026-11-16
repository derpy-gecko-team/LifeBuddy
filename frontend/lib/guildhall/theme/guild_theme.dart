import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class GuildColors {
  static const indigo = Color(0xFF4E5387);
  static const indigoDeep = Color(0xFF3B4071);
  static const indigoLight = Color(0xFF6268A0);
  static const shadow = Color(0xFF272B55);
  static const torchlight = Color(0xFFF3CF8A);

  static const cream = Color(0xFFEFE0BC);
  static const chalk = Color(0xFFDEC99E);
  static const chalkLine = Color(0xB8DEC99E);
  static const dangerText = Color(0xFFF4BDB2);

  static const parchment = Color(0xFFE9D4B5);
  static const parchmentDark = Color(0xFFD9C19C);
  static const vellum = Color(0xFFF1E4CB);
  static const mist = Color(0xFFDADBE8);
  static const mistDark = Color(0xFFBFC2D8);

  static const tan = Color(0xFFC4AC86);
  static const pencil = Color(0xFF9A8463);

  static const ink = Color(0xFF2C2F58);
  static const inkSoft = Color(0xFF4F517C);

  static const brick = Color(0xFFB95A54);
  static const brickDeep = Color(0xFF9E423C);

  static const gold = Color(0xFFDDB96E);
  static const goldBright = Color(0xFFEBD197);
  static const bronze = Color(0xFF7D5A1C);
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
  static const pageBack = Duration(milliseconds: 240);
  static const easeOut = Cubic(0.23, 1, 0.32, 1);
}

abstract final class GuildText {
  static final _hand = GoogleFonts.deliciousHandrawn();
  static final _lettering = GoogleFonts.almendra(fontWeight: FontWeight.w700);

  static Future<void> preload() async {
    _hand;
    _lettering;
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

  static TextStyle title(double size, {Color color = GuildColors.brickDeep}) => _lettering.copyWith(
        fontSize: size * 0.9,
        color: color,
        height: 1.12,
        letterSpacing: 0.2,
      );

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
