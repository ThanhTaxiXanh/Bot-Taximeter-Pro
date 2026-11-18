import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_config.dart';

/// Token màu dùng chung cho toàn bộ ứng dụng.
abstract final class AppColors {
  static const Color backgroundStart = Color(0xFF06152B);
  static const Color backgroundEnd = Color(0xFF0A2342);
  static const Color navyInk = Color(0xFF06182E);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color cyanBright = Color(0xFF2EE8FF);
  static const Color cyanDeep = Color(0xFF00CFF0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF9FB3C8);
  static const Color success = Color(0xFF3DDC84);
  static const Color danger = Color(0xFFFF5252);
  static const Color poi = Color(0xFFFF3FA4);
  static const Color glass = Color.fromRGBO(10, 35, 70, 0.65);
  static const Color border = Color.fromRGBO(0, 229, 255, 0.45);
  static const Color borderActive = Color.fromRGBO(0, 229, 255, 0.9);
  static const Color dangerGlass = Color.fromRGBO(255, 82, 82, 0.12);

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[backgroundStart, backgroundEnd],
  );
  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[cyanBright, cyanDeep],
  );
}

/// Theme tối với Be Vietnam Pro; CI dùng font hệ thống, không tải mạng.
abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundStart,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cyan,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.cyan,
        onPrimary: AppColors.navyInk,
        surface: AppColors.backgroundEnd,
        onSurface: AppColors.white,
      ),
    );
    final text = kCI
        ? base.textTheme
        : GoogleFonts.beVietnamProTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: text.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundStart,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.cyan),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glass,
        hintStyle: const TextStyle(color: AppColors.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
      ),
    );
  }
}
