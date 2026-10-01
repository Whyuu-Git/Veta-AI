// Layar Home: command center — sapaan, kartu riset aktif dengan progress,
// dan 4 quick action ke tab lain. Padanan Dashboard.tsx desain VETA.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/research_model.dart';
import '../../providers/active_research_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/create_research_dialog.dart';
import '../../widgets/main_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActiveResearchProvider>().loadResearches();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  void _openCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateResearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final researchProvider = context.watch<ActiveResearchProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: researchProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => researchProvider.loadResearches(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_greeting(),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      user?.name.split(' ').first ?? 'Researcher',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (researchProvider.researches.isEmpty)
                      _EmptyState(onCreateFirst: _openCreateDialog)
                    else if (researchProvider.activeResearch != null)
                      _CommandCenter(
                        research: researchProvider.activeResearch!,
                        onCreateNew: _openCreateDialog,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateFirst;
  const _EmptyState({required this.onCreateFirst});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 56),
          const SizedBox(height: 20),
          const Text('Selamat datang di VETA',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Mari mulai penelitian pertama Anda. VETA akan mendampingi Anda dengan rekomendasi jurnal, analisis AI, dan mentor pribadi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreateFirst,
            icon: const Icon(Icons.add),
            label: const Text('Buat Penelitian Pertama'),
          ),
        ],
      ),
    );
  }
}

class _CommandCenter extends StatelessWidget {
  final ResearchModel research;
  final VoidCallback onCreateNew;
  const _CommandCenter({required this.research, required this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    final progress = research.progressPercentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kartu riset aktif
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.card
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 11, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('PENELITIAN AKTIF',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(research.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                [research.field, research.topic]
                    .where((e) => e != null && e.isNotEmpty)
                    .join(' — '),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.muted,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${research.progressPercentage}%',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  _miniBadge(research.stageLabel),
                  _miniBadge(research.citationStyle),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _QuickAction(
              icon: Icons.menu_book_outlined,
              label: 'Research Workspace',
              desc: 'Catatan & tulisan',
              onTap: () => MainShell.of(context)?.goToTab(1),
            ),
            _QuickAction(
              icon: Icons.psychology_outlined,
              label: 'AI Mentor',
              desc: 'Tanya VETA',
              onTap: () => MainShell.of(context)?.goToTab(2),
            ),
            _QuickAction(
              icon: Icons.insights_outlined,
              label: 'Intelligence',
              desc: 'Analisis & skor',
              onTap: () => MainShell.of(context)?.goToTab(3),
            ),
            _QuickAction(
              icon: Icons.add,
              label: 'Penelitian Baru',
              desc: 'Tambah proyek',
              onTap: onCreateNew,
              isCreate: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final VoidCallback onTap;
  final bool isCreate;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.desc,
    required this.onTap,
    this.isCreate = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon,
                color: isCreate ? AppColors.textSecondary : AppColors.primary,
                size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
