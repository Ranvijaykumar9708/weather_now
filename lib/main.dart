import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:weather_now/app/bindings/app_binding.dart';
import 'package:weather_now/app/controllers/weather_Controller.dart';
import 'package:weather_now/app/ui/screens/splash_screen.dart';
import 'package:weather_now/repositories/weather_repository.dart';
import 'package:weather_now/repositories/weather_repository_impl.dart';
import 'package:weather_now/utils/translations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize WeatherController early to sync theme mode
    final WeatherController controller = Get.put(WeatherController(weatherRepository: WeatherRepositoryImpl()), permanent: true);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Now'.tr,
      initialBinding: AppBinding(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
          primary: Colors.blueAccent,
          secondary: Colors.cyan,
          background: Colors.grey[100],
          surface: Colors.white.withOpacity(0.9),
        ),
        scaffoldBackgroundColor: Colors.transparent, // For gradient backgrounds
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black87,
          size: 24,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.black54),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
          primary: Colors.blueGrey,
          secondary: Colors.cyanAccent,
          background: Colors.grey[900],
          surface: Colors.black.withOpacity(0.3),
        ),
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white70,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.white60,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.white54,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white70,
          size: 24,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
          ),
          hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.white54),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      themeMode: controller.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen()
          .animate()
          .fadeIn(duration: 800.ms)
          .scale(curve: Curves.easeInOut)
          .then()
          .shimmer(duration: 1000.ms, color: Colors.white24),
      translations: AppTranslations(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('hi', 'IN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}