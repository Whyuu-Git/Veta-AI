// Model data "research_note" (representasi response API backend).
// Mengikuti NoteResponse di app/schemas/research_note.py.

class ResearchNoteModel {
  final String id;
  final String researchId;
  final String? journalId; // terisi kalau catatan berasal dari jurnal (FR-07d)
  final String title;
  final String? content;
  final String type; // note | reference | writing | idea
  final DateTime createdAt;
  final DateTime updatedAt;

  ResearchNoteModel({
    required this.id,
    required this.researchId,
    this.journalId,
    required this.title,
    this.content,
    this.type = 'note',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResearchNoteModel.fromJson(Map<String, dynamic> json) {
    return ResearchNoteModel(
      id: json['id'],
      researchId: json['research_id'],
      journalId: json['journal_id'],
      title: json['title'],
      content: json['content'],
      type: json['type'] ?? 'note',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Label & ikon-friendly key per tipe, dipakai di widget filter/badge
  static const List<String> allTypes = ['note', 'reference', 'writing', 'idea'];

  static const Map<String, String> typeLabels = {
    'note': 'Catatan',
    'reference': 'Referensi',
    'writing': 'Tulisan',
    'idea': 'Ide',
  };

  String get typeLabel => typeLabels[type] ?? type;
}
