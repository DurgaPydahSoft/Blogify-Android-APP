import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/blog_post.dart';

class UserService {
  final String baseUrl = ApiConfig.baseUrl;

  // Follow/Unfollow user
  Future<void> followUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to follow users.');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/$userId/follow'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to follow user');
    }
  }

  Future<void> unfollowUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to unfollow users.');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/$userId/unfollow'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to unfollow user');
    }
  }

  // Bookmark/Unbookmark blog
  Future<void> bookmarkBlog(String blogId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to bookmark blogs.');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/blogs/$blogId/bookmark'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to bookmark blog');
    }
  }

  Future<void> unbookmarkBlog(String blogId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to unbookmark blogs.');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/blogs/$blogId/unbookmark'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to unbookmark blog');
    }
  }

  // Get user's bookmarked blogs
  Future<List<BlogPost>> getBookmarkedBlogs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to view bookmarks.');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/bookmarks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BlogPost.fromJson(json)).toList();
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load bookmarks');
    }
  }

  // Get user's reading history
  Future<List<BlogPost>> getReadingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to view reading history.');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/reading-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BlogPost.fromJson(json)).toList();
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load reading history');
    }
  }

  // Get user's dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to view dashboard.');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/dashboard'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load dashboard');
    }
  }

  // Get user's activity feed
  Future<List<Map<String, dynamic>>> getActivityFeed() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to view activity feed.');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/activity-feed'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => json as Map<String, dynamic>).toList();
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load activity feed');
    }
  }

  // Get users that the current user follows
  Future<List<User>> getFollowing() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to view following.');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/following'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load following');
    }
  }

  // Get users following the current user
  Future<List<User>> getFollowers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to view followers.');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/followers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load followers');
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to search users.');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/search?q=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to search users');
    }
  }
} 