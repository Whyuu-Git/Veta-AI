// Layar hasil analisis AI: health score, gap analysis, rekomendasi.
// Layar hasil analisis AI: health score, gap analysis, rekomendasi.
// Padanan Intelligence.tsx desain VETA — gauge skor custom digambar
// pakai CustomPainter (tidak butuh package chart tambahan).

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/intelligence_analysis_model.dart';
import '../../providers/active_research_provider.dart';
import '../../services/intelligence_service.dart';

class IntelligenceScreen extends StatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen> {
  final IntelligenceService _service = IntelligenceService();

  IntelligenceAnalysisModel? _latest;
  String? _loadedForResearchId;
  bool _isLoadingHistory = false;
  bool _isRunning = false;
  String? _error;

  Future<void> _loadHistory(String researchId) async {
    if (_loadedForResearchId == researchId) return;
    setState(() {
      _loadedForResearchId = researchId;
      _isLoadingHistory = true;
      _error = null;
    });

    try {
      final history = await _service.getHistory(researchId);
      if (!mounted) return;
      setState(() => _latest = history.isNotEmpty ? history.first : null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat riwayat analisis: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _runAnalysis(String researchId) async {
    setState(() {
      _isRunning = true;
      _error = null;
    });
    try {
      final result = await _service.runAnalysis(researchId);
      if (!mounted) return;
      setState(() => _latest = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal menjalankan analisis: $e');
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeResearch =
        context.watch<ActiveResearchProvider>().activeResearch;

    if (activeResearch == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Buat penelitian terlebih dahulu untuk menjalankan analisis Intelligence.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadHistory(activeResearch.id));

    if (_isLoadingHistory) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _loadedForResearchId = null;
        await _loadHistory(activeResearch.id);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Analisis Riset',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed:
                    _isRunning ? null : () => _runAnalysis(activeResearch.id),
                icon: _isRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primaryForeground),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(_isRunning
                    ? 'Menganalisis…'
                    : (_latest == null ? 'Analisis' : 'Analisis Ulang')),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.destructive.withValues(alpha: 0.3)),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: AppColors.destructive, fontSize: 12)),
            ),
          if (_latest == null && !_isRunning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.insights_outlined,
                      color: AppColors.textSecondary, size: 48),
                  SizedBox(height: 12),
                  Text('Belum ada analisis. Tap "Analisis" untuk memulai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          else if (_latest != null)
            _AnalysisResult(analysis: _latest!),
        ],
      ),
    );
  }
}

class _AnalysisResult extends StatelessWidget {
  final IntelligenceAnalysisModel analysis;
  const _AnalysisResult({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gauge skor kesehatan riset
        Center(
          child: _ScoreGauge(score: analysis.healthScore ?? 0),
        ),
        const SizedBox(height: 20),

        // Kartu kesiapan publikasi
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${analysis.publicationReadiness ?? 0}%',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const Text('Kesiapan Publikasi',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_readinessLabel(analysis.publicationReadiness ?? 0),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const Text('Tingkat Kesiapan',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (analysis.gapAnalysis != null)
          _sectionCard('Gap Analysis', analysis.gapAnalysis!, Icons.search),
        if (analysis.noveltyAssessment != null)
          _sectionCard('Novelty Assessment', analysis.noveltyAssessment!,
              Icons.lightbulb_outline),

        if (analysis.strengths.isNotEmpty)
          _listCard('Kekuatan', analysis.strengths, AppColors.primary,
              Icons.check_circle_outline),
        if (analysis.weaknesses.isNotEmpty)
          _listCard('Kelemahan', analysis.weaknesses, AppColors.destructive,
              Icons.error_outline),
        if (analysis.recommendations.isNotEmpty)
          _listCard('Rekomendasi', analysis.recommendations,
              AppColors.accentForeground, Icons.recommend_outlined),
      ],
    );
  }

  String _readinessLabel(int value) {
    if (value >= 70) return 'Tinggi';
    if (value >= 40) return 'Sedang';
    return 'Rendah';
  }

  Widget _sectionCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _listCard(
      String title, List<String> items, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// Gauge skor melengkung (0-100), digambar manual pakai CustomPainter
class _ScoreGauge extends StatelessWidget {
  final int score;
  const _ScoreGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: const Size(180, 100),
            painter: _GaugePainter(score: score),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Text('$score',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
                const Text('dari 100',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  _GaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    const startAngle = math.pi; // mulai dari kiri (180°)
    const sweepTotal = math.pi; // setengah lingkaran

    final bgPaint = Paint()
      ..color = AppColors.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    final scorePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final sweep = sweepTotal * (score.clamp(0, 100) / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.score != score;
}
