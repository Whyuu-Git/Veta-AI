// Model data "research" (representasi response API backend).
// Mengikuti tabel `researches` di database_schema.sql.

class ResearchModel {
  final String id;
  final String title;
  final String? field; // bidang ilmu, misal "Ilmu Komputer"
  final String? topic;
  final List<String> keywords;
  final String? goal;

  final String currentStage; // salah satu dari 9 tahap
  final int progressPercentage; // 0-100

  final String citationStyle; // APA, MLA, IEEE, dst
  final String status; // active | archived | completed

  ResearchModel({
    required this.id,
    required this.title,
    this.field,
    this.topic,
    this.keywords = const [],
    this.goal,
    required this.currentStage,
    this.progressPercentage = 0,
    this.citationStyle = 'APA',
    this.status = 'active',
  });

  // Urutan 9 tahap riset, dipakai untuk hitung "Tahap X dari 9"
  static const List<String> allStages = [
    'ide',
    'proposal',
    'literature_review',
    'metodologi',
    'pengumpulan_data',
    'analisis',
    'penulisan',
    'review',
    'publikasi',
  ];

  static const Map<String, String> stageLabels = {
    'ide': 'Ide',
    'proposal': 'Proposal',
    'literature_review': 'Literature Review',
    'metodologi': 'Metodologi',
    'pengumpulan_data': 'Pengumpulan Data',
    'analisis': 'Analisis',
    'penulisan': 'Penulisan',
    'review': 'Review',
    'publikasi': 'Publikasi',
  };

  int get stageNumber => allStages.indexOf(currentStage) + 1;
  String get stageLabel => stageLabels[currentStage] ?? currentStage;

  factory ResearchModel.fromJson(Map<String, dynamic> json) {
    return ResearchModel(
      id: json['id'],
      title: json['title'],
      field: json['field'],
      topic: json['topic'],
      keywords:
          json['keywords'] != null ? List<String>.from(json['keywords']) : [],
      goal: json['goal'],
      currentStage: json['current_stage'] ?? 'ide',
      progressPercentage: json['progress_percentage'] ?? 0,
      citationStyle: json['citation_style'] ?? 'APA',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'field': field,
      'topic': topic,
      'keywords': keywords,
      'goal': goal,
      'current_stage': currentStage,
      'progress_percentage': progressPercentage,
      'citation_style': citationStyle,
      'status': status,
    };
  }
}
