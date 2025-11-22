import 'package:class_attendance_frontend/api/api_constants.dart';
import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  // Private constructor
  ApiClient._()
      : _dio = Dio(
    BaseOptions(
      // Sử dụng URL từ ApiConstants để đồng bộ
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10), // Tăng timeout lên vì server free có thể chậm
      receiveTimeout: const Duration(seconds: 10),
    ),
  ) {
    // Thêm Interceptors để log request/response
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  // Singleton instance
  static final ApiClient _instance = ApiClient._();

  // Public factory constructor to return the singleton instance
  factory ApiClient() {
    return _instance;
  }

  // Getter to access the Dio instance
  Dio get dio => _dio;
}