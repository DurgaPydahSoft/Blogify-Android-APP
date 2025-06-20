class User {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final List<String> following; // Users this user follows
  final List<String> followers; // Users following this user
  final List<String> bookmarks; // Bookmarked blog IDs
  final List<String> readingHistory; // Recently read blog IDs
  final int totalBlogs; // Total blogs written
  final int totalLikes; // Total likes received
  final int totalComments; // Total comments received
  final DateTime createdAt;
  final DateTime? lastActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.following = const [],
    this.followers = const [],
    this.bookmarks = const [],
    this.readingHistory = const [],
    this.totalBlogs = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    required this.createdAt,
    this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      following: (json['following'] as List?)?.map((e) => e.toString()).toList() ?? [],
      followers: (json['followers'] as List?)?.map((e) => e.toString()).toList() ?? [],
      bookmarks: (json['bookmarks'] as List?)?.map((e) => e.toString()).toList() ?? [],
      readingHistory: (json['readingHistory'] as List?)?.map((e) => e.toString()).toList() ?? [],
      totalBlogs: json['totalBlogs'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'following': following,
      'followers': followers,
      'bookmarks': bookmarks,
      'readingHistory': readingHistory,
      'totalBlogs': totalBlogs,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
    };
  }

  // Helper methods
  bool isFollowing(String userId) => following.contains(userId);
  bool isFollowedBy(String userId) => followers.contains(userId);
  bool hasBookmarked(String blogId) => bookmarks.contains(blogId);
  bool hasRead(String blogId) => readingHistory.contains(blogId);
} 