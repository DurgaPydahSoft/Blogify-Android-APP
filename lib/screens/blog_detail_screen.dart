import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/blog_post.dart';

class BlogDetailScreen extends StatelessWidget {
  final BlogPost blog;
  const BlogDetailScreen({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Blog Details', style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(blog.title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(blog.description, style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
      ),
    );
  }
} 