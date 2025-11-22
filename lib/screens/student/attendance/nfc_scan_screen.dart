import 'package:class_attendance_frontend/providers/attendance_provider.dart';
import 'package:class_attendance_frontend/utils/nfc_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NfcScanScreen extends ConsumerStatefulWidget {
  const NfcScanScreen({super.key});

  @override
  ConsumerState<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends ConsumerState<NfcScanScreen> {
  bool _isReading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    // Kiểm tra xem đây là Mode check-in vị trí (Step 1 - Level 3) hay Mode check thẻ (Step 2)
    // Dựa vào việc sessionId đã có chưa.
    // Tuy nhiên, theo luồng đã thiết kế ở Home:
    // - Nếu từ QR: đã có SessionID -> Đây là Step 2 (Check thẻ).
    // - Nếu từ nút NFC ở Home: SessionID = 'WAITING_FOR_NFC' -> Đây là Step 1 (Check vị trí).
    final state = ref.read(attendanceProvider);
    if (state.sessionId == 'WAITING_FOR_NFC') {
        _statusMessage = 'Chạm vào thiết bị của Giảng viên để lấy Session ID...';
    } else {
        _statusMessage = 'Chạm thẻ sinh viên để xác thực...';
    }
    
    _startNfcSession();
  }

  Future<void> _startNfcSession() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        setState(() => _statusMessage = 'NFC không khả dụng.');
        return;
      }

      setState(() => _isReading = true);

      var tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 30));
      
      // LOGIC CHECK-IN VỊ TRÍ (Level 3 - Step 1)
      // Giả lập: Quét 1 thẻ bất kỳ coi như nhận được tín hiệu từ máy GV và lấy ID thẻ làm SessionID giả
      // Thực tế: Cần đọc NDEF record từ máy GV.
      final state = ref.read(attendanceProvider);
      
      if (state.sessionId == 'WAITING_FOR_NFC') {
          // Giả lập nhận SessionID từ máy GV
          // Ở đây ta hardcode sessionID lấy từ tag ID để test flow
          final fakeSessionIdFromTeacher = "MOCK_SESSION_LV3"; 
          
          ref.read(attendanceProvider.notifier).setSessionData(fakeSessionIdFromTeacher, 3); // Set Level 3
          
          await FlutterNfcKit.finish();
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Đã nhận tín hiệu vị trí! Vui lòng quét thẻ SV.')),
          );
          
          // Refresh lại trang này để chuyển sang mode quét thẻ
          setState(() {
              _isReading = false;
              _statusMessage = 'Bây giờ chạm thẻ sinh viên của bạn vào...';
          });
          // Gọi lại sau 1 giây để quét thẻ tiếp
          Future.delayed(const Duration(seconds: 1), _startNfcSession);
          return;
      }

      // LOGIC QUÉT THẺ SV (Step 2 - Cấp 1, 2, 3 đều vào đây)
      final tagId = NfcHandler.extractTagId(tag);
      if (tagId.isNotEmpty) {
        ref.read(attendanceProvider.notifier).setNfcCardId(tagId);
        await FlutterNfcKit.finish();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã đọc thẻ: $tagId')));

        // Kiểm tra Level để điều hướng
        final currentLevel = ref.read(attendanceProvider).sessionLevel ?? 1;
        
        if (currentLevel == 1) {
            // Cấp 1: Xong luôn -> Submit
            _submitAttendance();
        } else {
            // Cấp 2, 3: Chuyển sang quét mặt
            context.push('/student/scan-face');
        }
      } else {
          await FlutterNfcKit.finish();
      }

    } catch (e) {
      setState(() => _isReading = false);
      await FlutterNfcKit.finish();
    }
  }

  Future<void> _submitAttendance() async {
      setState(() => _statusMessage = 'Đang gửi dữ liệu...');
      await ref.read(attendanceProvider.notifier).submitCheckIn();
      
      if (!mounted) return;
      final state = ref.read(attendanceProvider);
      
      if (state.error != null) {
          // Show error dialog
          showDialog(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Lỗi'), content: Text(state.error!),
              actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Đóng'))]
          ));
      } else {
          // Thành công -> Redirect sang màn chi tiết lớp
          // ClassID được trả về trong state.successClassId
          final classId = state.successClassId;
          if (classId != null) {
              context.go('/student/course-detail/$classId');
          } else {
              context.go('/student/home');
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét NFC')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nfc, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            if (_isReading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          ],
        ),
      ),
    );
  }
}
