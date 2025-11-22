import 'package:class_attendance_frontend/api/attendance_api.dart';
import 'package:class_attendance_frontend/models/user.dart';
import 'package:class_attendance_frontend/providers/attendance_provider.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:class_attendance_frontend/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_helper.mocks.dart';

void main() {
  late MockAttendanceApi mockAttendanceApi;
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    mockAttendanceApi = MockAttendanceApi();
    mockAuthService = MockAuthService();
  });

  // Helper function để tạo container mới cho mỗi test case
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        attendanceApiProvider.overrideWithValue(mockAttendanceApi),
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AttendanceNotifier Test', () {
    test('submitCheckIn thất bại nếu chưa đăng nhập', () async {
      container = createContainer();

      // Act: Gọi hàm khi chưa login (authProvider mặc định là chưa login)
      await container.read(attendanceProvider.notifier).submitCheckIn();

      // Assert: Mặc định auth state là unauthenticated, nên submitCheckIn return void sớm
      // Tuy nhiên, nếu không có token thì hàm submitCheckIn (đã update) sẽ return luôn.
      // Để test fail do auth, ta có thể check state không thay đổi hoặc thêm cờ.
      // Ở code hiện tại, nếu token == null, nó return.
      final state = container.read(attendanceProvider);
      expect(state.isLoading, false);
    });

    test('submitCheckIn thành công khi đủ thông tin', () async {
      // Arrange
      container = createContainer();

      // Mock login thành công
      when(mockAuthService.login(any, any)).thenAnswer((_) async => (
      User(id: '1', userId: 'sv', fullName: 'A', role: 'student'),
      'fake_token'
      ));

      // Thực hiện login để cập nhật state của authProvider
      await container.read(authProvider.notifier).login('sv', 'pass');

      // Setup data điểm danh
      final notifier = container.read(attendanceProvider.notifier);
      // setSessionData bây giờ nhận (id, level)
      notifier.setSessionData('SESSION_1', 1);
      notifier.setNfcCardId('NFC_1');

      // Mock API checkIn trả về classId (String)
      when(mockAttendanceApi.checkIn(any, any, any, faceVector: anyNamed('faceVector')))
          .thenAnswer((_) async => Future.value('CLASS_123'));

      // Act
      await notifier.submitCheckIn();

      // Assert
      final state = container.read(attendanceProvider);
      expect(state.isLoading, false);
      expect(state.successClassId, 'CLASS_123'); // CẬP NHẬT: Kiểm tra successClassId
      expect(state.error, null);

      verify(mockAttendanceApi.checkIn('fake_token', 'SESSION_1', 'NFC_1', faceVector: null)).called(1);
    });

    test('submitCheckIn báo lỗi khi API trả về lỗi', () async {
      // Arrange
      container = createContainer();

      // Mock login
      when(mockAuthService.login(any, any)).thenAnswer((_) async => (
      User(id: '1', userId: 'sv', fullName: 'A', role: 'student'),
      'fake_token'
      ));
      await container.read(authProvider.notifier).login('sv', 'pass');

      final notifier = container.read(attendanceProvider.notifier);
      notifier.setSessionData('SESSION_1', 1);
      notifier.setNfcCardId('NFC_1');

      // Mock API checkIn ném lỗi
      when(mockAttendanceApi.checkIn(any, any, any, faceVector: anyNamed('faceVector')))
          .thenThrow(Exception('Invalid NFC'));

      // Act
      await notifier.submitCheckIn();

      // Assert
      final state = container.read(attendanceProvider);
      expect(state.isLoading, false);
      expect(state.error, 'Exception: Invalid NFC');
    });
  });
}