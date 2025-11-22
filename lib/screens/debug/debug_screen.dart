import 'package:class_attendance_frontend/api/debug_api.dart';
import 'package:flutter/material.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final DebugApi _api = DebugApi();
  bool _isLoading = false;
  String _status = '';

  Future<void> _handleAction(String name, Future<String> Function() action) async {
    setState(() {
      _isLoading = true;
      _status = 'Đang thực hiện $name...';
    });

    try {
      final message = await action();
      setState(() {
        _status = '✅ $message';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Lỗi: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Công cụ hỗ trợ Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Lưu ý: Các hành động này sẽ thay đổi trực tiếp Database.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleAction('Reset DB', _api.resetDatabase),
              icon: const Icon(Icons.delete_forever),
              label: const Text('1. XÓA SẠCH DATABASE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleAction('Seed Mock Data', _api.seedDatabase),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('2. TẠO DỮ LIỆU MOCK (5 THẺ NFC)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (!_isLoading && _status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey.shade200,
                child: Text(_status, textAlign: TextAlign.center),
              ),
            const Spacer(),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text('Thông tin tài khoản Mock:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('GV: gv001 / password123'),
                    Text('SV: sv01 -> sv05 / password123'),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

