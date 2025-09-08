import 'package:flutter/material.dart';

class AppThemeTemplate {
  final String id;
  final String nameEn;
  final String nameTr;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Brightness brightness;
  final String previewImagePath;

  const AppThemeTemplate({
    required this.id,
    required this.nameEn,
    required this.nameTr,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.brightness,
    required this.previewImagePath,
  });

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
        onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      iconTheme: IconThemeData(color: primaryColor),
      primaryIconTheme: IconThemeData(color: primaryColor),
      scaffoldBackgroundColor: backgroundColor,
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AppThemeTemplates {
  static const List<AppThemeTemplate> templates = [
    // Modern Blue (Default)
    AppThemeTemplate(
      id: 'modern_blue',
      nameEn: 'Modern Blue',
      nameTr: 'Modern Mavi',
      description: 'Clean and professional blue theme',
      primaryColor: Color(0xFF1976D2),
      secondaryColor: Color(0xFF42A5F5),
      backgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textPrimary: Color(0xFF212121),
      textSecondary: Color(0xFF757575),
      brightness: Brightness.light,
      previewImagePath: 'assets/themes/modern_blue.png',
    ),

    // Modern Blue Dark
    AppThemeTemplate(
      id: 'modern_blue_dark',
      nameEn: 'Modern Blue Dark',
      nameTr: 'Modern Mavi Karanlık',
      description: 'Dark version of modern blue theme',
      primaryColor: Color(0xFF90CAF9),
      secondaryColor: Color(0xFF42A5F5),
      backgroundColor: Color(0xFF1A1A1A),
      cardColor: Color(0xFF2D2D2D),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFB0BEC5),
      brightness: Brightness.dark,
      previewImagePath: 'assets/themes/modern_blue_dark.png',
    ),

    // Forest Green
    AppThemeTemplate(
      id: 'forest_green',
      nameEn: 'Forest Green',
      nameTr: 'Orman Yeşili',
      description: 'Natural green theme for nature lovers',
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF66BB6A),
      backgroundColor: Color(0xFFF1F8E9),
      cardColor: Colors.white,
      textPrimary: Color(0xFF1B5E20),
      textSecondary: Color(0xFF4CAF50),
      brightness: Brightness.light,
      previewImagePath: 'assets/themes/forest_green.png',
    ),

    // Forest Green Dark
    AppThemeTemplate(
      id: 'forest_green_dark',
      nameEn: 'Forest Green Dark',
      nameTr: 'Orman Yeşili Karanlık',
      description: 'Dark version of forest green theme',
      primaryColor: Color(0xFF81C784),
      secondaryColor: Color(0xFF66BB6A),
      backgroundColor: Color(0xFF1A1A1A),
      cardColor: Color(0xFF2D2D2D),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFA5D6A7),
      brightness: Brightness.dark,
      previewImagePath: 'assets/themes/forest_green_dark.png',
    ),

    // Sunset Orange
    AppThemeTemplate(
      id: 'sunset_orange',
      nameEn: 'Sunset Orange',
      nameTr: 'Gün Batımı Turuncu',
      description: 'Warm and energetic orange theme',
      primaryColor: Color(0xFFE65100),
      secondaryColor: Color(0xFFFF9800),
      backgroundColor: Color(0xFFFFF3E0),
      cardColor: Colors.white,
      textPrimary: Color(0xFFBF360C),
      textSecondary: Color(0xFFFF5722),
      brightness: Brightness.light,
      previewImagePath: 'assets/themes/sunset_orange.png',
    ),

    // Sunset Orange Dark
    AppThemeTemplate(
      id: 'sunset_orange_dark',
      nameEn: 'Sunset Orange Dark',
      nameTr: 'Gün Batımı Turuncu Karanlık',
      description: 'Dark version of sunset orange theme',
      primaryColor: Color(0xFFFFB74D),
      secondaryColor: Color(0xFFFF9800),
      backgroundColor: Color(0xFF1A1A1A),
      cardColor: Color(0xFF2D2D2D),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFFFCC02),
      brightness: Brightness.dark,
      previewImagePath: 'assets/themes/sunset_orange_dark.png',
    ),

    // Royal Purple
    AppThemeTemplate(
      id: 'royal_purple',
      nameEn: 'Royal Purple',
      nameTr: 'Kraliyet Moru',
      description: 'Elegant purple theme with luxury feel',
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFFAB47BC),
      backgroundColor: Color(0xFFF3E5F5),
      cardColor: Colors.white,
      textPrimary: Color(0xFF4A148C),
      textSecondary: Color(0xFF9C27B0),
      brightness: Brightness.light,
      previewImagePath: 'assets/themes/royal_purple.png',
    ),

    // Royal Purple Dark
    AppThemeTemplate(
      id: 'royal_purple_dark',
      nameEn: 'Royal Purple Dark',
      nameTr: 'Kraliyet Moru Karanlık',
      description: 'Dark version of royal purple theme',
      primaryColor: Color(0xFFBA68C8),
      secondaryColor: Color(0xFFAB47BC),
      backgroundColor: Color(0xFF1A1A1A),
      cardColor: Color(0xFF2D2D2D),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFCE93D8),
      brightness: Brightness.dark,
      previewImagePath: 'assets/themes/royal_purple_dark.png',
    ),

    // Midnight Dark (Keep existing)
    AppThemeTemplate(
      id: 'midnight_dark',
      nameEn: 'Midnight Dark',
      nameTr: 'Gece Yarısı Karanlık',
      description: 'Sleek dark theme for night owls',
      primaryColor: Color(0xFF90CAF9),
      secondaryColor: Color(0xFF42A5F5),
      backgroundColor: Color(0xFF1A1A1A),
      cardColor: Color(0xFF2D2D2D),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFB0BEC5),
      brightness: Brightness.dark,
      previewImagePath: 'assets/themes/midnight_dark.png',
    ),

    // Rose Gold
    AppThemeTemplate(
      id: 'rose_gold',
      nameEn: 'Rose Gold',
      nameTr: 'Altın Gülü',
      description: 'Elegant rose gold theme',
      primaryColor: Color(0xFFAD1457),
      secondaryColor: Color(0xFFE91E63),
      backgroundColor: Color(0xFFFCE4EC),
      cardColor: Colors.white,
      textPrimary: Color(0xFF880E4F),
      textSecondary: Color(0xFFC2185B),
      brightness: Brightness.light,
      previewImagePath: 'assets/themes/rose_gold.png',
    ),

    // Rose Gold Dark
    AppThemeTemplate(
      id: 'rose_gold_dark',
      nameEn: 'Rose Gold Dark',
      nameTr: 'Altın Gülü Karanlık',
      description: 'Dark version of rose gold theme',
      primaryColor: Color(0xFFF48FB1),
      secondaryColor: Color(0xFFE91E63),
      backgroundColor: Color(0xFF1A1A1A),
      cardColor: Color(0xFF2D2D2D),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFF8BBD9),
      brightness: Brightness.dark,
      previewImagePath: 'assets/themes/rose_gold_dark.png',
    ),
  ];

  static AppThemeTemplate getById(String id) {
    return templates.firstWhere(
      (template) => template.id == id,
      orElse: () => templates.first, // Default to first template
    );
  }

  static AppThemeTemplate get defaultTemplate => templates.first;
}