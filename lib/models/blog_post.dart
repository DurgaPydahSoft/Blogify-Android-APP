class BlogPost {
  final String id;
  final String title;
  final String description;
  final String? richContent; // For rich text content
  final List<String> categories; // Blog categories
  final List<String> tags; // Blog tags
  final DateTime createdAt;
  final DateTime? updatedAt;
  final BlogAuthor? author;
  final List<String> likes;
  final List<BlogComment> comments;
  final int readCount; // Number of times read
  final bool isPublished; // Draft or published status
  final String? coverImage; // Cover image URL

  BlogPost({
    required this.id,
    required this.title,
    required this.description,
    this.richContent,
    this.categories = const [],
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.author,
    this.likes = const [],
    this.comments = const [],
    this.readCount = 0,
    this.isPublished = true,
    this.coverImage,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      richContent: json['richContent'],
      categories: (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      author: json['author'] != null ? BlogAuthor.fromJson(json['author']) : null,
      likes: (json['likes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      comments: (json['comments'] as List?)?.map((e) => BlogComment.fromJson(e)).toList() ?? [],
      readCount: json['readCount'] ?? 0,
      isPublished: json['isPublished'] ?? true,
      coverImage: json['coverImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'richContent': richContent,
      'categories': categories,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'author': author?.toJson(),
      'likes': likes,
      'comments': comments.map((c) => c.toJson()).toList(),
      'readCount': readCount,
      'isPublished': isPublished,
      'coverImage': coverImage,
    };
  }

  // Helper method to get excerpt
  String get excerpt {
    if (description.length <= 150) return description;
    return '${description.substring(0, 150)}...';
  }

  // Helper method to get reading time estimate
  int get readingTime {
    final wordCount = description.split(' ').length;
    return (wordCount / 200).ceil(); // Average reading speed: 200 words per minute
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