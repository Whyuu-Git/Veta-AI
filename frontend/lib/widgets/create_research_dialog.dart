// Dialog form "Buat Penelitian Baru" — dipanggil dari Dashboard
// (tombol Plus / Quick Action "New Research").

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/active_research_provider.dart';

class CreateResearchDialog extends StatefulWidget {
  const CreateResearchDialog({super.key});

  @override
  State<CreateResearchDialog> createState() => _CreateResearchDialogState();
}

class _CreateResearchDialogState extends State<CreateResearchDialog> {
  final _titleController = TextEditingController();
  final _fieldController = TextEditingController();
  final _topicController = TextEditingController();
  bool _isSaving = false;

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await context.read<ActiveResearchProvider>().createResearch(
            title: _titleController.text.trim(),
            field: _fieldController.text.trim().isEmpty
                ? null
                : _fieldController.text.trim(),
            topic: _topicController.text.trim().isEmpty
                ? null
                : _topicController.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat riset: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Naik otomatis saat keyboard muncul
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Penelitian Baru',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _field('Judul penelitian', _titleController, autofocus: true),
            const SizedBox(height: 12),
            _field('Bidang (opsional)', _fieldController),
            const SizedBox(height: 12),
            _field('Topik (opsional)', _topicController),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primaryForeground),
                      )
                    : const Text('Buat Penelitian'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool autofocus = false}) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
