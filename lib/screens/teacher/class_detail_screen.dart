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
                  margin: const EdgeInsets.only(bottom: 12), // Thêm khoảng cách giữa các Card
                  child: Padding( // Thêm padding cho nội dung bên trong Card
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        'Buổi ${index + 1}: $dateStr',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Phòng: ${lesson.room} | Ca: ${lesson.shift}'),
                      ),
                      trailing: ElevatedButton(
                        // --- SỬA ĐỔI TẠI ĐÂY ---
                        style: ElevatedButton.styleFrom(
                          // 1. Tăng padding ngang (horizontal) để chữ không sát viền
                          // 2. Giảm padding dọc (vertical) để nút bớt "béo"
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                          // 3. Thiết lập kích thước tối thiểu để đảm bảo hình dáng chữ nhật
                          minimumSize: const Size(110, 40),

                          // Giữ nguyên màu và bo góc từ Theme hoặc chỉnh lại nếu muốn
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Điểm danh', style: TextStyle(fontSize: 14)),
                        onPressed: () {
                          context.push('/teacher/create-session', extra: {
                            'class': classModel,
                            'lessonId': lesson.lessonId
                          });
                        },
                      ),
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