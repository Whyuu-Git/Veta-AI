// Fungsi jalankan & ambil riwayat analisis Intelligence.
// Mengikuti endpoint di app/routers/intelligence.py.

import '../models/intelligence_analysis_model.dart';
import 'api_service.dart';

class IntelligenceService {
  final ApiService _api = ApiService();

  // Jalankan analisis AI baru untuk sebuah riset (FR-08).
  // Bisa makan beberapa detik karena manggil Gemini — UI wajib
  // tampilkan loading yang jelas selama menunggu.
  Future<IntelligenceAnalysisModel> runAnalysis(String researchId) async {
    final response = await _api.post('/intelligence/$researchId', {});
    return IntelligenceAnalysisModel.fromJson(response);
  }

  // Riwayat analisis, terbaru dulu. Elemen pertama = hasil terkini.
  Future<List<IntelligenceAnalysisModel>> getHistory(String researchId) async {
    final response = await _api.get('/intelligence/$researchId');
    return (response as List)
        .map((json) => IntelligenceAnalysisModel.fromJson(json))
        .toList();
  }
}
