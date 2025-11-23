// class_attendance_frontend/lib/screens/student/attendance/face_scan_screen.dart
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:class_attendance_frontend/providers/attendance_provider.dart';
import 'package:class_attendance_frontend/services/face_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceScanScreen extends ConsumerStatefulWidget {
  const FaceScanScreen({super.key});

  @override
  ConsumerState<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends ConsumerState<FaceScanScreen> {
  CameraController? _controller;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );
  final FaceService _faceService = FaceService();
  
  bool _isDetecting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _faceService.initialize();
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});

    // Bắt đầu loop scan
    _scanFaceLoop();
  }

  // Thay thế stream bằng chụp ảnh định kỳ để dễ xử lý hình ảnh hơn
  // Vì xử lý YUV420 stream sang RGB cho TFLite rất nặng và dễ lỗi trên các thiết bị khác nhau
  Future<void> _scanFaceLoop() async {
      while (mounted && !_isSuccess) {
          if (_controller == null || !_controller!.value.isInitialized || _isDetecting) {
              await Future.delayed(const Duration(milliseconds: 500));
              continue;
          }
          
          _isDetecting = true;
          try {
              final imageFile = await _controller!.takePicture();
              final inputImage = InputImage.fromFilePath(imageFile.path);
              final faces = await _faceDetector.processImage(inputImage);
              
              if (faces.isNotEmpty) {
                  // Tìm thấy mặt -> Xử lý
                  final bytes = await imageFile.readAsBytes();
                  // ignore: use_build_context_synchronously
                  final imgLibImage = await _decodeImage(bytes); // Hàm decode giống file Registration
                  
                  if (imgLibImage != null) {
                      final face = faces.first;
                      final cropped = _faceService.cropFace(imgLibImage, face);
                      final embedding = await _faceService.getFaceEmbedding(cropped);
                      
                      _handleSuccess(embedding);
                      break; // Thoát vòng lặp
                  }
              }
          } catch (e) {
              print("Scan error: $e");
          } finally {
              _isDetecting = false;
          }
          // Nghỉ 1 chút trước khi chụp tiếp
          await Future.delayed(const Duration(milliseconds: 500));
      }
  }

  void _handleSuccess(List<double> embedding) {
    _isSuccess = true;
    ref.read(attendanceProvider.notifier).setFaceEmbedding(embedding);
    _submitAttendance();
  }

  Future<void> _submitAttendance() async {
    await ref.read(attendanceProvider.notifier).submitCheckIn();
    final state = ref.read(attendanceProvider);

    if (!mounted) return;

    if (state.error != null) {
      // Nếu lỗi, cho phép thử lại
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lỗi điểm danh'),
          content: Text(state.error!),
          actions: [
            TextButton(onPressed: () {
                context.pop();
                setState(() {
                    _isSuccess = false; // Reset để quét lại
                    _scanFaceLoop(); // Chạy lại
                });
            }, child: const Text('Thử lại')),
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
  
  // Helper decode (cần import image package)
  Future<img.Image?> _decodeImage(Uint8List bytes) async => img.decodeImage(bytes);

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    _faceService.dispose();
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
                border: Border.all(color: _isDetecting ? Colors.yellow : Colors.green, width: 3),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),
          Positioned(
            bottom: 50, left: 0, right: 0,
            child: Text(
              _isDetecting ? 'Đang xử lý...' : 'Giữ khuôn mặt trong khung hình',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
