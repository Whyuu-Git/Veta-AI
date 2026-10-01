import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/research/research_list_screen.dart';
import '../screens/mentor/mentor_chat_screen.dart';
import '../screens/intelligence/intelligence_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();

  static MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void goToTab(int index) => setState(() => _currentIndex = index);

  static const List<Widget> _tabs = [
    DashboardScreen(),
    ResearchListScreen(),
    MentorChatScreen(),
    IntelligenceScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card.withValues(alpha: 0.7),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: const Text('V',
                  style: TextStyle(
                      color: AppColors.primaryForeground,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    children: [
                      TextSpan(
                          text: 'V',
                          style: TextStyle(color: AppColors.primary)),
                      TextSpan(
                          text: 'ETA',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const Text('AI RESEARCH OS',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar:
          BottomNavBar(currentIndex: _currentIndex, onTap: goToTab),
    );
  }
}
