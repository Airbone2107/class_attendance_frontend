import 'package:class_attendance_frontend/main.dart';
import 'package:class_attendance_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helper.mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    // 1. Mock FlutterSecureStorage để tránh lỗi MissingPluginException
    // AuthProvider khởi tạo FlutterSecureStorage ngay khi app chạy nên cần dòng này
    FlutterSecureStorage.setMockInitialValues({});

    // 2. Khởi tạo Mock Service
    mockAuthService = MockAuthService();
  });

  testWidgets('Hien thi man hinh Login khi khoi dong app', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // KHẮC PHỤC LỖI 1: Phải bọc MyApp trong ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override AuthService để không gọi API thực tế
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
        child: const MyApp(),
      ),
    );

    // Đợi router chuyển hướng và giao diện render xong
    await tester.pumpAndSettle();

    // KHẮC PHỤC LỖI 2: Kiểm tra giao diện Login thay vì Counter (App mặc định)

    // Kiểm tra xem AppBar có title 'SmartCheck Login' không
    expect(find.text('SmartCheck Login'), findsOneWidget);

    // Kiểm tra xem có 2 ô nhập liệu (User ID và Password) không
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Kiểm tra xem có nút 'Đăng nhập' không
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}