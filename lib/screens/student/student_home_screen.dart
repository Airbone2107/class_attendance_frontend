import 'package:class_attendance_frontend/api/attendance_api.dart';
import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:class_attendance_frontend/providers/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _currentIndex = 0;

  void _onCheckInPressed() {
    ref.read(attendanceProvider.notifier).reset(); // Reset state
    
    // Nút điểm danh mở ra lựa chọn QR hoặc NFC (Bước 1)
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chọn phương thức bắt đầu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text('1. Quét QR (Cấp 1, 2)', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade900,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/student/scan-qr');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.nfc, size: 28),
              label: const Text('2. Quét NFC Check-in (Cấp 3 - Vị trí)', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange.shade50,
                foregroundColor: Colors.orange.shade900,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                // Vào màn hình NFC nhưng với mode nhận session
                // (Logic xử lý bên trong nfc_scan_screen sẽ được cập nhật)
                // Để đơn giản, ta set cứng level 3 và chuyển tới NFC
                ref.read(attendanceProvider.notifier).setSessionData('WAITING_FOR_NFC', 3);
                context.push('/student/scan-nfc'); 
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    final tabs = [
      _HomeTab(user: user, onCheckIn: _onCheckInPressed),
      const _ScheduleTabMock(), // Thời khóa biểu Mock
      const _CourseListTab(), // Danh sách lớp thật từ API
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'TKB'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Môn học'),
        ],
      ),
    );
  }
}

// Tab 1: Trang chủ
class _HomeTab extends StatelessWidget {
  final dynamic user;
  final VoidCallback onCheckIn;

  const _HomeTab({required this.user, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(
                  radius: 28, 
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xin chào,', style: TextStyle(color: Colors.grey[600])),
                    Text(user?.fullName ?? 'Sinh viên',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {})
              ],
            ),
            const SizedBox(height: 40),
            
            // Nút Điểm danh lớn
            Center(
              child: GestureDetector(
                onTap: onCheckIn,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 25, spreadRadius: 8)
                    ]
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fingerprint, size: 70, color: Colors.white),
                      SizedBox(height: 12),
                      Text('ĐIỂM DANH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Text('Tin tức HUTECH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Mock Data cứng
            _buildNewsItem('HUTECH long trọng tổ chức lễ khai giảng năm học mới', '2 giờ trước'),
            _buildNewsItem('Thông báo lịch nghỉ Tết Nguyên Đán 2026', '1 ngày trước'),
            _buildNewsItem('Sinh viên HUTECH đạt giải nhất cuộc thi NCKH', '3 ngày trước'),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItem(String title, String time) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: Container(
          width: 70, height: 70, 
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.image, color: Colors.grey),
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
      ),
    );
  }
}

// Tab 2: Thời khóa biểu Mock (Giống ảnh 2)
class _ScheduleTabMock extends StatelessWidget {
  const _ScheduleTabMock();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thời khóa biểu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: const Center(child: Text('17/11/2025 đến 23/11/2025', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 20),
          const Text('Thứ 2, 17/11/2025', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildScheduleItem('Quản lý dự án công nghệ thông tin', 'Tiết 7-11', 'Phòng: E1-09.08'),
          const SizedBox(height: 20),
          const Text('Thứ 3, 18/11/2025', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildScheduleItem('Phát triển ứng dụng với J2EE', 'Tiết 2-6', 'Phòng: E1-09.05'),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String subject, String shift, String room) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.blue.shade800, width: 4)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(shift, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 20),
              Text(room),
            ],
          )
        ],
      ),
    );
  }
}

// Tab 3: Danh sách lớp (Gọi API thật)
class _CourseListTab extends ConsumerWidget {
  const _CourseListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authProvider).token!;
    final future = ref.watch(attendanceApiProvider).getStudentClasses(token);

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách môn học')),
      body: FutureBuilder<List<ClassModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          
          final classes = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final cls = classes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(cls.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text('${cls.classId} | ${cls.group}'),
                      Text('TC: ${cls.credits} | Số buổi: ${cls.lessons.length}'), // Sử dụng totalLessons đã tính ở backend hoặc class model
                    ],
                  ),
                  onTap: () {
                    context.push('/student/course-detail/${cls.classId}');
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
