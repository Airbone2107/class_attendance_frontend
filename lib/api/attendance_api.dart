import 'package:class_attendance_frontend/api/api_client.dart';
import 'package:class_attendance_frontend/api/api_constants.dart';
import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:class_attendance_frontend/models/session_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceApi {
  final Dio _dio = ApiClient().dio;

  // --- STUDENT APIs ---
  Future<List<ClassModel>> getStudentClasses(String token) async {
    final response = await _dio.get(
      '/attendance/classes',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List).map((e) => ClassModel.fromJson(e)).toList();
  }

  Future<ClassModel> getStudentClassDetail(String token, String classId) async {
    final response = await _dio.get(
      '/attendance/history/$classId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ClassModel.fromJson(response.data);
  }

  // Check-in: Cập nhật faceEmbedding là List<double>
  Future<String> checkIn(String token, String sessionId, String nfcCardId, {List<double>? faceEmbedding}) async {
    // SỬA LỖI: Khai báo rõ kiểu Map<String, dynamic>
    final Map<String, dynamic> data = {
      'sessionId': sessionId,
      'nfcCardId': nfcCardId,
    };
    if (faceEmbedding != null) {
      data['faceEmbedding'] = faceEmbedding;
    }

    final response = await _dio.post(
      ApiConstants.checkIn,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['classId'];
  }

  // Đăng ký khuôn mặt
  Future<void> registerFace(String token, List<double> faceEmbedding) async {
    await _dio.post(
      '/users/register-face',
      data: {'faceEmbedding': faceEmbedding},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // --- TEACHER APIs ---
  Future<List<ClassModel>> getTeacherClasses(String token) async {
    final response = await _dio.get(
      ApiConstants.teacherClasses,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List).map((e) => ClassModel.fromJson(e)).toList();
  }

  Future<SessionModel> createSession(String token, String classId, String lessonId, int level) async {
    final response = await _dio.post(
      ApiConstants.createSession,
      data: {'classId': classId, 'lessonId': lessonId, 'level': level},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SessionModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getSessionStats(String token, String sessionId) async {
    final response = await _dio.get(
      '/sessions/$sessionId/stats',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }
}

final attendanceApiProvider = Provider<AttendanceApi>((ref) => AttendanceApi());