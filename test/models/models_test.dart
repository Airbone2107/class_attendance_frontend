import 'package:class_attendance_frontend/models/class_model.dart';
import 'package:class_attendance_frontend/models/session_model.dart';
import 'package:class_attendance_frontend/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models Test', () {
    test('User.fromJson chuyển đổi đúng dữ liệu', () {
      final json = {
        'id': '123',
        'userId': 'sv001',
        'fullName': 'Nguyen Van A',
        'role': 'student'
      };

      final user = User.fromJson(json);

      expect(user.id, '123');
      expect(user.userId, 'sv001');
      expect(user.fullName, 'Nguyen Van A');
      expect(user.role, 'student');
    });

    test('ClassModel.fromJson chuyển đổi đúng dữ liệu kèm lessons', () {
      final json = {
        'classId': 'IT001',
        'className': 'Lap trinh Mobile',
        'credits': 3,
        'group': '01',
        'lessons': [
          {
            'lessonId': 'L1',
            'date': '2025-11-20T07:00:00Z',
            'room': 'A1',
            'shift': '1',
            'status': 'not_checked'
          }
        ]
      };

      final classModel = ClassModel.fromJson(json);

      expect(classModel.classId, 'IT001');
      expect(classModel.className, 'Lap trinh Mobile');
      expect(classModel.lessons.length, 1);
      expect(classModel.lessons[0].lessonId, 'L1');
      expect(classModel.lessons[0].room, 'A1');
    });

    test('SessionModel.fromJson chuyển đổi đúng dữ liệu (có expiresAt)', () {
      final dateStr = '2025-11-18T10:00:00.000Z';
      final json = {
        'sessionId': 'SESSION123',
        'level': 2,
        'expiresAt': dateStr
      };

      final session = SessionModel.fromJson(json);

      expect(session.sessionId, 'SESSION123');
      expect(session.level, 2);
      expect(session.expiresAt, DateTime.parse(dateStr));
    });

    test('SessionModel.fromJson xử lý expiresAt null', () {
      final json = {
        'sessionId': 'SESSION123',
        'level': 1,
        'expiresAt': null
      };

      final session = SessionModel.fromJson(json);

      expect(session.sessionId, 'SESSION123');
      expect(session.expiresAt, null);
    });
  });
}