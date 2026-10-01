// Palet warna aplikasi VETA — dikonversi dari tema Zite/VETA (HSL di
// src/index.css) ke hex, supaya visual Flutter konsisten dengan desain
// yang sudah disepakati (dark + teal, bukan lagi navy/emas mockup lama).

import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF080A0C);
  static const Color card = Color(0xFF0F1115);
  static const Color muted = Color(0xFF1A1D23);
  static const Color border = Color(0xFF23272F);

  static const Color primary = Color(0xFF1FADA2);
  static const Color primaryForeground = Color(0xFF080A0C);
  static const Color accent = Color(0xFF183936);
  static const Color accentForeground = Color(0xFFBEF4EF);

  static const Color destructive = Color(0xFFDC2828);

  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF7B899D);

  static const Color surface = card;
  static const Color gold = primary;
  static const Color moss = primary;
  static const Color textOnGold = primaryForeground;
  static const Color badgeBackground = muted;
}
