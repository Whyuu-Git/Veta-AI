// Fungsi CRUD catatan riset + simpan jurnal sebagai catatan (FR-07d).
// Mengikuti endpoint di app/routers/notes.py.

import '../models/research_note_model.dart';
import 'api_service.dart';

class NotesService {
  final ApiService _api = ApiService();

  Future<List<ResearchNoteModel>> getNotes(String researchId,
      {String? type}) async {
    final query = type != null ? '?type=$type' : '';
    final response = await _api.get('/researches/$researchId/notes$query');
    return (response as List)
        .map((json) => ResearchNoteModel.fromJson(json))
        .toList();
  }

  Future<ResearchNoteModel> createNote({
    required String researchId,
    required String title,
    String? content,
    String type = 'note',
  }) async {
    final response = await _api.post('/researches/$researchId/notes', {
      'title': title,
      'content': content,
      'type': type,
    });
    return ResearchNoteModel.fromJson(response);
  }

  // FR-07d: simpan jurnal rekomendasi Mentor AI sebagai catatan reference
  Future<ResearchNoteModel> createNoteFromJournal({
    required String researchId,
    required String journalId,
  }) async {
    final response =
        await _api.post('/researches/$researchId/notes/from-journal', {
      'journal_id': journalId,
    });
    return ResearchNoteModel.fromJson(response);
  }

  Future<ResearchNoteModel> updateNote(
      String noteId, Map<String, dynamic> changes) async {
    final response = await _api.patch('/notes/$noteId', changes);
    return ResearchNoteModel.fromJson(response);
  }

  Future<void> deleteNote(String noteId) async {
    await _api.delete('/notes/$noteId');
  }
}
