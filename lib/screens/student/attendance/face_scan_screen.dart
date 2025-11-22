// ignore_for_file: unused_import

import 'package:camera/camera.dart';
import 'package:class_attendance_frontend/providers/attendance_provider.dart';
import 'package:class_attendance_frontend/services/face_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceScanScreen extends ConsumerStatefulWidget {
  const FaceScanScreen({super.key});

  @override
  ConsumerState<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends ConsumerState<FaceScanScreen> {
  CameraController? _controller;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  bool _isDetecting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});

    _controller!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _isSuccess) return;
    _isDetecting = true;

    try {
      // Giả lập delay xử lý nhận diện
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Giả lập nhận diện thành công
        _handleSuccess('mock_face_vector_data_from_camera');
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    } finally {
      _isDetecting = false;
    }
  }

  void _handleSuccess(String faceVector) {
    _isSuccess = true;
    _controller?.stopImageStream();

    ref.read(attendanceProvider.notifier).setFaceVector(faceVector);
    _submitAttendance();
  }

  Future<void> _submitAttendance() async {
    // SỬA LỖI: Xóa tham số '2' vì hàm submitCheckIn không còn nhận tham số nữa
    await ref.read(attendanceProvider.notifier).submitCheckIn();

    final state = ref.read(attendanceProvider);

    if (!mounted) return;

    if (state.error != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lỗi điểm danh'),
          content: Text(state.error!),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('Đóng')),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Thành công'),
          content: const Text('Bạn đã điểm danh thành công!'),
          actions: [
            TextButton(
              onPressed: () {
                context.go('/student/home');
              },
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bước 3: Xác thực khuôn mặt')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Giữ khuôn mặt trong khung hình',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}