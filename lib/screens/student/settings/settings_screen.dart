import 'package:class_attendance_frontend/api/debug_api.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart'; // Import AuthProvider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final DebugApi _debugApi = DebugApi();
  bool _isLoading = false;

  // Hàm Reset DB (Giữ nguyên logic cũ)
  Future<void> _resetDb() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận Reset"),
        content: const Text("Hành động này sẽ xóa toàn bộ dữ liệu và đăng xuất bạn. Bạn có chắc không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final msg = await _debugApi.resetDatabase();
      await _debugApi.seedDatabase();

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$msg\nĐã tạo lại dữ liệu mẫu."), backgroundColor: Colors.green));
        await ref.read(authProvider.notifier).logout();
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm Đăng xuất
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đăng xuất", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      // Router sẽ tự động chuyển về Login vì authState thay đổi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tài khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // 1. Đăng ký khuôn mặt
          ListTile(
            leading: const Icon(Icons.face, color: Colors.blue, size: 28),
            title: const Text('Đăng ký khuôn mặt'),
            subtitle: const Text('Cập nhật dữ liệu để điểm danh'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/student/register-face'),
            tileColor: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),

          const SizedBox(height: 10),

          // 2. Đăng xuất (Mới thêm)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange, size: 28),
            title: const Text('Đăng xuất'),
            subtitle: const Text('Thoát tài khoản hiện tại'),
            onTap: _logout,
            tileColor: Colors.orange.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),

          const SizedBox(height: 30),
          const Text('Hệ thống (Debug)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 10),

          // 3. Reset DB
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset & Seed Database'),
            subtitle: const Text('Xóa sạch và tạo lại dữ liệu mẫu'),
            onTap: _isLoading ? null : _resetDb,
            tileColor: Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            trailing: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
        ],
      ),
    );
  }
}