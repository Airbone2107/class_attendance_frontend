import 'package:class_attendance_frontend/models/user.dart';
import 'package:class_attendance_frontend/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.token, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({User? user, String? token, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  // API được lấy thông qua ref
  late AuthService _authService;
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    // Lấy instance từ provider
    _authService = ref.watch(authServiceProvider);
    return AuthState();
  }

  Future<void> login(String userId, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (user, token) = await _authService.login(userId, password);
      await _storage.write(key: 'jwt_token', value: token);
      state = state.copyWith(user: user, token: token, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);