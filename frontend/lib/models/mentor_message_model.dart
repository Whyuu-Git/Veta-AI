// Model data "mentor_message" (representasi response API backend).
// Mengikuti MessageResponse di app/schemas/mentor.py — perhatikan field
// `journals`: daftar sitasi jurnal yang ditautkan ke pesan ini (FR-07c),
// cuma terisi untuk pesan assistant yang memakai tool pencarian jurnal.

import 'journal_model.dart';

class MentorMessageModel {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
  final List<JournalModel> journals;

  MentorMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.journals = const [],
  });

  bool get isUser => role == 'user';

  factory MentorMessageModel.fromJson(Map<String, dynamic> json) {
    return MentorMessageModel(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      journals: json['journals'] != null
          ? (json['journals'] as List)
              .map((j) => JournalModel.fromJson(j))
              .toList()
          : [],
    );
  }
}

// Model percakapan (ConversationResponse) — dipakai untuk riwayat/switch sesi
class MentorConversationModel {
  final String id;
  final String researchId;
  final String? title;
  final DateTime createdAt;

  MentorConversationModel({
    required this.id,
    required this.researchId,
    this.title,
    required this.createdAt,
  });

  factory MentorConversationModel.fromJson(Map<String, dynamic> json) {
    return MentorConversationModel(
      id: json['id'],
      researchId: json['research_id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
