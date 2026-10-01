// Fungsi kirim pesan chat ke Mentor AI & ambil riwayat.
// Mengikuti endpoint di app/routers/mentor.py.

import '../models/mentor_message_model.dart';
import 'api_service.dart';

class MentorService {
  final ApiService _api = ApiService();

  // Buat sesi percakapan baru untuk sebuah riset
  Future<MentorConversationModel> createConversation(String researchId) async {
    final response = await _api.post('/mentor/conversations', {
      'research_id': researchId,
    });
    return MentorConversationModel.fromJson(response);
  }

  // Daftar percakapan yang pernah ada untuk riset tertentu (riwayat)
  Future<List<MentorConversationModel>> getConversations(
      String researchId) async {
    final response =
        await _api.get('/mentor/conversations?research_id=$researchId');
    return (response as List)
        .map((json) => MentorConversationModel.fromJson(json))
        .toList();
  }

  // Riwayat pesan dalam satu percakapan
  Future<List<MentorMessageModel>> getMessages(String conversationId) async {
    final response =
        await _api.get('/mentor/conversations/$conversationId/messages');
    return (response as List)
        .map((json) => MentorMessageModel.fromJson(json))
        .toList();
  }

  // Kirim pesan baru. Response-nya cuma balasan assistant (pesan user
  // sendiri tidak dikembalikan backend, jadi ditambahkan manual di UI).
  //
  // CATATAN: belum streaming (NFR-04 masih di-defer) — proses ini bisa
  // makan 10-40 detik kalau Mentor AI memutuskan mencari jurnal, jadi
  // UI WAJIB menampilkan indikator loading yang jelas selama menunggu.
  Future<MentorMessageModel> sendMessage(
      String conversationId, String content) async {
    final response = await _api.post(
      '/mentor/conversations/$conversationId/messages',
      {'content': content},
    );
    return MentorMessageModel.fromJson(response);
  }
}
