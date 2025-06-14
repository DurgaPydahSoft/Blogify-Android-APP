import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blog_post.dart';
import '../config/api_config.dart';

class BlogService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<List<BlogPost>> getBlogs() async {
    try {
      print('Fetching blogs from: $baseUrl/api/blogs');
      print('Full URL: ${Uri.parse('$baseUrl/api/blogs')}');
      
      final response = await http.get(Uri.parse('$baseUrl/api/blogs'));
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BlogPost.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load blogs: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Client Exception: $e');
      print('Connection details:');
      print('- Base URL: $baseUrl');
      print('- Full URL: ${Uri.parse('$baseUrl/api/blogs')}');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } catch (e) {
      print('Error in getBlogs: $e');
      throw Exception('Error loading blogs: $e');
    }
  }

  Future<BlogPost> createBlog(String title, String description) async {
    try {
      final url = '$baseUrl/api/blogs';
      print('Creating blog at: $url');
      print('Full URL: ${Uri.parse(url)}');
      
      final body = {
        'title': title,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
      };
      print('Request body: $body');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        return BlogPost.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create blog: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Client Exception: $e');
      print('Connection details:');
      print('- Base URL: $baseUrl');
      print('- Full URL: ${Uri.parse('$baseUrl/api/blogs')}');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } catch (e) {
      print('Error in createBlog: $e');
      throw Exception('Error creating blog: $e');
    }
  }

  Future<void> deleteBlog(String id) async {
    try {
      final url = '$baseUrl/api/blogs/$id';
      print('Deleting blog at: $url');
      print('Full URL: ${Uri.parse(url)}');
      
      final response = await http.delete(Uri.parse(url));
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete blog: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Client Exception: $e');
      print('Connection details:');
      print('- Base URL: $baseUrl');
      print('- Full URL: ${Uri.parse('$baseUrl/api/blogs/$id')}');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } catch (e) {
      print('Error in deleteBlog: $e');
      throw Exception('Error deleting blog: $e');
    }
  }

  Future<BlogPost> updateBlog(String id, String title, String description) async {
    final url = '$baseUrl/api/blogs/$id';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'title': title,
        'description': description,
      }),
    );
    if (response.statusCode == 200) {
      return BlogPost.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update blog: ${response.body}');
    }
  }

  Future<int> likeBlog(String blogId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/api/blogs/$blogId/like'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['likes'] ?? 0;
    } else {
      throw Exception('Failed to like blog: ${response.body}');
    }
  }

  Future<int> unlikeBlog(String blogId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/api/blogs/$blogId/unlike'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['likes'] ?? 0;
    } else {
      throw Exception('Failed to unlike blog: ${response.body}');
    }
  }

  Future<List<BlogComment>> getComments(String blogId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/blogs/$blogId/comments'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BlogComment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }

  Future<List<BlogComment>> addComment(String blogId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/api/blogs/$blogId/comments'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({'text': text}),
    );
    if (response.statusCode == 201) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BlogComment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }
} 