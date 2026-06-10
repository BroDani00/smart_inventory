// lib/core/constants/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Light Theme
  static const Color primaryLight = Color(0xFF0F172A); // Biru Gelap Modern
  static const Color accentLight = Color(0xFF10B981);  // Emerald Modern
  static const Color secondaryLight = Color(0xFF06B6D4); // Cyan Soft
  static const Color backgroundLight = Color(0xFFF8FAFC); // Abu-abu Terang
  static const Color cardLight = Colors.white;

  // Dark Theme
  static const Color primaryDark = Color(0xFF020617);
  static const Color accentDark = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF22D3EE);
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color cardDark = Color(0xFF1E293B);

  // General Accent Colors
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF06B6D4);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  
  // Gradients for Light Theme
  static LinearGradient get premiumGradient => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  static LinearGradient get premiumGradientLight => const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  static LinearGradient get premiumGradientDark => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get emeraldGradient => const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get cyanGradient => const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  static LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  static LinearGradient get orangeGradient => const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  static LinearGradient get dangerGradient => const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  static LinearGradient get glassGradient => LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}