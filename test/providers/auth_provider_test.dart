import 'package:class_attendance_frontend/models/user.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:class_attendance_frontend/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_helper.mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUp(() {
    // Mock FlutterSecureStorage để tránh lỗi MissingPluginException
    FlutterSecureStorage.setMockInitialValues({});
    
    mockAuthService = MockAuthService();
    
    // Tạo container và override authServiceProvider bằng mock
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier Test', () {
    final testUser = User(id: '1', userId: 'sv001', fullName: 'Test User', role: 'student');
    final testToken = 'test_token_jwt';

    test('Initial state should be empty', () {
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
      expect(state.error, null);
    });

    test('login thành công cập nhật state với user và token', () async {
      // Arrange
      when(mockAuthService.login('sv001', 'password'))
          .thenAnswer((_) async => (testUser, testToken));

      // Act
      await container.read(authProvider.notifier).login('sv001', 'password');

      // Assert
      final state = container.read(authProvider);
      expect(state.isLoading, false);
      expect(state.isAuthenticated, true);
      expect(state.user, testUser);
      expect(state.token, testToken);
      expect(state.error, null);
    });

    test('login thất bại cập nhật state với lỗi', () async {
      // Arrange
      when(mockAuthService.login('sv001', 'wrong_pass'))
          .thenThrow(Exception('Login failed'));

      // Act
      await container.read(authProvider.notifier).login('sv001', 'wrong_pass');

      // Assert
      final state = container.read(authProvider);
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
      expect(state.error, 'Exception: Login failed');
    });

    test('logout xóa token và reset state', () async {
      // Arrange: Login trước
      when(mockAuthService.login('sv001', 'password'))
          .thenAnswer((_) async => (testUser, testToken));
      await container.read(authProvider.notifier).login('sv001', 'password');

      // Act
      await container.read(authProvider.notifier).logout();

      // Assert
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);
      expect(state.user, null);
      expect(state.token, null);
    });
  });
}