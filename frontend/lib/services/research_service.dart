// Fungsi CRUD riset ke backend — sudah tersambung ke backend asli
// (mock data dimatikan; backend kamu sudah lengkap & teruji).

import '../models/research_model.dart';
import 'api_service.dart';

class ResearchService {
  final ApiService _api = ApiService();

  Future<List<ResearchModel>> getAllResearches() async {
    final response = await _api.get('/researches');
    return (response as List)
        .map((json) => ResearchModel.fromJson(json))
        .toList();
  }

  Future<ResearchModel> getResearchDetail(String id) async {
    final response = await _api.get('/researches/$id');
    return ResearchModel.fromJson(response);
  }

  Future<ResearchModel> createResearch({
    required String title,
    String? field,
    String? topic,
    List<String> keywords = const [],
    String? goal,
    String citationStyle = 'APA',
  }) async {
    final response = await _api.post('/researches', {
      'title': title,
      'field': field,
      'topic': topic,
      'keywords': keywords,
      'goal': goal,
      'citation_style': citationStyle,
    });
    return ResearchModel.fromJson(response);
  }

  Future<ResearchModel> updateResearch(
      String id, Map<String, dynamic> changes) async {
    final response = await _api.patch('/researches/$id', changes);
    return ResearchModel.fromJson(response);
  }

  Future<void> deleteResearch(String id) async {
    await _api.delete('/researches/$id');
  }
}
