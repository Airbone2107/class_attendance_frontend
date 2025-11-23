// class_attendance_frontend/lib/screens/student/settings/settings_screen.dart
import 'package:class_attendance_frontend/api/debug_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DebugApi _debugApi = DebugApi();
  bool _isLoading = false;

  Future<void> _resetDb() async {
    setState(() => _isLoading = true);
    try {
      final msg = await _debugApi.resetDatabase();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
        // Sau khi reset, nên seed lại dữ liệu mẫu luôn cho tiện
        await _debugApi.seedDatabase();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã tạo lại dữ liệu mẫu!"), backgroundColor: Colors.blue));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
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
          ListTile(
            leading: const Icon(Icons.face, color: Colors.blue, size: 32),
            title: const Text('Đăng ký khuôn mặt'),
            subtitle: const Text('Cập nhật dữ liệu khuôn mặt để điểm danh'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/student/register-face');
            },
            tileColor: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          
          const SizedBox(height: 30),
          const Text('Hệ thống (Debug)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 10),
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

