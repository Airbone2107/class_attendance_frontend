import 'package:class_attendance_frontend/api/debug_api.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart'; // Import AuthProvider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:go_router/go_router.dart'; // Import GoRouter

// 1. Đổi thành ConsumerStatefulWidget
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

// 2. Đổi thành ConsumerState
class _DebugScreenState extends ConsumerState<DebugScreen> {
  final DebugApi _api = DebugApi();
  bool _isLoading = false;
  String _status = '';

  // Hàm xử lý chung
  Future<void> _handleAction(String name, Future<String> Function() action, {bool shouldLogout = false}) async {
    setState(() {
      _isLoading = true;
      _status = 'Đang thực hiện $name...';
    });

    try {
      final message = await action();

      // --- THÊM LOGIC MỚI TẠI ĐÂY ---
      if (shouldLogout) {
        // Xóa dữ liệu local và state đăng nhập
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reset thành công. Đang đăng xuất...'), backgroundColor: Colors.green),
          );
          // Chuyển hướng về trang login
          context.go('/login');
          return; // Kết thúc luôn, không cần update state UI nữa vì đã chuyển trang
        }
      }
      // -----------------------------

      setState(() {
        _status = '✅ $message';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Lỗi: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Công cụ hỗ trợ Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Lưu ý: Các hành động này sẽ thay đổi trực tiếp Database.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // 3. Cập nhật nút Reset DB: thêm tham số shouldLogout: true
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _handleAction('Reset DB', _api.resetDatabase, shouldLogout: true),
              icon: const Icon(Icons.delete_forever),
              label: const Text('1. XÓA SẠCH DATABASE & ĐĂNG XUẤT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.all(20),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleAction('Seed Mock Data', _api.seedDatabase),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('2. TẠO DỮ LIỆU MOCK (5 THẺ NFC)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (!_isLoading && _status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey.shade200,
                child: Text(_status, textAlign: TextAlign.center),
              ),
            const Spacer(),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text('Thông tin tài khoản Mock:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('GV: gv001 / password123'),
                    Text('SV: sv001, sv02 -> sv05 / password123'),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}