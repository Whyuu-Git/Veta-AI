// Fungsi register/login, simpan & baca JWT dari secure storage.
//
// CATATAN: endpoint di bawah (/auth/register, /auth/login, /users/me)
// mengikuti rencana FR-01 & FR-02 di BRD. Sesuaikan path-nya nanti kalau
// backend kalian pakai penamaan yang sedikit berbeda.

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Daftar akun baru. Mengembalikan UserModel kalau berhasil.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });

    // Backend disarankan langsung balikin token saat register juga,
    // supaya user tidak perlu login manual lagi setelah daftar.
    await _api.saveToken(response['access_token']);
    return UserModel.fromJson(response['user']);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    await _api.saveToken(response['access_token']);
    return UserModel.fromJson(response['user']);
  }

  // Ambil data user yang sedang login (dipakai saat app dibuka ulang,
  // untuk cek apakah token masih valid & langsung isi data profil)
  Future<UserModel?> getCurrentUser() async {
    final token = await _api.getToken();
    if (token == null) return null;

    try {
      final response = await _api.get('/users/me');
      return UserModel.fromJson(response);
    } catch (_) {
      // token expired/invalid -> anggap belum login
      return null;
    }
  }

  // Kirim data setup wizard (role, universitas, preferensi AI, dst)
  Future<UserModel> completeSetup(Map<String, dynamic> profileData) async {
    final response = await _api.patch('/users/me/profile', profileData);
    return UserModel.fromJson(response);
  }

  Future<void> logout() async {
    await _api.clearToken();
  }
}
