class User {
  final String id;
  final String userId;
  final String fullName;
  final String role;

  User({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userId: json['userId'],
      fullName: json['fullName'],
      role: json['role'],
    );
  }
}