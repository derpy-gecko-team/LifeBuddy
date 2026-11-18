import 'package:material_ui/material_ui.dart';

/// The app palette. Never hardcode a color in a widget: add it here.
///
/// Values were eyeballed from the login mock-up (indigo frame, gold
/// ornaments, parchment, red lettering) and the Guild Hall screenshot.
/// Use an eyedropper on the artwork for exact values; change them here and
/// the whole app follows.
abstract final class AppColors {
  // --- Parchment: page background, quest cards ---
  static const parchment = Color(0xFFEAD8B2);
  static const parchmentLight = Color(0xFFF1E3C3);
  static const parchmentDark = Color(0xFFD9BE8E);
  static const parchmentSage = Color(0xFFD6DDC3); // the green quest card

  // --- Indigo: the painted border. Primary buttons, nav bar ---
  static const indigo = Color(0xFF4A5498);
  static const indigoDark = Color(0xFF343C78); // button outline, pressed state

  // --- Ink: text on parchment ---
  static const ink = Color(0xFF262B4F); // deep indigo, typed text
  static const inkFaded = Color(0xFF6B5836); // hints, secondary text

  // --- Gold: the border ornaments. Selected state, highlights ---
  static const gold = Color(0xFFE6C77A);
  static const goldLight = Color(0xFFF2DFA2); // titles on dark surfaces

  // --- Red: title lettering, field outlines, urgency ---
  static const wax = Color(0xFFC4514E);
  static const waxDark = Color(0xFF8E2F2A); // error text

  // --- Guild Hall (until it is ported onto the indigo theme) ---
  static const wood = Color(0xFF6B4423);
  static const woodDark = Color(0xFF4A2F18);
  static const stone = Color(0xFF262A27);
  static const stoneLight = Color(0xFF3A3F3A);
  static const torch = Color(0xFFE8892B);
}