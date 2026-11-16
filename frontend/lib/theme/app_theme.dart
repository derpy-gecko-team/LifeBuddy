import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Font families registered in pubspec.yaml.
abstract final class AppFonts {
  /// Calligraphic script. Big titles only: it is hard to read at small sizes.
  static const String display = 'NorthEternal';

  /// Text people actually read: inputs, buttons, body copy.
  /// null = system font for now. Once we pick the hand-drawn body font shared
  /// with the Guild Hall, set it here and every screen follows.
  /// (To use MySoul everywhere: `static const String? body = display;`)
  static const String? body = null;
}

abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.indigo,
          onPrimary: AppColors.parchmentLight,
          secondary: AppColors.gold,
          onSecondary: AppColors.ink,
          tertiary: AppColors.wax,
          surface: AppColors.parchment,
          onSurface: AppColors.ink,
          error: AppColors.waxDark,
          onError: AppColors.parchmentLight,
        );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    final textTheme = base.textTheme
        .apply(
          fontFamily: AppFonts.body,
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        )
        .copyWith(
          // Screen titles ("Login"): script font, red like the mock-up.
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontFamily: AppFonts.display,
            fontSize: 64,
            height: 1.1,
            color: AppColors.wax,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.parchment,
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.indigo,
        selectionHandleColor: AppColors.indigo,
        selectionColor: AppColors.indigo.withValues(alpha: 0.25),
      ),
      // Primary action: blue like the painted border.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: AppColors.parchmentLight,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.titleMedium?.copyWith(
            fontFamily: AppFonts.display,
            fontSize: 18,
            height: 1.2,
            leadingDistribution: TextLeadingDistribution.even,
          ),
          padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.indigoDark, width: 2),
          ),
        ),
      ),
      // Secondary actions stay quiet (faded tan in the mock-up).
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.inkFaded),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.inkFaded),
      ),
      // Indigo bar with gold selection, like the border ornaments.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.indigo,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.gold.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.parchment,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? AppColors.goldLight
                : AppColors.parchment,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.indigoDark,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
          color: AppColors.parchmentLight,
        ),
      ),
    );
  }
}
