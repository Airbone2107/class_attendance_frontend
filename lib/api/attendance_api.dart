import 'package:class_attendance_frontend/api/api_client.dart';
import 'package:class_attendance_frontend/api/api_constants.dart';
import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:class_attendance_frontend/models/session_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceApi {
  final Dio _dio = ApiClient().dio;

  // --- STUDENT APIs ---
  // Lấy danh sách lớp (Tab 3)
  Future<List<ClassModel>> getStudentClasses(String token) async {
    final response = await _dio.get(
      '/attendance/classes',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List).map((e) => ClassModel.fromJson(e)).toList();
  }

  // Lấy chi tiết lớp và trạng thái các buổi (Màn hình chi tiết)
  Future<ClassModel> getStudentClassDetail(String token, String classId) async {
    final response = await _dio.get(
      '/attendance/history/$classId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ClassModel.fromJson(response.data);
  }

  // Check-in: Trả về classId để redirect
  Future<String> checkIn(String token, String sessionId, String nfcCardId, {String? faceVector}) async {
    final data = {
      'sessionId': sessionId,
      'nfcCardId': nfcCardId,
    };
    if (faceVector != null) {
      data['faceVector'] = faceVector;
    }

    final response = await _dio.post(
      ApiConstants.checkIn,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['classId'];
  }

  // --- TEACHER APIs ---
  Future<List<ClassModel>> getTeacherClasses(String token) async {
    final response = await _dio.get(
      ApiConstants.teacherClasses,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List).map((e) => ClassModel.fromJson(e)).toList();
  }

  // Tạo session cho 1 buổi học cụ thể
  Future<SessionModel> createSession(String token, String classId, String lessonId, int level) async {
    final response = await _dio.post(
      ApiConstants.createSession,
      data: {'classId': classId, 'lessonId': lessonId, 'level': level},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SessionModel.fromJson(response.data);
  }

  // Lấy thống kê (số lượng đã check-in)
  Future<Map<String, dynamic>> getSessionStats(String token, String sessionId) async {
    final response = await _dio.get(
      '/sessions/$sessionId/stats',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }
}

final attendanceApiProvider = Provider<AttendanceApi>((ref) => AttendanceApi());