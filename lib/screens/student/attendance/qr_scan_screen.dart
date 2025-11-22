import 'package:class_attendance_frontend/providers/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR (Bước 1)')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              final rawValue = barcode.rawValue!;
              // QR Format: SESSION_ID|LEVEL
              // VD: ABCD1234|1
              if (rawValue.contains('|')) {
                setState(() => _isScanned = true);
                
                final parts = rawValue.split('|');
                final sessionId = parts[0];
                final level = int.tryParse(parts[1]) ?? 1;

                // Lưu vào state
                ref.read(attendanceProvider.notifier).setSessionData(sessionId, level);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã nhận Session: $sessionId (Cấp $level)')),
                );

                // Chuyển sang bước 2: NFC
                context.push('/student/scan-nfc');
                break;
              }
            }
          }
        },
      ),
    );
  }
}