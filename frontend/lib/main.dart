// Entry point aplikasi Flutter.
// Di sini: runApp(), setup theme VETA (dark + teal, font Inter), dan routing awal.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'constants/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/active_research_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/setup/setup_wizard_screen.dart';
import 'widgets/main_shell.dart';

void main() {
  runApp(const VetaApp());
}

class VetaApp extends StatelessWidget {
  const VetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Semua provider didaftarkan di sini, supaya bisa diakses
      // dari layar manapun lewat context.read<...>() / context.watch<...>()
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ActiveResearchProvider()),
      ],
      child: MaterialApp(
        title: 'VETA',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.setupWizard: (_) => const SetupWizardScreen(),
          // Setelah login/setup selesai, seluruh app (5 tab) hidup di
          // dalam satu shell — bukan route terpisah per tab, supaya
          // bottom nav tetap terlihat & state tiap tab tidak reset.
          AppRoutes.dashboard: (_) => const MainShell(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    final baseTextTheme =
        GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.card,
        error: AppColors.destructive,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
