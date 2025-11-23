import 'package:class_attendance_frontend/config/app_theme.dart'; // Import file theme
import 'package:class_attendance_frontend/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Đảm bảo binding được khởi tạo trước khi chạy app (quan trọng cho Local Auth)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SmartCheck',
      debugShowCheckedModeBanner: false,
      // Áp dụng Theme mới
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      //themeMode: ThemeMode.system, // Tự động theo cài đặt máy // Sẽ bật lại sau khi fix darkmode
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}