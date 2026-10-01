// Model data "intelligence_analysis" (representasi response API backend).
// Mengikuti IntelligenceResponse di app/schemas/intelligence.py.

class IntelligenceAnalysisModel {
  final String id;
  final String researchId;
  final int? healthScore; // 0-100
  final int? publicationReadiness; // 0-100
  final String? gapAnalysis;
  final String? noveltyAssessment;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final DateTime createdAt;

  IntelligenceAnalysisModel({
    required this.id,
    required this.researchId,
    this.healthScore,
    this.publicationReadiness,
    this.gapAnalysis,
    this.noveltyAssessment,
    this.strengths = const [],
    this.weaknesses = const [],
    this.recommendations = const [],
    required this.createdAt,
  });

  factory IntelligenceAnalysisModel.fromJson(Map<String, dynamic> json) {
    return IntelligenceAnalysisModel(
      id: json['id'],
      researchId: json['research_id'],
      healthScore: json['health_score'],
      publicationReadiness: json['publication_readiness'],
      gapAnalysis: json['gap_analysis'],
      noveltyAssessment: json['novelty_assessment'],
      strengths:
          json['strengths'] != null ? List<String>.from(json['strengths']) : [],
      weaknesses: json['weaknesses'] != null
          ? List<String>.from(json['weaknesses'])
          : [],
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
