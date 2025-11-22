import 'dart:convert';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  static String? generateFaceSignature(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

    if (leftEye == null || rightEye == null || noseBase == null || bottomMouth == null) {
      return null;
    }

    double calculateDistance(Point<int> p1, Point<int> p2) {
      return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
    }

    final eyeDist = calculateDistance(leftEye.position, rightEye.position);
    final noseMouthDist = calculateDistance(noseBase.position, bottomMouth.position);

    final Map<String, dynamic> signature = {
      'eye_distance': eyeDist.toStringAsFixed(2),
      'nose_mouth_distance': noseMouthDist.toStringAsFixed(2),
      'bounds': face.boundingBox.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(signature);
  }
}

