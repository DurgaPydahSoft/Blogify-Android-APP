class BlogPost {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final BlogAuthor? author;
  final List<String> likes;
  final List<BlogComment> comments;

  BlogPost({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.author,
    this.likes = const [],
    this.comments = const [],
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      author: json['author'] != null ? BlogAuthor.fromJson(json['author']) : null,
      likes: (json['likes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      comments: (json['comments'] as List?)?.map((e) => BlogComment.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'author': author?.toJson(),
      'likes': likes,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }
}

class BlogAuthor {
  final String id;
  final String name;
  final String email;

  BlogAuthor({required this.id, required this.name, required this.email});

  factory BlogAuthor.fromJson(Map<String, dynamic> json) {
    return BlogAuthor(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
    };
  }
}

class BlogComment {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime createdAt;

  BlogComment({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.createdAt,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return BlogComment(
      id: json['id'] ?? json['_id'] ?? '',
      text: json['text'] ?? '',
      userId: user['id'] ?? user['_id'] ?? '',
      userName: user['name'] ?? '',
      userEmail: user['email'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'text': text,
      'user': {
        '_id': userId,
        'name': userName,
        'email': userEmail,
      },
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 