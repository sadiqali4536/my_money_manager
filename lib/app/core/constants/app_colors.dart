import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF082B63); // Navy Blue
  static const Color primaryDark = Color(0xFF051C42);
  static const Color primaryLight = Color(0xFF13428E);
  
  // Design Specific Colors
  static const Color darkBackground = Color(0xFF1C221F);
  static const Color cardDarkBackground = Color(0xFF252D26);
  static const Color neonLime = Color(0xFFD4F938);
  static const Color neonLimeLight = Color(0xFFE8FFA6);
  static const Color softGreenBadge = Color(0xFFE9F9E5);
  static const Color softRedBadge = Color(0xFFFFECEF);
  static const Color softBlueBadge = Color(0xFFE6F3FF);
  static const Color softOrangeBadge = Color(0xFFFFF2E6);
  static const Color softGreyBadge = Color(0xFFF1F4F6);

  // Secondary / Accent
  static const Color secondary = Color(0xFFF5B400); // Gold
  static const Color secondaryLight = Color(0xFFFFD54F);

  // Background & Surfaces
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // Dark Mode Surfaces
  static const Color backgroundDark = Color(0xFF0E131F);
  static const Color surfaceDark = Color(0xFF172033);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color dividerDark = Color(0xFF2E3A52);

  // Typography
  static const Color textPrimaryLight = Color(0xFF172033);
  static const Color textSecondaryLight = Color(0xFF737B8C);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Financial Semantics
  static const Color success = Color(0xFF0D9488); // Muted Teal
  static const Color successLight = Color(0xFFCCFBF1);
  static const Color expense = Color(0xFFE11D48); // Muted Red
  static const Color expenseLight = Color(0xFFFFE4E6);
  static const Color warning = Color(0xFFD97706); // Amber
  static const Color info = Color(0xFF0284C7); // Sky Blue
  static const Color neutral = Color(0xFF64748B); // Slate
  
  // Account Category Palette
  static const List<Color> categoryPalette = [
    Color(0xFF3B82F6), // Blue (Food & Groceries)
    Color(0xFF10B981), // Emerald (Travel)
    Color(0xFFF59E0B), // Amber (Emergency)
    Color(0xFF8B5CF6), // Purple (Investments)
    Color(0xFFEC4899), // Pink (Daily Savings)
    Color(0xFF06B6D4), // Cyan (Entertainment)
    Color(0xFF64748B), // Slate (Other / Buffer)
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
  ];
}

