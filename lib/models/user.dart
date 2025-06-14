class User {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'avatarUrl': avatarUrl,
    };
  }
} 