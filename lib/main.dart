import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/main_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;
  
  runApp(MyApp(initialDarkMode: isDark));
}

class MyApp extends StatelessWidget {
  final bool initialDarkMode;
  
  const MyApp({super.key, this.initialDarkMode = false});
  
  static late ValueNotifier<ThemeMode> themeNotifier;

  @override
  Widget build(BuildContext context) {
    themeNotifier = ValueNotifier(initialDarkMode ? ThemeMode.dark : ThemeMode.light);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'จัดการเงินส่วนตัว',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          initialRoute: '/lock',
          routes: {
            '/lock': (context) => const LockScreen(),
            '/': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/categories': (context) => const CategoriesScreen(),
            '/dashboard': (context) => const MainScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    final primaryColor = const Color(0xFF4F46E5);
    final secondaryColor = const Color(0xFF06B6D4);
    final errorColor = const Color(0xFFF43F5E);
    final backgroundColor = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final surfaceColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
    final textColor = isDark ? Colors.white : Colors.black87;

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.promptTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : primaryColor,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : primaryColor,
          fontFamily: GoogleFonts.prompt().fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : primaryColor);
          }
          return TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: backgroundColor,
      ),
    );
  }
}
