import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF0B2A4A);
  static const Color deepNavy = Color(0xFF071C33);
  static const Color navySoft = Color(0xFF163A5C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color ivory = Color(0xFFFBF8F1);
  static const Color cream = Color(0xFFF4EBDA);
  static const Color parchment = Color(0xFFF8F1E3);
  static const Color petalCream = Color(0xFFFAF4E8);
  static const Color softBackground = Color(0xFFF6F0E4);
  static const Color lightBlue = Color(0xFFEAF2FA);
  static const Color mist = Color(0xFFD7E3F0);
  static const Color gold = Color(0xFFC9A85D);
  static const Color goldSoft = Color(0xFFE6D7AE);
  static const Color goldMuted = Color(0xFFB8954A);
  static const Color textPrimary = Color(0xFF0B2A4A);
  static const Color textSecondary = Color(0xFF4A6075);
  static const Color textOnNavy = Color(0xFFF7F4EC);
  static const Color border = Color(0xFFD9E4F0);
  static const Color error = Color(0xFF9B3A3A);
  static const Color success = Color(0xFF2F6B4F);

  static const LinearGradient medallion = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navySoft, navy, deepNavy],
  );
}
