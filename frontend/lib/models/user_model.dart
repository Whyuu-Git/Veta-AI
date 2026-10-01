// Model data "user" (representasi response API backend).
//
// Field-field ini mengikuti tabel `users` di database_schema.sql.
// fromJson() dipakai saat menerima data dari backend (response API).
// toJson() dipakai saat mengirim data ke backend (misal saat setup wizard).

class UserModel {
  final String id;
  final String name;
  final String email;

  // Profil akademik (diisi saat setup wizard)
  final String? role; // 'siswa' | 'mahasiswa' | 'dosen' | 'peneliti'
  final String? university;
  final String? faculty;
  final String? major;

  // Preferensi AI
  final String aiLanguage; // 'id' | 'en'
  final String writingStyle; // 'formal' | 'santai' | 'akademik_ketat'
  final String academicTone; // 'suportif' | 'kritis' | 'netral'

  final String tier; // 'gratis' | 'individu' | 'profesional' | 'institusi'
  final bool setupComplete;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.university,
    this.faculty,
    this.major,
    this.aiLanguage = 'id',
    this.writingStyle = 'formal',
    this.academicTone = 'suportif',
    this.tier = 'gratis',
    this.setupComplete = false,
  });

  // Mengubah JSON (Map) dari response API jadi objek UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      university: json['university'],
      faculty: json['faculty'],
      major: json['major'],
      aiLanguage: json['ai_language'] ?? 'id',
      writingStyle: json['writing_style'] ?? 'formal',
      academicTone: json['academic_tone'] ?? 'suportif',
      tier: json['tier'] ?? 'gratis',
      setupComplete: json['setup_complete'] ?? false,
    );
  }

  // Mengubah objek UserModel jadi JSON (Map) untuk dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'university': university,
      'faculty': faculty,
      'major': major,
      'ai_language': aiLanguage,
      'writing_style': writingStyle,
      'academic_tone': academicTone,
    };
  }
}
