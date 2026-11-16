import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours of the Buddy's campfire, taken from the Figma frame "Buddy – Idle v4".
abstract final class BuddyColors {
  static const night = Color(0xFF0F1230);
  static const outline = Color(0xFF15142A);

  static const card = Color(0xFFDCC6A0);
  static const cardShade = Color(0xFFC4AA7E); // the rods of the writing scroll
  static const cardLight = Color(0xFFECDCB9);
  static const ink = Color(0xFF2A2C57);
  static const inkFaded = Color(0xFF8B7458);
  static const name = Color(0xFFC4514B);

  static const cream = Color(0xFFF4E3C3);
  static const leather = Color(0xFF8A5A3B);

  // Old messages, up in the sky: Pip's in warm campfire smoke, the hero's in
  // cooler night mist. Body, and the paler billowing edge.
  static const smokeWarm = Color(0xFF453C56);
  static const smokeRimWarm = Color(0xFFC9B79A);
  static const smokeCool = Color(0xFF2E3A66);
  static const smokeRimCool = Color(0xFF9DABD6);
}

abstract final class BuddyAssets {
  static const _dir = 'assets/images/buddy';

  static const forest = '$_dir/forest.png';
  static const campfire = '$_dir/campfire.png';
  static const pip = '$_dir/pip.png';
  static const pawSeal = '$_dir/paw_seal.png';
  static const heyPipButton = '$_dir/hey_pip_button.png';
  static const quill = '$_dir/quill.png';
  static const cloud = '$_dir/cloud.png';
}

abstract final class BuddyText {
  static final _hand = GoogleFonts.deliciousHandrawn();
  static final _serif = GoogleFonts.grenze(fontWeight: FontWeight.w700);

  static Future<void> preload() async {
    _hand;
    _serif;
    try {
      await GoogleFonts.pendingFonts();
    } catch (_) {}
  }

  /// Handwriting: what the Buddy says, what the hero writes.
  static TextStyle hand(double size, {Color color = BuddyColors.ink, double height = 1.3}) =>
      _hand.copyWith(fontSize: size, color: color, height: height, letterSpacing: 0.2, wordSpacing: size * 0.14);

  /// Carved lettering: the Buddy's name, the ribbon on the horn.
  static TextStyle serif(double size, {Color color = BuddyColors.ink, double spacing = 0}) =>
      _serif.copyWith(fontSize: size, color: color, height: 1, letterSpacing: spacing);
}
