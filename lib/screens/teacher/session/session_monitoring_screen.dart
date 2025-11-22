import 'dart:async';
import 'package:class_attendance_frontend/api/attendance_api.dart';
import 'package:class_attendance_frontend/models/session_model.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SessionMonitoringScreen extends ConsumerStatefulWidget {
  final SessionModel session;
  const SessionMonitoringScreen({super.key, required this.session});

  @override
  ConsumerState<SessionMonitoringScreen> createState() => _SessionMonitoringScreenState();
}

class _SessionMonitoringScreenState extends ConsumerState<SessionMonitoringScreen> {
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  Duration _timeLeft = Duration.zero;
  int _studentCount = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  void _startCountdown() {
    if (widget.session.expiresAt == null) return;
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = widget.session.expiresAt!.difference(now);
      
      if (diff.isNegative) {
        timer.cancel();
        _pollingTimer?.cancel(); // Dừng poll khi hết giờ
        setState(() => _timeLeft = Duration.zero);
      } else {
        setState(() => _timeLeft = diff);
      }
    });
  }

  void _startPolling() {
    // Poll 3s một lần
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final token = ref.read(authProvider).token!;
        final stats = await AttendanceApi().getSessionStats(token, widget.session.sessionId);
        if (mounted) {
          setState(() {
            _studentCount = stats['count'] ?? 0;
          });
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _timeLeft.inSeconds == 0;
    final minutes = _timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Đang điểm danh...'), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isExpired ? 'PHIÊN KẾT THÚC' : 'Thời gian còn lại',
              style: TextStyle(color: isExpired ? Colors.red : Colors.black54, fontWeight: FontWeight.bold),
            ),
            Text(
              '$minutes:$seconds',
              style: TextStyle(
                fontSize: 60, 
                fontWeight: FontWeight.bold, 
                color: isExpired ? Colors.red : Colors.blue
              ),
            ),
            const SizedBox(height: 30),
            
            if (!isExpired) ...[
                // QR chứa SESSION_ID|LEVEL (Backend sẽ tự map)
                QrImageView(
                  data: '${widget.session.sessionId}|${widget.session.level}',
                  version: QrVersions.auto,
                  size: 260.0,
                ),
                const SizedBox(height: 10),
                const Text('Sinh viên quét mã để điểm danh', style: TextStyle(fontStyle: FontStyle.italic)),
            ] else ...[
                const Icon(Icons.lock, size: 100, color: Colors.grey),
                const Text('Mã QR đã hết hạn'),
            ],

            const SizedBox(height: 40),
            
            // Thống kê
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200)
              ),
              child: Column(
                children: [
                  const Text('Đã điểm danh', style: TextStyle(fontSize: 16)),
                  Text(
                    '$_studentCount',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),

            const Spacer(),
            ElevatedButton(
              onPressed: () => context.pop(), // Quay về trang trước
              child: const Text('Thoát màn hình này'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

