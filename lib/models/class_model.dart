class LessonModel {
  final String lessonId;
  final DateTime date;
  final String room;
  final String shift;
  final String status; // 'present', 'absent', 'not_checked'

  LessonModel({
    required this.lessonId,
    required this.date,
    required this.room,
    required this.shift,
    this.status = 'not_checked',
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      lessonId: json['lessonId'] ?? '',
      date: DateTime.parse(json['date']),
      room: json['room'] ?? '',
      shift: json['shift'] ?? '',
      status: json['status'] ?? 'not_checked',
    );
  }
}

class ClassModel {
  final String classId;
  final String className;
  final int credits;
  final String group;
  final List<LessonModel> lessons;

  ClassModel({
    required this.classId,
    required this.className,
    required this.credits,
    required this.group,
    this.lessons = const [],
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classId: json['classId'],
      className: json['className'],
      credits: json['credits'] ?? 0,
      group: json['group'] ?? '',
      lessons: json['lessons'] != null
          ? (json['lessons'] as List).map((e) => LessonModel.fromJson(e)).toList()
          : [],
    );
  }
}

