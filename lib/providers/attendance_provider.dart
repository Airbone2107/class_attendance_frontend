import 'package:class_attendance_frontend/api/attendance_api.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceState {
  final String? sessionId;
  final int? sessionLevel;
  final String? nfcCardId;
  final List<double>? faceEmbedding; // Đổi từ String sang List<double>
  final bool isLoading;
  final String? error;
  final String? successClassId; // ClassID đích để điều hướng sau khi xong

  AttendanceState({
    this.sessionId,
    this.sessionLevel,
    this.nfcCardId,
    this.faceEmbedding,
    this.isLoading = false,
    this.error,
    this.successClassId,
  });

  AttendanceState copyWith({
    String? sessionId,
    int? sessionLevel,
    String? nfcCardId,
    List<double>? faceEmbedding,
    bool? isLoading,
    String? error,
    String? successClassId,
  }) {
    return AttendanceState(
      sessionId: sessionId ?? this.sessionId,
      sessionLevel: sessionLevel ?? this.sessionLevel,
      nfcCardId: nfcCardId ?? this.nfcCardId,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successClassId: successClassId ?? this.successClassId,
    );
  }
}

class AttendanceNotifier extends Notifier<AttendanceState> {
  late AttendanceApi _api;

  @override
  AttendanceState build() {
    _api = ref.watch(attendanceApiProvider);
    return AttendanceState();
  }

  void setSessionData(String id, int level) {
    state = state.copyWith(sessionId: id, sessionLevel: level, error: null);
  }

  void setNfcCardId(String id) {
    state = state.copyWith(nfcCardId: id, error: null);
  }
  
  void setFaceEmbedding(List<double> vector) {
    state = state.copyWith(faceEmbedding: vector);
  }

  void reset() {
    state = AttendanceState();
  }

  Future<void> submitCheckIn() async {
    final authState = ref.read(authProvider);
    if (authState.token == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Gọi API check-in
      final classId = await _api.checkIn(
        authState.token!,
        state.sessionId!,
        state.nfcCardId!,
        faceEmbedding: state.faceEmbedding,
      );
      // Lưu classId để UI biết đường chuyển trang
      state = state.copyWith(isLoading: false, successClassId: classId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final attendanceProvider = NotifierProvider<AttendanceNotifier, AttendanceState>(AttendanceNotifier.new);