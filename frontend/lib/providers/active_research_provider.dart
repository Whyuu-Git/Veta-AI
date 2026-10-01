// State management: riset yang sedang aktif dipilih pengguna,
// plus daftar semua riset milik pengguna (dipakai di Dashboard & Layout).

import 'package:flutter/foundation.dart';
import '../models/research_model.dart';
import '../services/research_service.dart';

class ActiveResearchProvider extends ChangeNotifier {
  final ResearchService _researchService = ResearchService();

  List<ResearchModel> _researches = [];
  ResearchModel? _activeResearch;
  bool _isLoading = false;

  List<ResearchModel> get researches => _researches;
  ResearchModel? get activeResearch => _activeResearch;
  bool get isLoading => _isLoading;

  // Ambil semua riset milik user. Kalau belum ada riset aktif terpilih
  // (atau riset aktif sebelumnya sudah tidak ada di daftar), otomatis
  // pilih riset pertama — supaya user tidak perlu tap manual tiap buka app.
  Future<void> loadResearches() async {
    _isLoading = true;
    notifyListeners();

    _researches = await _researchService.getAllResearches();

    final stillExists = _activeResearch != null &&
        _researches.any((r) => r.id == _activeResearch!.id);
    if (!stillExists) {
      _activeResearch = _researches.isNotEmpty ? _researches.first : null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setActiveResearch(ResearchModel research) {
    _activeResearch = research;
    notifyListeners();
  }

  Future<void> createResearch({
    required String title,
    String? field,
    String? topic,
    List<String> keywords = const [],
    String? goal,
  }) async {
    final created = await _researchService.createResearch(
      title: title,
      field: field,
      topic: topic,
      keywords: keywords,
      goal: goal,
    );
    _researches.insert(0, created);
    _activeResearch = created; // riset baru langsung jadi aktif
    notifyListeners();
  }
}
