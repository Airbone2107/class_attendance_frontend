import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TeacherClassDetailScreen extends StatelessWidget {
  final ClassModel classModel;
  const TeacherClassDetailScreen({super.key, required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(classModel.classId)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classModel.className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Danh sách buổi học:', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classModel.lessons.length,
              itemBuilder: (context, index) {
                final lesson = classModel.lessons[index];
                final dateStr = DateFormat('dd/MM/yyyy').format(lesson.date);
                
                return Card(
                  child: ListTile(
                    title: Text('Buổi ${index + 1}: $dateStr'),
                    subtitle: Text('Phòng: ${lesson.room} | Ca: ${lesson.shift}'),
                    trailing: ElevatedButton(
                      child: const Text('Điểm danh'),
                      onPressed: () {
                        // Chuyển sang màn hình tạo session cho buổi học này
                        context.push('/teacher/create-session', extra: {
                          'class': classModel,
                          'lessonId': lesson.lessonId
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

