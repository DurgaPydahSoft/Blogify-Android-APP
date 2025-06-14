import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';

class ProfileService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<User> getUserProfile(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/profile/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user profile: ${response.body}');
    }
  }

  Future<User> updateUserProfile(
    String userId,
    String token, {
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/profile/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user profile: ${response.body}');
    }
  }

  Future<String> uploadAvatar(File imageFile, String token) async {
    final uri = Uri.parse('$baseUrl/api/upload/avatar');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    } else {
      throw Exception('Failed to upload avatar: ${response.body}');
    }
  }
} 