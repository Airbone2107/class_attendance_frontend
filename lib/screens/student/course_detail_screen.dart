import 'package:class_attendance_frontend/api/attendance_api.dart';
import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StudentCourseDetailScreen extends ConsumerStatefulWidget {
  final String classId;
  const StudentCourseDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<StudentCourseDetailScreen> createState() => _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState extends ConsumerState<StudentCourseDetailScreen> {
  late Future<ClassModel> _classDetailFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final token = ref.read(authProvider).token!;
    _classDetailFuture = ref.read(attendanceApiProvider).getStudentClassDetail(token, widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết điểm danh')),
      body: FutureBuilder<ClassModel>(
        future: _classDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

          final classInfo = snapshot.data!;
          // Tính số buổi vắng
          final absentCount = classInfo.lessons.where((l) => l.status == 'absent').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  classInfo.className,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.grey[100],
                width: double.infinity,
                child: Text('Số buổi vắng: $absentCount', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classInfo.lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = classInfo.lessons[index];
                    final dateStr = DateFormat('dd/MM/yyyy').format(lesson.date);
                    
                    Color statusColor;
                    String statusText;
                    
                    if (lesson.status == 'present') {
                      statusColor = Colors.green.shade100;
                      statusText = 'Có mặt';
                    } else if (lesson.status == 'absent') {
                      statusColor = Colors.red.shade100;
                      statusText = 'Vắng';
                    } else {
                      statusColor = Colors.grey.shade300;
                      statusText = 'Chưa điểm danh';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ngày: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('Tiết: ${lesson.shift}'),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: lesson.status == 'present' ? Colors.green[800] : Colors.black87,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

