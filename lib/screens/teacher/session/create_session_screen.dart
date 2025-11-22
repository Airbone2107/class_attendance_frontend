import 'package:class_attendance_frontend/api/attendance_api.dart';
import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  final ClassModel classInfo;
  final String lessonId;

  const CreateSessionScreen({super.key, required this.classInfo, required this.lessonId});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  int _selectedLevel = 1;
  bool _isLoading = false;

  Future<void> _createSession() async {
    setState(() => _isLoading = true);
    try {
      final token = ref.read(authProvider).token!;
      final session = await AttendanceApi().createSession(
        token,
        widget.classInfo.classId,
        widget.lessonId,
        _selectedLevel,
      );

      if (!mounted) return;
      // Tạo xong chuyển ngay sang màn hình Monitor để show QR và đếm ngược
      context.pushReplacement('/teacher/monitor', extra: session);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo phiên: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình phiên điểm danh')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Môn: ${widget.classInfo.className}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Buổi học ID: ${widget.lessonId}'),
            const SizedBox(height: 30),
            const Text('Chọn mức độ an ninh:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            _buildLevelOption(1, 'Cấp 1: Cơ bản', 'Quét QR + NFC Thẻ', Icons.qr_code),
            _buildLevelOption(2, 'Cấp 2: Nâng cao', 'QR + NFC + Face ID', Icons.face),
            _buildLevelOption(3, 'Cấp 3: Nghiêm ngặt', 'Tại chỗ (NFC Loc) + Thẻ + Face', Icons.security),

            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading ? null : _createSession,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('BẮT ĐẦU PHIÊN (5 PHÚT)'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLevelOption(int level, String title, String desc, IconData icon) {
    return RadioListTile<int>(
      value: level,
      groupValue: _selectedLevel,
      onChanged: (val) => setState(() => _selectedLevel = val!),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
      secondary: Icon(icon, color: _selectedLevel == level ? Colors.blue : Colors.grey),
      activeColor: Colors.blue,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _selectedLevel == level ? Colors.blue : Colors.grey.shade300)
      ),
    );
  }
}