// Setup HTTP client dasar (base URL, header, error handling).
//
// Semua service lain (auth_service, research_service, dst) pakai class ini
// supaya tidak perlu tulis ulang logika "tambahkan token JWT ke header",
// "cek status code", dll di setiap file.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // GANTI ini sesuai alamat backend FastAPI kalian.
  // Kalau jalankan backend di laptop sendiri dan test di emulator Android,
  // biasanya "10.0.2.2" dipakai untuk mengakses "localhost" milik laptop.
  static const String baseUrl =
      'https://aerobics-exemption-regime.ngrok-free.dev';

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // Ambil token yang tersimpan (null kalau belum login)
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  // Header standar, otomatis sertakan token JWT kalau ada
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  // Cek status code, dan lempar error yang mudah dibaca kalau gagal
  dynamic _handleResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccess) {
      String message = 'Terjadi kesalahan (kode ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {
        // body bukan JSON, biarkan pakai pesan default di atas
      }
      throw ApiException(message);
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}

// Custom exception supaya di UI kita bisa tampilkan pesan error yang jelas,
// misal: try { ... } catch (e) { showSnackbar(e.toString()) }
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
