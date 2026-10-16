import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Light theme.
ThemeData get lightTheme => _themeFor(AppColors.lightColorScheme);

/// Dark theme.
ThemeData get darkTheme => _themeFor(AppColors.darkColorScheme);

/// Builds a complete theme from a colour scheme.
///
/// Both brightnesses deliberately go through this single function.
///
/// An earlier version configured the component themes for the light theme only,
/// which caused two problems at once:
///
///  * dark mode silently lost every radius, padding, size and app-bar setting,
///    because an unset component theme means "use the framework default";
///  * more seriously, it crashed. In this `material_ui` fork the text *geometry*
///    themes are declared with `inherit: false`, and `ThemeData.localize` does
///    `localTextGeometry.merge(baseTheme.textTheme)`. Since `TextStyle.merge`
///    keeps the receiver's `inherit`, every `Theme.of(context).textTheme.*`
///    style ends up `inherit: false`. The light theme pinned its button
///    `textStyle` to [AppTextStyles] (`inherit: true`), while the dark theme
///    fell back to `Theme.of(context).textTheme.labelLarge` (`inherit: false`).
///    `Material` animates its `textStyle` through `AnimatedDefaultTextStyle`,
///    and `TextStyle.lerp` asserts when the two endpoints disagree on `inherit`
///    - so merely restoring a saved dark theme threw
///    "Failed to interpolate TextStyles with different inherit values" for
///    every button on screen.
///
/// Keeping one builder means both endpoints always come from [AppTextStyles],
/// which fixes the crash and the missing dark styling together. For the same
/// reason this function does not set `textStyle` on `iconButtonTheme` or
/// `labelTextStyle` on `navigationBarTheme`: leaving those on the framework
/// default keeps them consistently sourced in both themes.
ThemeData _themeFor(ColorScheme colorScheme) {
  final bool isDark = colorScheme.brightness == Brightness.dark;

  // The one style every button in the app uses, from a single source.
  final TextStyle labelStyle = AppTextStyles.labelLarge.copyWith(
    fontWeight: FontWeight.w600,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: AppTextStyles.textTheme,
    primaryTextTheme: AppTextStyles.textTheme,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: colorScheme.shadow,
      toolbarHeight: 56.h,
      leadingWidth: 80.w,
      titleSpacing: 0,
      titleTextStyle: AppTextStyles.titleLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24.r),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface, size: 24.r),
      // Status-bar icon brightness follows the theme: dark glyphs on a light
      // surface, light glyphs on a dark one. The previous hard-coded values
      // asked for light icons on a light background, which made them vanish.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        // iOS inverts this one: it describes the background, not the glyphs.
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        minimumSize: Size(double.infinity.w, 48.h),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        textStyle: labelStyle,
        animationDuration: const Duration(milliseconds: 200),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        side: BorderSide(color: colorScheme.primary, width: 1.w),
        disabledBackgroundColor: Colors.transparent,
        minimumSize: Size(double.infinity.w, 48.h),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        textStyle: labelStyle,
        animationDuration: const Duration(milliseconds: 200),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
        minimumSize: Size(0, 48.h),
        textStyle: labelStyle,
        animationDuration: const Duration(milliseconds: 200),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surface,
        padding: EdgeInsets.zero,
        minimumSize: Size(40.w, 40.h),
        shape: const CircleBorder(),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),

      // Border styles
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: colorScheme.outline, width: 1.w),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: colorScheme.outline, width: 1.w),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: colorScheme.error, width: 1.w),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: colorScheme.error, width: 2.w),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.38),
          width: 1.w,
        ),
      ),

      // Typography
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      errorStyle: AppTextStyles.bodySmall.copyWith(color: colorScheme.error),
      helperStyle: AppTextStyles.bodySmall.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),

      // Behavior
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      alignLabelWithHint: true,
    ),

    // Bottom navigation (Material 3 `NavigationBar`, which the app shell uses).
    navigationBarTheme: NavigationBarThemeData(
      height: 66.h,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      elevation: 0,
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(thickness: 1.w, space: 1.h),
  );
}
