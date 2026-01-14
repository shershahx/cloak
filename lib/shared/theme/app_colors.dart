import 'package:flutter/material.dart';

/// Cloak color palette - modern dark theme for privacy protection
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF00AEF0);         // Cyan blue
  static const Color primaryDark = Color(0xFF0091C9);     // Darker cyan
  static const Color primaryLight = Color(0xFF4FC3F7);    // Lighter cyan
  
  // Accent / Secondary
  static const Color accent = Color(0xFF7C4DFF);          // Purple accent
  static const Color accentLight = Color(0xFFB388FF);     // Light purple
  
  // Background Colors
  static const Color background = Color(0xFF0D0D1A);      // Deep dark blue
  static const Color surface = Color(0xFF1A1A2E);         // Card background
  static const Color surfaceLight = Color(0xFF252542);    // Elevated surface
  static const Color surfaceLighter = Color(0xFF2F2F52);  // Modal/dialog
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);         // Green - connected
  static const Color successLight = Color(0xFF81C784);    // Light green
  static const Color warning = Color(0xFFFFB74D);         // Orange - caution
  static const Color error = Color(0xFFEF5350);           // Red - blocked/error
  static const Color errorDark = Color(0xFFD32F2F);       // Dark red
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);     // White
  static const Color textSecondary = Color(0xFFB0B0C8);   // Light gray-blue
  static const Color textMuted = Color(0xFF6B6B8A);       // Muted
  static const Color textDisabled = Color(0xFF4A4A5A);    // Disabled
  
  // Category Colors (for tracker types)
  static const Color categoryAds = Color(0xFFE91E63);         // Pink - Ads
  static const Color categoryTracking = Color(0xFF9C27B0);    // Purple - Trackers
  static const Color categoryAnnoyances = Color(0xFFFF5722);  // Orange - Annoyances
  static const Color categoryAllowed = Color(0xFF4CAF50);     // Green - Allowed
  
  // Shield Colors (for the main toggle)
  static const Color shieldActive = Color(0xFF00AEF0);    // Active/protected
  static const Color shieldInactive = Color(0xFF4A4A5A);  // Inactive/off
  static const Color shieldGlow = Color(0x4000AEF0);      // Glow effect
  
  // Divider & Border
  static const Color divider = Color(0xFF2A2A3E);
  static const Color border = Color(0xFF3A3A4E);
  static const Color borderLight = Color(0xFF4A4A5E);
}
