// Widget kartu riset (dipakai di Dashboard & daftar riset).
// Tampilan mengikuti mockup: judul, bidang, badge tahap, progress bar,
// dan teks "Tahap X dari 9" di kanan bawah.

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/research_model.dart';

class ResearchCard extends StatelessWidget {
  final ResearchModel research;
  final VoidCallback onTap;

  const ResearchCard({
    super.key,
    required this.research,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    research.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StageBadge(label: research.stageLabel),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [research.field, research.topic].where((e) => e != null).join(' · '),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: research.progressPercentage / 100,
                minHeight: 6,
                backgroundColor: AppColors.badgeBackground,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tahap ${research.stageNumber} dari 9',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Badge kecil di pojok kanan atas card, contoh: "ANALISIS", "PROPOSAL"
class _StageBadge extends StatelessWidget {
  final String label;
  const _StageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.badgeBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.moss,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
