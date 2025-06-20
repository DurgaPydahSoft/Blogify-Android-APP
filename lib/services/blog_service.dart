import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blog_post.dart';
import '../config/api_config.dart';

class BlogService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<List<BlogPost>> getBlogs({String? search, String? category, String? tag, String? sortBy}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;

      final uri = Uri.parse('$baseUrl/api/blogs').replace(queryParameters: queryParams);
      print('Fetching blogs from: $uri');
      
      final response = await http.get(uri);
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BlogPost.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load blogs: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Client Exception: $e');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } catch (e) {
      print('Error in getBlogs: $e');
      throw Exception('Error loading blogs: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/blogs/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e.toString()).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getCategories: $e');
      throw Exception('Error loading categories: $e');
    }
  }

  Future<List<String>> getTags() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/blogs/tags'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e.toString()).toList();
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTags: $e');
      throw Exception('Error loading tags: $e');
    }
  }

  Future<BlogPost> createBlog(
    String title, 
    String description, 
    {List<String>? categories, List<String>? tags, String? coverImage, bool isPublished = true}
  ) async {
    try {
      final url = '$baseUrl/api/blogs';
      print('Creating blog at: $url');
      
      final body = {
        'title': title,
        'description': description,
        'categories': categories ?? [],
        'tags': tags ?? [],
        'coverImage': coverImage,
        'isPublished': isPublished,
        'createdAt': DateTime.now().toIso8601String(),
      };
      print('Request body: $body');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('You must be logged in to create a blog. Please login first.');
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        return BlogPost.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to create blog: ${errorBody['message'] ?? 'Unknown error'}');
      }
    } on http.ClientException catch (e) {
      print('Client Exception: $e');
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
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('You must be logged in to delete a blog. Please login first.');
      }
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to delete blog: ${errorBody['message'] ?? 'Unknown error'}');
      }
    } on http.ClientException catch (e) {
      print('Client Exception: $e');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    } catch (e) {
      print('Error in deleteBlog: $e');
      throw Exception('Error deleting blog: $e');
    }
  }

  Future<BlogPost> updateBlog(
    String id, 
    String title, 
    String description, 
    {List<String>? categories, List<String>? tags, String? coverImage, bool? isPublished}
  ) async {
    final url = '$baseUrl/api/blogs/$id';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to update a blog. Please login first.');
    }
    
    final body = {
      'title': title,
      'description': description,
      'categories': categories,
      'tags': tags,
      'coverImage': coverImage,
      'isPublished': isPublished,
    };
    
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
    
    if (response.statusCode == 200) {
      return BlogPost.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please login again.');
    } else {
      final errorBody = json.decode(response.body);
      throw Exception('Failed to update blog: ${errorBody['message'] ?? 'Unknown error'}');
    }
  }

  Future<void> incrementReadCount(String blogId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/blogs/$blogId/read'));
      if (response.statusCode != 200) {
        print('Failed to increment read count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error incrementing read count: $e');
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
    
    if (token == null) {
      throw Exception('You must be logged in to comment.');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/blogs/$blogId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'text': text}),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BlogComment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  // Bookmark functionality
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

  // Get bookmarked blogs
  Future<List<BlogPost>> getBookmarkedBlogs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('You must be logged in to view bookmarks.');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/blogs/bookmarked'),
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

  // Get blogs from following users
  Future<List<BlogPost>> getBlogsFromFollowing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('You must be logged in to view following blogs.');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/blogs/following'),
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
        throw Exception(errorBody['message'] ?? 'Failed to load following blogs');
      }
    } catch (e) {
      print('Error in getBlogsFromFollowing: $e');
      throw Exception('Error loading following blogs: $e');
    }
  }
} 