// Model data "journal" (representasi response API backend).
// Mengikuti JournalResponse di app/schemas/journal.py.
// Dipakai untuk kartu sitasi di bawah balasan Mentor AI (FR-07c).

class JournalModel {
  final String id;
  final String title;
  final String? authors;
  final String source; // semantic_scholar | openalex
  final int? year;
  final int? citationCount;
  final String? doi;
  final String? url;

  JournalModel({
    required this.id,
    required this.title,
    this.authors,
    required this.source,
    this.year,
    this.citationCount,
    this.doi,
    this.url,
  });

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    return JournalModel(
      id: json['id'],
      title: json['title'],
      authors: json['authors'],
      source: json['source'],
      year: json['year'],
      citationCount: json['citation_count'],
      doi: json['doi'],
      url: json['url'],
    );
  }

  // Label sumber yang enak dibaca di UI, misal untuk badge kecil di kartu jurnal
  String get sourceLabel {
    switch (source) {
      case 'semantic_scholar':
        return 'Semantic Scholar';
      case 'openalex':
        return 'OpenAlex';
      default:
        return source;
    }
  }
}
