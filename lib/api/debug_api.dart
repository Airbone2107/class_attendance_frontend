import 'package:class_attendance_frontend/api/api_client.dart';
import 'package:class_attendance_frontend/api/api_constants.dart';
import 'package:dio/dio.dart';

class DebugApi {
  final Dio _dio = ApiClient().dio;

  Future<String> resetDatabase() async {
    try {
      final response = await _dio.post(ApiConstants.debugReset);
      return response.data['message'] ?? 'Reset thành công';
    } catch (e) {
      throw Exception('Lỗi reset DB: $e');
    }
  }

  Future<String> seedDatabase() async {
    try {
      final response = await _dio.post(ApiConstants.debugSeed);
      return response.data['message'] ?? 'Seed thành công';
    } catch (e) {
      throw Exception('Lỗi seed DB: $e');
    }
  }
}


