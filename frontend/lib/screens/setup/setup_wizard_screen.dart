// Layar onboarding: role, universitas/fakultas/jurusan, preferensi AI.
//
// Dibuat sederhana pakai PageView 4 langkah (sesuai progress bar VETA).
// Setiap langkah punya validasi ringan sebelum boleh lanjut ke langkah berikutnya.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0-3, total 4 langkah

  String? _role;
  final _universityController = TextEditingController();
  final _facultyController = TextEditingController();
  final _majorController = TextEditingController();
  String _writingStyle = 'formal';
  String _academicTone = 'suportif';

  bool _isSubmitting = false;

  void _goToNextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _role != null;
      case 1:
        return _universityController.text.trim().isNotEmpty &&
            _majorController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthProvider>().completeSetup({
        'role': _role,
        'university': _universityController.text.trim(),
        'faculty': _facultyController.text.trim(),
        'major': _majorController.text.trim(),
        'writing_style': _writingStyle,
        'academic_tone': _academicTone,
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar 4 langkah
              Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                'LANGKAH ${_currentStep + 1} DARI 4',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentStep = index),
                  children: [
                    _RoleStep(
                      selectedRole: _role,
                      onSelect: (role) => setState(() => _role = role),
                    ),
                    _AcademicDataStep(
                      universityController: _universityController,
                      facultyController: _facultyController,
                      majorController: _majorController,
                      onChanged: () => setState(() {}),
                    ),
                    _AiPreferenceStep(
                      writingStyle: _writingStyle,
                      academicTone: _academicTone,
                      onWritingStyleChanged: (v) =>
                          setState(() => _writingStyle = v),
                      onAcademicToneChanged: (v) =>
                          setState(() => _academicTone = v),
                    ),
                    _SummaryStep(
                      role: _role,
                      university: _universityController.text,
                      major: _majorController.text,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    TextButton(
                      onPressed: _goToPreviousStep,
                      child: const Text('Kembali',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_canProceed && !_isSubmitting)
                          ? _goToNextStep
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryForeground),
                            )
                          : Text(_currentStep == 3 ? 'Selesai' : 'Lanjutkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Langkah 1: Pilih peran akademik ----------
class _RoleStep extends StatelessWidget {
  final String? selectedRole;
  final ValueChanged<String> onSelect;

  const _RoleStep({required this.selectedRole, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final roles = [
      {
        'value': 'mahasiswa',
        'title': 'Mahasiswa',
        'subtitle': 'Skripsi, tesis, tugas riset'
      },
      {
        'value': 'dosen',
        'title': 'Dosen',
        'subtitle': 'Riset mandiri & bahan ajar'
      },
      {
        'value': 'peneliti',
        'title': 'Peneliti',
        'subtitle': 'Proyek riset independen'
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apa peran akademikmu saat ini?',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Ini membantu Mentor AI menyesuaikan gaya pendampingannya untukmu.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ...roles.map((role) {
            final isSelected = selectedRole == role['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onSelect(role['value']!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role['title']!,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(role['subtitle']!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------- Langkah 2: Data akademik ----------
class _AcademicDataStep extends StatelessWidget {
  final TextEditingController universityController;
  final TextEditingController facultyController;
  final TextEditingController majorController;
  final VoidCallback onChanged;

  const _AcademicDataStep({
    required this.universityController,
    required this.facultyController,
    required this.majorController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data akademikmu',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildTextField('Universitas', universityController),
          const SizedBox(height: 16),
          _buildTextField('Fakultas (opsional)', facultyController),
          const SizedBox(height: 16),
          _buildTextField('Jurusan/Program Studi', majorController),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ---------- Langkah 3: Preferensi AI ----------
class _AiPreferenceStep extends StatelessWidget {
  final String writingStyle;
  final String academicTone;
  final ValueChanged<String> onWritingStyleChanged;
  final ValueChanged<String> onAcademicToneChanged;

  const _AiPreferenceStep({
    required this.writingStyle,
    required this.academicTone,
    required this.onWritingStyleChanged,
    required this.onAcademicToneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferensi Mentor AI',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('Gaya tulisan',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['formal', 'santai', 'akademik_ketat'].map((style) {
              final isSelected = writingStyle == style;
              return ChoiceChip(
                label: Text(style),
                selected: isSelected,
                onSelected: (_) => onWritingStyleChanged(style),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primaryForeground
                      : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Tone akademik',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['suportif', 'kritis', 'netral'].map((tone) {
              final isSelected = academicTone == tone;
              return ChoiceChip(
                label: Text(tone),
                selected: isSelected,
                onSelected: (_) => onAcademicToneChanged(tone),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primaryForeground
                      : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------- Langkah 4: Ringkasan ----------
class _SummaryStep extends StatelessWidget {
  final String? role;
  final String university;
  final String major;

  const _SummaryStep(
      {required this.role, required this.university, required this.major});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Siap!',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Kamu terdaftar sebagai $role di $university, jurusan $major. '
          'Mentor AI akan menyesuaikan pendampingannya berdasarkan ini — bisa diubah lagi lewat halaman Profil.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
