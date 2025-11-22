class SessionModel {
  final String sessionId;
  final int level;
  final DateTime? expiresAt;

  SessionModel({
    required this.sessionId,
    required this.level,
    this.expiresAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['sessionId'],
      level: json['level'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }
}

