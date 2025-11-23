import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceService {
  Interpreter? _interpreter;

  // FaceNet input size thường là 160 hoặc 112. Kiểm tra model của bạn.
  static const int inputSize = 160;

  Future<void> initialize() async {
    try {
      final options = InterpreterOptions();
      if (Platform.isAndroid) {
        options.addDelegate(XNNPackDelegate());
      }

      // Load model từ assets
      _interpreter = await Interpreter.fromAsset('assets/facenet.tflite', options: options);

      print('✅ FaceNet Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('❌ Failed to load FaceNet model: $e');
    }
  }

  img.Image? convertCameraImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(image);
      }
      return null;
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  img.Image cropFace(img.Image originalImage, Face face) {
    final x = face.boundingBox.left.toInt();
    final y = face.boundingBox.top.toInt();
    final w = face.boundingBox.width.toInt();
    final h = face.boundingBox.height.toInt();

    final safeX = max(0, x);
    final safeY = max(0, y);
    final safeW = min(w, originalImage.width - safeX);
    final safeH = min(h, originalImage.height - safeY);

    img.Image cropped = img.copyCrop(originalImage, x: safeX, y: safeY, width: safeW, height: safeH);

    return img.copyResize(cropped, width: inputSize, height: inputSize);
  }

  Future<List<double>> getFaceEmbedding(img.Image faceImage) async {
    if (_interpreter == null) throw Exception('Interpreter not initialized');

    var input = List.generate(1, (i) => List.generate(inputSize, (y) => List.generate(inputSize, (x) => List.filled(3, 0.0))));

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = faceImage.getPixel(x, y);
        input[0][y][x][0] = (pixel.r - 127.5) / 127.5;
        input[0][y][x][1] = (pixel.g - 127.5) / 127.5;
        input[0][y][x][2] = (pixel.b - 127.5) / 127.5;
      }
    }

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outputSize = outputShape.last;

    var output = List.filled(1 * outputSize, 0.0).reshape([1, outputSize]);

    _interpreter!.run(input, output);

    return List<double>.from(output[0]);
  }

  // --- HÀM MỚI THÊM: Tính trung bình các vector ---
  List<double> computeMeanVector(List<List<double>> embeddings) {
    if (embeddings.isEmpty) return [];

    int dimension = embeddings[0].length;
    List<double> meanVector = List.filled(dimension, 0.0);

    // Cộng dồn
    for (var embedding in embeddings) {
      for (int i = 0; i < dimension; i++) {
        meanVector[i] += embedding[i];
      }
    }

    // Chia trung bình
    for (int i = 0; i < dimension; i++) {
      meanVector[i] /= embeddings.length;
    }

    return meanVector;
  }
  // ------------------------------------------------

  img.Image _convertBGRA8888ToImage(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  img.Image _convertYUV420ToImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        imgBuffer.setPixelRgb(x, y, r, g, b);
      }
    }
    return imgBuffer;
  }

  void dispose() {
    _interpreter?.close();
  }
}