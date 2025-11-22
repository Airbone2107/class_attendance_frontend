class ApiConstants {
  // Lưu ý: Hãy đảm bảo IP này đúng với mạng của bạn (10.0.2.2 cho Emulator, hoặc IP LAN cho máy thật)
  static const String baseUrl = 'https://class-attendance-backend.onrender.com/api';
  static const String login = '/login';
  static const String teacherClasses = '/classes';
  static const String createSession = '/sessions/create';
  static const String checkIn = '/attendance/check-in';

  // Debug Endpoints
  static const String debugReset = '/debug/reset';
  static const String debugSeed = '/debug/seed';
}

