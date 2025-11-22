import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:class_attendance_frontend/models/session_model.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:class_attendance_frontend/screens/auth/login_screen.dart';
import 'package:class_attendance_frontend/screens/debug/debug_screen.dart';
import 'package:class_attendance_frontend/screens/student/attendance/face_scan_screen.dart';
import 'package:class_attendance_frontend/screens/student/attendance/nfc_scan_screen.dart';
import 'package:class_attendance_frontend/screens/student/attendance/qr_scan_screen.dart';
import 'package:class_attendance_frontend/screens/student/course_detail_screen.dart';
import 'package:class_attendance_frontend/screens/student/student_home_screen.dart';
import 'package:class_attendance_frontend/screens/teacher/class_detail_screen.dart';
import 'package:class_attendance_frontend/screens/teacher/session/create_session_screen.dart';
import 'package:class_attendance_frontend/screens/teacher/session/session_monitoring_screen.dart';
import 'package:class_attendance_frontend/screens/teacher/teacher_home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final target = state.uri.toString();
      final isLoginRoute = target == '/login';
      final isDebugRoute = target == '/debug';

      if (isDebugRoute) return null;

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        if (authState.user?.role == 'teacher') {
          return '/teacher/home';
        } else {
          return '/student/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/debug',
        builder: (context, state) => const DebugScreen(),
      ),
      // --- TEACHER ROUTES ---
      GoRoute(
        path: '/teacher/home',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: '/teacher/class-detail',
        builder: (context, state) {
          final classModel = state.extra as ClassModel;
          return TeacherClassDetailScreen(classModel: classModel);
        },
      ),
      GoRoute(
        path: '/teacher/create-session',
        builder: (context, state) {
          // Truyền cả ClassModel và LessonId qua map
          final args = state.extra as Map<String, dynamic>;
          return CreateSessionScreen(
            classInfo: args['class'] as ClassModel,
            lessonId: args['lessonId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/teacher/monitor',
        builder: (context, state) {
          final session = state.extra as SessionModel;
          return SessionMonitoringScreen(session: session);
        },
      ),
      // --- STUDENT ROUTES ---
      GoRoute(
        path: '/student/home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/student/course-detail/:classId',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          return StudentCourseDetailScreen(classId: classId);
        },
      ),
      GoRoute(
        path: '/student/scan-qr',
        builder: (context, state) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/student/scan-nfc',
        builder: (context, state) => const NfcScanScreen(),
      ),
      GoRoute(
        path: '/student/scan-face',
        builder: (context, state) => const FaceScanScreen(),
      ),
    ],
  );
});