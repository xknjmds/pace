import 'package:flutter/material.dart';

import 'pace_colors.dart';
import 'pace_pastels.dart';
import 'pace_tokens.dart';

/// Calm Material 3 themes in the PACE palette, set in Figtree.
/// No red for user states: the error colour is kept for real failures only,
/// which the UI never shows for missed routines.
abstract final class PaceTheme {
  static const fontFamily = 'Figtree';
  static const tabular = [FontFeature.tabularFigures()];

  /// Off-white page, white cards, soft-ink actions, mint for selected
  /// states, Moss as the accent.
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: PaceColors.moss,
          dynamicSchemeVariant: DynamicSchemeVariant.neutral,
        ).copyWith(
          primary: PaceColors.softInk,
          onPrimary: PaceColors.offWhite,
          primaryContainer: PaceColors.mint,
          onPrimaryContainer: PaceColors.text,
          secondary: PaceColors.moss,
          onSecondary: PaceColors.white,
          secondaryContainer: const Color(0xFFE4EAE3),
          onSecondaryContainer: PaceColors.text,
          tertiary: PaceColors.dawn,
          onTertiary: PaceColors.white,
          tertiaryContainer: PaceColors.dawnMist,
          onTertiaryContainer: const Color(0xFF3D2A07),
          surface: PaceColors.offWhite,
          onSurface: PaceColors.text,
          onSurfaceVariant: PaceColors.textSoft,
          surfaceContainerLowest: PaceColors.white,
          surfaceContainerLow: PaceColors.white,
          surfaceContainer: PaceColors.mist,
          surfaceContainerHigh: PaceColors.sunken,
          surfaceContainerHighest: PaceColors.sunkenDeep,
          outline: PaceColors.line,
          outlineVariant: PaceColors.lineSoft,
          inverseSurface: PaceColors.softInk,
          onInverseSurface: PaceColors.offWhite,
          inversePrimary: PaceColors.mossLight,
          surfaceTint: Colors.transparent,
        );
    return _base(scheme);
  }

  /// Soft charcoal page, lifted cards, paper-white actions, deep mint for
  /// selected states, Moss light as the accent.
  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: PaceColors.moss,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.neutral,
        ).copyWith(
          primary: PaceColors.paper,
          onPrimary: PaceColors.charcoal,
          primaryContainer: PaceColors.mintNight,
          onPrimaryContainer: PaceColors.textNight,
          secondary: PaceColors.mossLight,
          onSecondary: const Color(0xFF14231E),
          secondaryContainer: const Color(0xFF2C3833),
          onSecondaryContainer: PaceColors.textNight,
          tertiary: PaceColors.dawnLight,
          onTertiary: const Color(0xFF2A1E08),
          tertiaryContainer: PaceColors.dawnNight,
          onTertiaryContainer: const Color(0xFFF6E2BD),
          surface: PaceColors.charcoal,
          onSurface: PaceColors.textNight,
          onSurfaceVariant: PaceColors.textNightSoft,
          surfaceContainerLowest: PaceColors.charcoalDeep,
          surfaceContainerLow: PaceColors.charcoalCard,
          surfaceContainer: PaceColors.charcoalMid,
          surfaceContainerHigh: PaceColors.charcoalHigh,
          surfaceContainerHighest: PaceColors.charcoalHighest,
          outline: PaceColors.lineNight,
          outlineVariant: PaceColors.lineNightSoft,
          inverseSurface: PaceColors.textNight,
          onInverseSurface: PaceColors.charcoal,
          inversePrimary: PaceColors.moss,
          surfaceTint: Colors.transparent,
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
      extensions: [
        scheme.brightness == Brightness.dark
            ? PacePastels.dark
            : PacePastels.light,
      ],
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
        // White cards lift off the off-white page with a whisper of
        // shadow; on charcoal the lighter fill does that job.
        elevation: scheme.brightness == Brightness.light ? 1 : 0,
        shadowColor: const Color(0x1A1C1D20),
        margin: const EdgeInsets.symmetric(vertical: 5),
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        // Borderless: blocks are told apart by fill and lift, not lines.
        shape: const RoundedRectangleBorder(borderRadius: PaceRadius.cardAll),
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
        backgroundColor: Colors.transparent,
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
          borderSide: BorderSide(color: scheme.secondary, width: 1.5),
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
        color: scheme.secondary,
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
