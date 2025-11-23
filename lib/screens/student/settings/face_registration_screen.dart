import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:class_attendance_frontend/api/attendance_api.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:class_attendance_frontend/services/face_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceRegistrationScreen extends ConsumerStatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  ConsumerState<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends ConsumerState<FaceRegistrationScreen> {
  CameraController? _controller;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );
  final FaceService _faceService = FaceService();

  bool _isProcessing = false;
  bool _isInitialized = false;

  // --- Các biến mới cho việc lấy mẫu ---
  final int _totalSamples = 10; // Số lượng mẫu cần lấy
  int _currentSample = 0;
  final List<List<double>> _collectedEmbeddings = [];
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _faceService.initialize();
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();

    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _startSampling() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _currentSample = 0;
      _collectedEmbeddings.clear();
      _statusMessage = "Đang chuẩn bị...";
    });

    try {
      // Vòng lặp lấy mẫu
      while (_currentSample < _totalSamples && mounted) {
        setState(() {
          _statusMessage = "Đang lấy mẫu ${_currentSample + 1}/$_totalSamples\nGiữ yên khuôn mặt...";
        });

        // 1. Chụp ảnh
        final imageFile = await _controller!.takePicture();
        final inputImage = InputImage.fromFilePath(imageFile.path);

        // 2. Phát hiện khuôn mặt
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isEmpty) {
          // Nếu không thấy mặt, bỏ qua lần này nhưng không tăng biến đếm
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        // Lấy khuôn mặt to nhất
        final face = faces.reduce((curr, next) =>
        (curr.boundingBox.width * curr.boundingBox.height) > (next.boundingBox.width * next.boundingBox.height) ? curr : next
        );

        // 3. Decode ảnh
        final bytes = await imageFile.readAsBytes();
        final imgLibImage = await _decodeImage(bytes);

        if (imgLibImage != null) {
          // 4. Crop và lấy Embedding
          final croppedFace = _faceService.cropFace(imgLibImage, face);
          final embedding = await _faceService.getFaceEmbedding(croppedFace);

          _collectedEmbeddings.add(embedding);
          _currentSample++;
        }

        // Nghỉ 1 chút giữa các lần chụp để tránh lag máy
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted) return;

      // 5. Tính trung bình cộng các vector
      setState(() => _statusMessage = "Đang tính toán dữ liệu...");
      final meanEmbedding = _faceService.computeMeanVector(_collectedEmbeddings);

      // 6. Gửi lên Server
      setState(() => _statusMessage = "Đang lưu dữ liệu lên server...");
      final token = ref.read(authProvider).token!;
      await ref.read(attendanceApiProvider).registerFace(token, meanEmbedding);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Thành công"),
            content: const Text("Khuôn mặt đã được đăng ký thành công với độ chính xác cao!"),
            actions: [
              TextButton(onPressed: () {
                context.pop(); // Close dialog
                context.pop(); // Back to settings
              }, child: const Text("OK"))
            ],
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<img.Image?> _decodeImage(Uint8List bytes) async {
    return img.decodeImage(bytes);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    _faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký khuôn mặt")),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                CameraPreview(_controller!),
                Center(
                  child: Container(
                    width: 280, height: 350,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 3),
                        borderRadius: BorderRadius.circular(150)
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 20),
                            Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      )
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Lưu ý: Giữ khuôn mặt trong khung hình và xoay nhẹ đầu sang các hướng để tăng độ chính xác.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _startSampling,
                  icon: const Icon(Icons.face_retouching_natural),
                  label: const Text("BẮT ĐẦU QUÉT (10 LẦN)"),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}