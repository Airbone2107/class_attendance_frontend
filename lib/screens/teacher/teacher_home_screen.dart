import 'package:class_attendance_frontend/api/attendance_api.dart';
import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  late Future<List<ClassModel>> _classesFuture;

  @override
  void initState() {
    super.initState();
    final token = ref.read(authProvider).token!;
    _classesFuture = AttendanceApi().getTeacherClasses(token);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Giảng viên: ${user?.fullName ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ClassModel>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final classes = snapshot.data ?? [];
          
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final item = classes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(item.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item.classId} - Nhóm: ${item.group}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Chuyển sang màn hình chi tiết lớp để chọn buổi học
                    context.push('/teacher/class-detail', extra: item);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

