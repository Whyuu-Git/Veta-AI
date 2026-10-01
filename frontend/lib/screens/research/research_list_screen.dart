// Research Workspace: catatan riset — search, filter tipe, tambah/hapus.
// Padanan Research.tsx desain VETA. Nama file/class tetap "ResearchList"
// mengikuti struktur project (rute bottom nav "Research"), tapi fungsinya
// workspace catatan, bukan daftar semua riset (sesuai opsi A/layout VETA).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/research_note_model.dart';
import '../../providers/active_research_provider.dart';
import '../../services/notes_service.dart';

class ResearchListScreen extends StatefulWidget {
  const ResearchListScreen({super.key});

  @override
  State<ResearchListScreen> createState() => _ResearchListScreenState();
}

class _ResearchListScreenState extends State<ResearchListScreen> {
  final NotesService _notesService = NotesService();
  final TextEditingController _searchController = TextEditingController();

  List<ResearchNoteModel> _notes = [];
  String? _loadedForResearchId;
  String _filterType = 'all'; // all | note | reference | writing | idea
  bool _isLoading = false;

  Future<void> _loadNotes(String researchId) async {
    if (_loadedForResearchId == researchId) return;
    setState(() {
      _loadedForResearchId = researchId;
      _isLoading = true;
    });

    try {
      final notes = await _notesService.getNotes(researchId);
      if (!mounted) return;
      setState(() => _notes = notes);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh(String researchId) async {
    _loadedForResearchId = null;
    await _loadNotes(researchId);
  }

  Future<void> _deleteNote(ResearchNoteModel note) async {
    try {
      await _notesService.deleteNote(note.id);
      if (!mounted) return;
      setState(() => _notes.removeWhere((n) => n.id == note.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  void _openAddDialog(String researchId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddNoteSheet(
        researchId: researchId,
        notesService: _notesService,
        onCreated: (note) => setState(() => _notes.insert(0, note)),
      ),
    );
  }

  List<ResearchNoteModel> get _filteredNotes {
    return _notes.where((n) {
      if (_filterType != 'all' && n.type != _filterType) return false;
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty && !n.title.toLowerCase().contains(query))
        return false;
      return true;
    }).toList();
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
              'Belum ada penelitian aktif. Buat penelitian terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadNotes(activeResearch.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _refresh(activeResearch.id),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Research Workspace',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              FilledButton.icon(
                                onPressed: () =>
                                    _openAddDialog(activeResearch.id),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Note'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Cari catatan…',
                              hintStyle:
                                  TextStyle(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.search,
                                  color: AppColors.textSecondary, size: 18),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 32,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _filterChip('all', 'Semua'),
                                ...ResearchNoteModel.allTypes.map((t) =>
                                    _filterChip(
                                        t, ResearchNoteModel.typeLabels[t]!)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredNotes.isEmpty
                          ? const Center(
                              child: Text('Belum ada catatan.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredNotes.length,
                              itemBuilder: (context, index) {
                                final note = _filteredNotes[index];
                                return _NoteCard(
                                    note: note,
                                    onDelete: () => _deleteNote(note));
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filterType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterType = value),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
            color: isSelected
                ? AppColors.primaryForeground
                : AppColors.textSecondary),
        side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ResearchNoteModel note;
  final VoidCallback onDelete;
  const _NoteCard({required this.note, required this.onDelete});

  IconData get _icon {
    switch (note.type) {
      case 'reference':
        return Icons.menu_book_outlined;
      case 'writing':
        return Icons.edit_outlined;
      case 'idea':
        return Icons.lightbulb_outline;
      default:
        return Icons.notes_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (note.content != null && note.content!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note.content!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(note.typeLabel,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.textSecondary),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('Hapus catatan?',
                    style: TextStyle(color: AppColors.textPrimary)),
                content: Text('"${note.title}" akan dihapus permanen.',
                    style: const TextStyle(color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    child: const Text('Hapus',
                        style: TextStyle(color: AppColors.destructive)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddNoteSheet extends StatefulWidget {
  final String researchId;
  final NotesService notesService;
  final ValueChanged<ResearchNoteModel> onCreated;

  const _AddNoteSheet(
      {required this.researchId,
      required this.notesService,
      required this.onCreated});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _type = 'note';
  bool _isSaving = false;

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final note = await widget.notesService.createNote(
        researchId: widget.researchId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        type: _type,
      );
      widget.onCreated(note);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambah catatan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catatan Baru',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ResearchNoteModel.allTypes.map((t) {
                final isSelected = _type == t;
                return ChoiceChip(
                  label: Text(ResearchNoteModel.typeLabels[t]!,
                      style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _type = t),
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
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Judul',
                  labelStyle: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Isi (opsional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary)),
            ),
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
                            strokeWidth: 2, color: AppColors.primaryForeground))
                    : const Text('Simpan'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
