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
  late AuthService _authService;
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    return AuthState();
  }

  Future<void> login(String userId, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (user, token) = await _authService.login(userId, password);

      // Lưu Token và User Info cơ bản để dùng cho tính năng đăng nhập nhanh sau này
      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'user_id', value: user.userId);
      await _storage.write(key: 'user_role', value: user.role);
      await _storage.write(key: 'user_fullname', value: user.fullName);
      await _storage.write(key: 'user_db_id', value: user.id);

      state = state.copyWith(user: user, token: token, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Hàm mới: Chỉ kiểm tra xem có token lưu trong máy không (để hiện nút vân tay)
  // KHÔNG tự động đăng nhập (không update state)
  Future<bool> hasSavedSession() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final userId = await _storage.read(key: 'user_id');
      return token != null && userId != null;
    } catch (e) {
      return false;
    }
  }

  // Hàm mới: Thực hiện khôi phục phiên đăng nhập (khi vân tay thành công)
  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final userId = await _storage.read(key: 'user_id');

      if (token != null && userId != null) {
        final id = await _storage.read(key: 'user_db_id') ?? '';
        final fullName = await _storage.read(key: 'user_fullname') ?? '';
        final role = await _storage.read(key: 'user_role') ?? 'student';

        final restoredUser = User(id: id, userId: userId, fullName: fullName, role: role);

        // Cập nhật state -> App sẽ tự chuyển màn hình
        state = state.copyWith(user: restoredUser, token: token, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: "Không tìm thấy phiên đăng nhập cũ");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Lỗi khôi phục phiên: $e");
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll(); // Xóa sạch dữ liệu lưu trữ
    state = AuthState(); // Reset state về ban đầu
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);