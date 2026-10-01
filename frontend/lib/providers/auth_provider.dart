// State management: status login & data user aktif.
//
// Kenapa pakai ChangeNotifier + Provider?
// Supaya kalau data user berubah (misal setelah setup wizard selesai),
// semua widget yang "mendengarkan" provider ini otomatis rebuild,
// tanpa kita harus manual pass data user ke setiap layar.

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  // Dipanggil sekali saat app pertama kali dibuka, cek apakah ada
  // token tersimpan dari sesi login sebelumnya
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _currentUser = await _authService.login(email: email, password: password);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    _currentUser = await _authService.register(name: name, email: email, password: password);
    notifyListeners();
  }

  Future<void> completeSetup(Map<String, dynamic> profileData) async {
    _currentUser = await _authService.completeSetup(profileData);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
