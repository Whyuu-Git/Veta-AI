// Layar profil & preferensi pengguna.
// Padanan Profile.tsx desain VETA — edit data akademik & preferensi AI,
// pakai endpoint yang sama dengan Setup Wizard (PATCH /users/me/profile).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _universityController = TextEditingController();
  final _facultyController = TextEditingController();
  final _majorController = TextEditingController();

  String? _role;
  String _writingStyle = 'formal';
  String _academicTone = 'suportif';
  bool _isSaving = false;
  bool _isEditing = false;
  bool _initialized = false;

  void _loadFromUser(dynamic user) {
    if (_initialized || user == null) return;
    _universityController.text = user.university ?? '';
    _facultyController.text = user.faculty ?? '';
    _majorController.text = user.major ?? '';
    _role = user.role;
    _writingStyle = user.writingStyle;
    _academicTone = user.academicTone;
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
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
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Keluar dari akun?',
            style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar',
                style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    _loadFromUser(user);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header avatar + nama
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(user?.name ?? '',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  Text(user?.email ?? '',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        'Tier ${(user?.tier ?? 'gratis').toUpperCase()}',
                        style: const TextStyle(
                            color: AppColors.accentForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profil Akademik',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                  icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined,
                      size: 16),
                  label: Text(_isEditing ? 'Batal' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isEditing)
              ..._buildEditForm()
            else
              ..._buildReadOnlyInfo(user),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout,
                  size: 16, color: AppColors.destructive),
              label: const Text('Keluar',
                  style: TextStyle(color: AppColors.destructive)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.destructive),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReadOnlyInfo(dynamic user) {
    return [
      _infoRow('Peran', user?.role ?? '-'),
      _infoRow('Universitas',
          user?.university?.isNotEmpty == true ? user!.university : '-'),
      _infoRow(
          'Fakultas', user?.faculty?.isNotEmpty == true ? user!.faculty : '-'),
      _infoRow(
          'Program Studi', user?.major?.isNotEmpty == true ? user!.major : '-'),
      const SizedBox(height: 16),
      const Text('Preferensi AI',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _infoRow('Gaya Tulisan', user?.writingStyle ?? '-'),
      _infoRow('Nada Akademik', user?.academicTone ?? '-'),
      _infoRow('Bahasa AI',
          (user?.aiLanguage ?? 'id') == 'id' ? 'Bahasa Indonesia' : 'English'),
    ];
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Widget> _buildEditForm() {
    return [
      DropdownButtonFormField<String>(
        initialValue: _role,
        decoration: const InputDecoration(
            labelText: 'Peran',
            labelStyle: TextStyle(color: AppColors.textSecondary)),
        dropdownColor: AppColors.card,
        style: const TextStyle(color: AppColors.textPrimary),
        items: const [
          DropdownMenuItem(value: 'mahasiswa', child: Text('Mahasiswa')),
          DropdownMenuItem(value: 'dosen', child: Text('Dosen')),
          DropdownMenuItem(value: 'peneliti', child: Text('Peneliti')),
        ],
        onChanged: (v) => setState(() => _role = v),
      ),
      const SizedBox(height: 12),
      _editField('Universitas', _universityController),
      const SizedBox(height: 12),
      _editField('Fakultas', _facultyController),
      const SizedBox(height: 12),
      _editField('Program Studi', _majorController),
      const SizedBox(height: 16),
      const Text('Preferensi AI',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Gaya Tulisan',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: ['formal', 'santai', 'akademik_ketat'].map((style) {
          final isSelected = _writingStyle == style;
          return ChoiceChip(
            label: Text(style, style: const TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (_) => setState(() => _writingStyle = style),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.muted,
            labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primaryForeground
                    : AppColors.textSecondary),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
      const Text('Nada Akademik',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: ['suportif', 'kritis', 'netral'].map((tone) {
          final isSelected = _academicTone == tone;
          return ChoiceChip(
            label: Text(tone, style: const TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (_) => setState(() => _academicTone = tone),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.muted,
            labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primaryForeground
                    : AppColors.textSecondary),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryForeground))
              : const Text('Simpan Perubahan'),
        ),
      ),
    ];
  }

  Widget _editField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
