import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Radios del diseño (Turco Parcial Design.pen · Guía de estilo).
abstract final class AppRadius {
  /// Tarjetas: radio 16 (cardTheme).
  static const double card = 16;

  /// Campos: radio 12 (inputDecorationTheme).
  static const double field = 12;
  static const double chip = 8;
  static const double badge = 8;
  static const double sheet = 28;
  static const double dialog = 28;
  static const double dayTile = 18;
  static const double slot = 10;
  static const double summary = 14;
  static const double search = 24;
  static const double logo = 10;
  static const double fab = 16;
  static const double snack = 8;
}

/// Espacios del diseño.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Relleno del contenido de las pantallas: [4, 16, 16, 16].
  static const EdgeInsets pantalla = EdgeInsets.fromLTRB(16, 4, 16, 16);
  static const EdgeInsets tarjeta = EdgeInsets.all(16);
  static const EdgeInsets hoja = EdgeInsets.fromLTRB(20, 0, 20, 20);
}

/// Tema global claro y oscuro de Turco (Material 3, Poppins, seed 0xFF00695C).
///
/// Todos los colores de pantallas y widgets salen de [ColorScheme]: no hay
/// colores fijos fuera de este archivo.
abstract final class AppTheme {
  static const Color seed = Color(0xFF00695C);
  static const String fuente = 'Poppins';

  static ColorScheme get _esquemaClaro => ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF006A60),
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFF9EF2E4),
        onPrimaryContainer: const Color(0xFF00201C),
        secondaryContainer: const Color(0xFFCCE8E2),
        onSecondaryContainer: const Color(0xFF05201C),
        tertiary: const Color(0xFF456179),
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: const Color(0xFFCDE5FF),
        onTertiaryContainer: const Color(0xFF001D32),
        error: const Color(0xFFBA1A1A),
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFFFDAD6),
        onErrorContainer: const Color(0xFF410002),
        surface: const Color(0xFFF4FBF9),
        onSurface: const Color(0xFF161D1C),
        onSurfaceVariant: const Color(0xFF3F4947),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFEEF5F3),
        surfaceContainer: const Color(0xFFE9EFED),
        surfaceContainerHigh: const Color(0xFFE3EAE8),
        surfaceContainerHighest: const Color(0xFFE3EAE8),
        outline: const Color(0xFF6F7977),
        outlineVariant: const Color(0xFFBEC9C6),
        inverseSurface: const Color(0xFF2B3231),
        onInverseSurface: const Color(0xFFF4FBF9),
        inversePrimary: const Color(0xFF74F8E5),
      );

  static ColorScheme get _esquemaOscuro => ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF53DBC9),
        onPrimary: const Color(0xFF003731),
        primaryContainer: const Color(0xFF005047),
        onPrimaryContainer: const Color(0xFF74F8E5),
        secondaryContainer: const Color(0xFF314B47),
        onSecondaryContainer: const Color(0xFFCCE8E2),
        tertiary: const Color(0xFFADCAE6),
        onTertiary: const Color(0xFF153349),
        tertiaryContainer: const Color(0xFF2D4960),
        onTertiaryContainer: const Color(0xFFCDE5FF),
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
        errorContainer: const Color(0xFF93000A),
        onErrorContainer: const Color(0xFFFFDAD6),
        surface: const Color(0xFF0E1514),
        onSurface: const Color(0xFFDDE4E2),
        onSurfaceVariant: const Color(0xFFBEC9C6),
        surfaceContainerLowest: const Color(0xFF090F0F),
        surfaceContainerLow: const Color(0xFF161D1C),
        surfaceContainer: const Color(0xFF1A2120),
        surfaceContainerHigh: const Color(0xFF252B2A),
        surfaceContainerHighest: const Color(0xFF2F3635),
        outline: const Color(0xFF899390),
        outlineVariant: const Color(0xFF3F4947),
        inverseSurface: const Color(0xFFDDE4E2),
        onInverseSurface: const Color(0xFF2B3231),
        inversePrimary: const Color(0xFF006A60),
      );

  static ThemeData get claro => _tema(_esquemaClaro);
  static ThemeData get oscuro => _tema(_esquemaOscuro);

  /// Tipografía Poppins: headlineSmall 24 SemiBold, titleLarge 22 SemiBold,
  /// titleMedium 16 Medium, bodyMedium 14 Regular, labelSmall 11 Medium.
  static TextTheme _texto(ColorScheme s) {
    const f = fuente;
    return const TextTheme(
      headlineMedium: TextStyle(fontFamily: f, fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontFamily: f, fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: f, fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontFamily: f, fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: f, fontSize: 15, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontFamily: f, fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontFamily: f, fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontFamily: f, fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontFamily: f, fontSize: 13, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontFamily: f, fontSize: 11, fontWeight: FontWeight.w500),
    ).apply(bodyColor: s.onSurface, displayColor: s.onSurface);
  }

  static ThemeData _tema(ColorScheme s) {
    final t = _texto(s);
    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: s.outline),
    );
    final bordeError = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: s.error, width: 2),
    );
    const pastilla = StadiumBorder();
    const tamBoton = Size(64, 46);

    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      brightness: s.brightness,
      fontFamily: fuente,
      textTheme: t,
      scaffoldBackgroundColor: s.surface,
      canvasColor: s.surface,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: s.surface,
        foregroundColor: s.onSurface,
        surfaceTintColor: s.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        titleSpacing: 16,
        titleTextStyle: t.titleLarge?.copyWith(fontSize: 20, color: s.onSurface),
        iconTheme: IconThemeData(color: s.onSurface),
        actionsIconTheme: IconThemeData(color: s.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: s.surfaceContainer,
        surfaceTintColor: s.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(borderSide: BorderSide(color: s.primary, width: 2)),
        errorBorder: bordeError,
        focusedErrorBorder: bordeError,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        hintStyle: t.bodyMedium?.copyWith(color: s.outline),
        labelStyle: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
        errorStyle: t.bodySmall?.copyWith(color: s.error),
        helperStyle: t.labelSmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w400),
        counterStyle: t.labelSmall?.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w400),
        prefixIconColor: s.onSurfaceVariant,
        suffixIconColor: s.onSurfaceVariant,
        errorMaxLines: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: tamBoton,
          shape: pastilla,
          textStyle: t.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: tamBoton,
          shape: pastilla,
          textStyle: t.labelLarge,
          foregroundColor: s.primary,
          side: BorderSide(color: s.outline),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: t.labelLarge, foregroundColor: s.primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: s.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: s.primaryContainer,
        foregroundColor: s.onPrimaryContainer,
        elevation: 3,
        extendedTextStyle: t.labelLarge,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.fab)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surfaceContainer,
        surfaceTintColor: s.surfaceContainer,
        indicatorColor: s.secondaryContainer,
        elevation: 0,
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 22,
              color: states.contains(WidgetState.selected)
                  ? s.onSecondaryContainer
                  : s.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? t.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: s.onSurface)
                : t.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: s.onSurfaceVariant)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
        side: WidgetStateBorderSide.resolveWith((states) => states.contains(WidgetState.selected)
            ? BorderSide(color: s.secondaryContainer)
            : BorderSide(color: s.outlineVariant)),
        labelStyle: t.labelMedium?.copyWith(color: s.onSurfaceVariant),
        secondaryLabelStyle: t.labelMedium?.copyWith(color: s.onSecondaryContainer),
        selectedColor: s.secondaryContainer,
        backgroundColor: s.surface.withValues(alpha: 0),
        checkmarkColor: s.onSecondaryContainer,
        showCheckmark: true,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(t.labelMedium),
          minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
          side: WidgetStatePropertyAll(BorderSide(color: s.outline)),
          visualDensity: VisualDensity.standard,
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? s.secondaryContainer : s.surface.withValues(alpha: 0)),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? s.onSecondaryContainer : s.onSurface),
          iconColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? s.onSecondaryContainer : s.onSurface),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceContainer,
        surfaceTintColor: s.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
        iconColor: s.error,
        titleTextStyle: t.titleLarge?.copyWith(fontSize: 20, color: s.onSurface),
        contentTextStyle: t.bodyMedium?.copyWith(color: s.onSurfaceVariant, height: 1.45),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: s.surface,
        modalBackgroundColor: s.surface,
        showDragHandle: true,
        dragHandleColor: s.outlineVariant,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s.inverseSurface,
        actionTextColor: s.inversePrimary,
        contentTextStyle: t.bodyMedium?.copyWith(color: s.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.snack)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: s.surfaceContainerHighest,
        surfaceTintColor: s.surfaceContainerHighest,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
        textStyle: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: s.onSurface),
      ),
      dividerTheme: DividerThemeData(color: s.outlineVariant, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: s.onSurfaceVariant,
        titleTextStyle: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: s.onSurface),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: s.surfaceContainer,
        surfaceTintColor: s.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(s.outline.withValues(alpha: 0.6)),
        radius: const Radius.circular(4),
      ),
    );
  }
}

/// Colores de estado de un turno, siempre derivados del [ColorScheme].
class ColoresEstado {
  const ColoresEstado(this.acento, this.contenedor, this.sobreContenedor);

  final Color acento;
  final Color contenedor;
  final Color sobreContenedor;

  factory ColoresEstado.de(ColorScheme s, EstadoTurno estado) {
    switch (estado) {
      case EstadoTurno.programado:
        return ColoresEstado(s.primary, s.primaryContainer, s.onPrimaryContainer);
      case EstadoTurno.completado:
        return ColoresEstado(s.tertiary, s.tertiaryContainer, s.onTertiaryContainer);
      case EstadoTurno.cancelado:
        return ColoresEstado(s.error, s.errorContainer, s.onErrorContainer);
    }
  }
}
