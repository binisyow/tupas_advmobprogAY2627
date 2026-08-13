// packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// screens
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

// providers
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) async {
    await dotenv.load(fileName: 'assets/.env');
    runApp(const TupasAdvMobProg());
  });
}

class TupasAdvMobProg extends StatelessWidget {
  const TupasAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          final themeModel = build.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _chromeHeartsTheme(Brightness.light),
            darkTheme: _chromeHeartsTheme(Brightness.dark),
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'E-Commerce App',
            initialRoute: '/home',
            routes: {
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }

  ThemeData _chromeHeartsTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const black = Color(0xFF090909);
    const charcoal = Color(0xFF181818);
    const silver = Color(0xFFBFC0C2);
    const bone = Color(0xFFF2F0EB);
    final scheme = ColorScheme.fromSeed(
      seedColor: silver,
      brightness: brightness,
      primary: isDark ? bone : black,
      onPrimary: isDark ? black : bone,
      surface: isDark ? charcoal : bone,
      onSurface: isDark ? bone : black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? black : bone,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? black : bone,
        foregroundColor: isDark ? bone : black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? bone : black,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? charcoal : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r),
          side: const BorderSide(color: silver, width: 0.7),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? charcoal : Colors.white,
        hintStyle: TextStyle(color: isDark ? silver : Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: const BorderSide(color: silver),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: const BorderSide(color: silver),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: isDark ? bone : black, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? charcoal : Colors.white,
        side: const BorderSide(color: silver),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.r)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? black : bone,
        selectedItemColor: isDark ? bone : black,
        unselectedItemColor: isDark ? silver : Colors.black45,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: silver,
    );
  }
}
