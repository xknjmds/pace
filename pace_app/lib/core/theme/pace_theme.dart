import 'package:flutter/material.dart';

import 'pace_colors.dart';
import 'pace_tokens.dart';

/// Calm Material 3 themes in the PACE palette, set in Figtree.
/// No red for user states: the error colour is kept for real failures only,
/// which the UI never shows for missed routines.
abstract final class PaceTheme {
  static const fontFamily = 'Figtree';
  static const tabular = [FontFeature.tabularFigures()];

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: PaceColors.moss,
          dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
        ).copyWith(
          primary: PaceColors.moss,
          onPrimary: Colors.white,
          primaryContainer: PaceColors.mossMist,
          onPrimaryContainer: PaceColors.mossDeep,
          secondary: const Color(0xFF56665F),
          secondaryContainer: const Color(0xFFE3E9E2),
          onSecondaryContainer: const Color(0xFF1E2B26),
          tertiary: PaceColors.dawn,
          tertiaryContainer: PaceColors.dawnMist,
          onTertiaryContainer: const Color(0xFF3D2A07),
          surface: PaceColors.sand,
          onSurface: PaceColors.ink,
          onSurfaceVariant: const Color(0xFF56605B),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: PaceColors.paper,
          surfaceContainer: const Color(0xFFEFE9E0),
          surfaceContainerHigh: PaceColors.sandDeep,
          surfaceContainerHighest: PaceColors.sandHigh,
          outline: const Color(0xFF7D8681),
          outlineVariant: const Color(0xFFDDD5C9),
        );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: PaceColors.moss,
          brightness: Brightness.dark,
        ).copyWith(
          primary: PaceColors.mossLight,
          onPrimary: const Color(0xFF0F2A22),
          primaryContainer: PaceColors.mossNight,
          onPrimaryContainer: PaceColors.mossPale,
          secondary: const Color(0xFFB5C6BE),
          secondaryContainer: const Color(0xFF33423C),
          onSecondaryContainer: const Color(0xFFD6E4DD),
          tertiary: PaceColors.dawnLight,
          tertiaryContainer: PaceColors.dawnNight,
          onTertiaryContainer: const Color(0xFFF6E2BD),
          surface: PaceColors.ink,
          onSurface: const Color(0xFFEDE8DF),
          onSurfaceVariant: const Color(0xFFB4BEB8),
          surfaceContainerLowest: const Color(0xFF151D1A),
          surfaceContainerLow: PaceColors.inkLow,
          surfaceContainer: PaceColors.inkMid,
          surfaceContainerHigh: PaceColors.inkHigh,
          surfaceContainerHighest: PaceColors.inkHighest,
          outline: const Color(0xFF8A9690),
          outlineVariant: const Color(0xFF3A4842),
        );
    return _base(scheme);
  }

  static TextTheme _text(TextTheme colors) {
    // Sizes come in here (not at localisation time) so component styles
    // built from this theme carry them too.
    final t = Typography.englishLike2021.merge(colors);
    TextStyle s(TextStyle? x, FontWeight w, [double tracking = 0]) =>
        x!.copyWith(fontWeight: w, letterSpacing: tracking);
    return t.copyWith(
      displayLarge: s(
        t.displayLarge,
        FontWeight.w600,
        -1.5,
      ).copyWith(fontFeatures: tabular),
      displayMedium: s(
        t.displayMedium,
        FontWeight.w600,
        -1,
      ).copyWith(fontFeatures: tabular),
      displaySmall: s(t.displaySmall, FontWeight.w600, -0.5),
      headlineLarge: s(t.headlineLarge, FontWeight.w700, -0.5),
      headlineMedium: s(t.headlineMedium, FontWeight.w700, -0.4),
      headlineSmall: s(t.headlineSmall, FontWeight.w600, -0.2),
      titleLarge: s(t.titleLarge, FontWeight.w600, -0.2),
      titleMedium: s(t.titleMedium, FontWeight.w600),
      titleSmall: s(t.titleSmall, FontWeight.w600, 0.1),
      bodyLarge: s(t.bodyLarge, FontWeight.w400, 0.1),
      bodyMedium: s(t.bodyMedium, FontWeight.w400, 0.1),
      bodySmall: s(t.bodySmall, FontWeight.w500, 0.2),
      labelLarge: s(t.labelLarge, FontWeight.w600, 0.1),
      labelMedium: s(t.labelMedium, FontWeight.w600, 0.3),
      labelSmall: s(t.labelSmall, FontWeight.w600, 0.4),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, fontFamily: fontFamily);
    final text = _text(base.textTheme);
    const stadium = StadiumBorder();
    const buttonSize = Size(64, 52);
    final buttonText = text.labelLarge!.copyWith(fontSize: 15);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PaceRouteTransitions(),
          TargetPlatform.linux: PaceRouteTransitions(),
          TargetPlatform.windows: PaceRouteTransitions(),
          TargetPlatform.macOS: PaceRouteTransitions(),
          TargetPlatform.fuchsia: PaceRouteTransitions(),
          TargetPlatform.iOS: PaceRouteTransitions(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: text.titleLarge!.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 5),
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: PaceRadius.cardAll,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: stadium,
          textStyle: buttonText,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: stadium, textStyle: buttonText),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 1,
        highlightElevation: 0,
        shape: const StadiumBorder(),
        extendedTextStyle: buttonText,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLow,
        labelStyle: text.labelLarge!.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaceRadius.m),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge!.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outlineVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(PaceRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge!.copyWith(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaceRadius.m),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withValues(alpha: .7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.m),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.m),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaceRadius.m),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaceRadius.m),
        ),
        textStyle: text.bodyLarge,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .7),
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: scheme.surfaceContainerHigh,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

/// Route change: the new screen fades in while rising 4 %, on a strong
/// ease-out. With reduced motion it only fades.
class PaceRouteTransitions extends PageTransitionsBuilder {
  const PaceRouteTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final curved = CurvedAnimation(
      parent: animation,
      curve: PaceMotion.easeOut,
      reverseCurve: Curves.easeIn,
    );
    final faded = FadeTransition(opacity: curved, child: child);
    if (reduced) return faded;
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, .04),
        end: Offset.zero,
      ).animate(curved),
      child: faded,
    );
  }
}
