import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex =
          prefs.getInt(_themeKey) ?? 0; // 0: system, 1: light, 2: dark
      _themeMode = ThemeMode.values[themeIndex];
    } catch (e) {
      _themeMode = ThemeMode.system;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  // Enhanced Light Theme - Modern Material Design 3
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Modern color scheme with enhanced contrast and accessibility
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFFDCEDC8),
      tertiary: Color(0xFF26A69A),
      surface: Color(0xFFFEFEFE),
      surfaceContainerHighest: Color(0xFFF5F5F5),
      surfaceContainerLow: Color(0xFFF8F9FA),
      surfaceContainer: Color(0xFFF1F3F4),
      surfaceContainerHigh: Color(0xFFECEFF1),
      error: Color(0xFFD32F2F),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFF1C1B1F),
      onSurfaceVariant: Color(0xFF49454F),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFCAC4D0),
      outlineVariant: Color(0xFFCAC4D0),
    ),

    // Enhanced App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFEFEFE),
      foregroundColor: Color(0xFF1C1B1F),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C1B1F),
      ),
    ),

    // Enhanced Card Theme
    cardTheme: CardThemeData(
      color: const Color(0xFFFEFEFE),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Enhanced Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Enhanced Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF1976D2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Enhanced Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7F2FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCAC4D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCAC4D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      hintStyle: const TextStyle(color: Color(0xFF49454F)),
      labelStyle: const TextStyle(color: Color(0xFF1C1B1F)),
    ),

    // Enhanced Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF1976D2);
        }
        return const Color(0xFFFFFFFF);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF90CAF9);
        }
        return const Color(0xFFCAC4D0);
      }),
    ),

    // Enhanced Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1976D2),
      foregroundColor: Colors.white,
    ),

    // Enhanced Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Color(0xFFFEFEFE),
      indicatorColor: Color(0xFF1976D2).withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color:
              Color(0xFF49454F), // onSurfaceVariant color for better contrast
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: Color(0xFF1976D2),
          );
        }
        return const IconThemeData(
          color:
              Color(0xFF49454F), // onSurfaceVariant color for better contrast
        );
      }),
    ),

    // Enhanced Typography with Material Design 3 scale
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
        color: Color(0xFF1C1B1F),
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
        color: Color(0xFF1C1B1F),
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
        color: Color(0xFF1C1B1F),
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: Color(0xFF1C1B1F),
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.29,
        color: Color(0xFF1C1B1F),
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: Color(0xFF1C1B1F),
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
        color: Color(0xFF1C1B1F),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: Color(0xFF1C1B1F),
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        color: Color(0xFF1C1B1F),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: Color(0xFF1C1B1F),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        color: Color(0xFF1C1B1F),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: Color(0xFF1C1B1F),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        color: Color(0xFF1C1B1F),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        color: Color(0xFF1C1B1F),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: Color(0xFF1C1B1F),
      ),
    ),
  );

  // Enhanced Dark Theme - Modern Material Design 3
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Modern dark color scheme
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF90CAF9),
      secondary: Color(0xFF81C784),
      tertiary: Color(0xFF4DB6AC),
      surface: Color(0xFF121212),
      surfaceContainerHighest: Color(0xFF1E1E1E),
      surfaceContainerLow: Color(0xFF1E1E1E),
      surfaceContainer: Color(0xFF252525),
      surfaceContainerHigh: Color(0xFF2D2D2D),
      error: Color(0xFFEF5350),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFE0E0E0),
      onSurfaceVariant: Color(0xFFCAC4D0),
      onError: Color(0xFF000000),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
    ),

    // Enhanced App Bar Theme for dark mode
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE0E0E0),
      ),
    ),

    // Enhanced Card Theme for dark mode
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      shadowColor: Colors.black.withValues(alpha: 0.3),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Enhanced Button Themes for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF90CAF9),
        foregroundColor: Color(0xFF000000),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Enhanced Text Button Theme for dark mode
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF90CAF9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Enhanced Input Decoration Theme for dark mode
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF49454F)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF49454F)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      hintStyle: const TextStyle(color: Color(0xFFCAC4D0)),
      labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
    ),

    // Enhanced Switch Theme for dark mode
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF90CAF9);
        }
        return const Color(0xFF1E1E1E);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF1976D2);
        }
        return const Color(0xFF49454F);
      }),
    ),

    // Enhanced Floating Action Button Theme for dark mode
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF90CAF9),
      foregroundColor: Color(0xFF000000),
    ),

    // Enhanced Navigation Bar Theme for dark mode
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Color(0xFF121212),
      indicatorColor: Color(0xFF90CAF9).withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF90CAF9),
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(
              0xFFCAC4D0), // onSurfaceVariant color for better contrast in dark mode
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: Color(0xFF90CAF9),
          );
        }
        return const IconThemeData(
          color: Color(
              0xFFCAC4D0), // onSurfaceVariant color for better contrast in dark mode
        );
      }),
    ),

    // Enhanced Typography for dark mode
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
        color: Color(0xFFE0E0E0),
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
        color: Color(0xFFE0E0E0),
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
        color: Color(0xFFE0E0E0),
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: Color(0xFFE0E0E0),
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.29,
        color: Color(0xFFE0E0E0),
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: Color(0xFFE0E0E0),
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
        color: Color(0xFFE0E0E0),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: Color(0xFFE0E0E0),
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        color: Color(0xFFE0E0E0),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: Color(0xFFE0E0E0),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        color: Color(0xFFE0E0E0),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: Color(0xFFE0E0E0),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        color: Color(0xFFE0E0E0),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        color: Color(0xFFE0E0E0),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: Color(0xFFE0E0E0),
      ),
    ),
  );

  // Material themes
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
}
