// Daftar nama route/halaman untuk navigasi.
//
// Kenapa pakai nama (String), bukan langsung Navigator.push(MaterialPageRoute(...))?
// Supaya kalau nanti ada banyak tempat yang pindah ke halaman yang sama,
// kita tidak perlu ulang tulis "MaterialPageRoute(builder: (_) => XScreen())"
// di banyak file. Cukup panggil: Navigator.pushNamed(context, AppRoutes.dashboard)

class AppRoutes {
  static const String login = '/login';
  static const String setupWizard = '/setup-wizard';
  static const String dashboard = '/dashboard';
  static const String researchList = '/research-list';
  static const String researchDetail = '/research-detail';
  static const String mentorChat = '/mentor-chat';
  static const String intelligence = '/intelligence';
  static const String profile = '/profile';
}
