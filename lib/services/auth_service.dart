import 'package:class_attendance_frontend/api/api_client.dart';
import 'package:class_attendance_frontend/models/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Thêm import

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<(User, String)> login(String userId, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'userId': userId,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data['user']);
        final token = response.data['token'].toString();
        return (user, token);
      } else {
        throw Exception('Failed to login with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Lỗi không xác định. Vui lòng thử lại.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }
}

// Thêm Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());