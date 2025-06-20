import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../services/blog_service.dart';
import '../services/profile_service.dart';
import '../models/blog_post.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class WriteBlogScreen extends StatefulWidget {
  final BlogPost? blogToEdit; // For editing existing blog
  
  const WriteBlogScreen({super.key, this.blogToEdit});

  @override
  State<WriteBlogScreen> createState() => _WriteBlogScreenState();
}

class _WriteBlogScreenState extends State<WriteBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _blogService = BlogService();
  final _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();
  
  // Enhanced fields
  List<String> _selectedCategories = [];
  List<String> _selectedTags = [];
  List<String> _availableCategories = [];
  List<String> _availableTags = [];
  String? _coverImageUrl;
  File? _coverImageFile;
  bool _isLoading = false;
  bool _isPublished = true;
  bool _isDraft = false;
  
  // Auto-save timer
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndTags();
    
    if (widget.blogToEdit != null) {
      _loadBlogForEditing();
    }
    
    // Auto-save every 30 seconds
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _autoSave();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCategoriesAndTags() async {
    try {
      final categories = await _blogService.getCategories();
      final tags = await _blogService.getTags();
      setState(() {
        _availableCategories = categories;
        _availableTags = tags;
      });
    } catch (e) {
      print('Error loading categories and tags: $e');
    }
  }

  void _loadBlogForEditing() {
    final blog = widget.blogToEdit!;
    _titleController.text = blog.title;
    _descriptionController.text = blog.description;
    _selectedCategories = List.from(blog.categories);
    _selectedTags = List.from(blog.tags);
    _coverImageUrl = blog.coverImage;
    _isPublished = blog.isPublished;
  }

  Future<void> _autoSave() async {
    if (_titleController.text.isNotEmpty || _descriptionController.text.isNotEmpty) {
      try {
        await _saveDraft();
      } catch (e) {
        print('Auto-save failed: $e');
      }
    }
  }

  Future<void> _saveDraft() async {
    if (_titleController.text.isEmpty && _descriptionController.text.isEmpty) return;
    
    try {
      await _blogService.createBlog(
        _titleController.text.isEmpty ? 'Untitled Draft' : _titleController.text,
        _descriptionController.text.isEmpty ? 'No content yet' : _descriptionController.text,
        categories: _selectedCategories,
        tags: _selectedTags,
        coverImage: _coverImageUrl,
        isPublished: false,
      );
    } catch (e) {
      print('Error saving draft: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
        _isLoading = true;
      });
      
      try {
        final url = await _profileService.uploadAvatar(_coverImageFile!, '');
        setState(() {
          _coverImageUrl = url;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
      }
    }
  }

  Future<void> _submitBlog() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (widget.blogToEdit != null) {
          // Update existing blog
          await _blogService.updateBlog(
            widget.blogToEdit!.id,
            _titleController.text,
            _descriptionController.text,
            categories: _selectedCategories,
            tags: _selectedTags,
            coverImage: _coverImageUrl,
            isPublished: _isPublished,
          );
        } else {
          // Create new blog
          await _blogService.createBlog(
            _titleController.text,
            _descriptionController.text,
            categories: _selectedCategories,
            tags: _selectedTags,
            coverImage: _coverImageUrl,
            isPublished: _isPublished,
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isPublished ? 'Blog published successfully!' : 'Draft saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6D5DF6),
                Color(0xFF46A0FC),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Authentication Required',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You must be logged in to create blogs.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6D5DF6),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Login Now',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/signup');
                      },
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6D5DF6),
              Color(0xFF46A0FC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCoverImageSection(),
                                const SizedBox(height: 24),
                                _buildTitleSection(),
                                const SizedBox(height: 24),
                                _buildContentSection(),
                                const SizedBox(height: 24),
                                _buildCategoriesSection(),
                                const SizedBox(height: 16),
                                _buildTagsSection(),
                                const SizedBox(height: 24),
                                _buildPublishOptions(),
                                const SizedBox(height: 32),
                                _buildActionButtons(),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            widget.blogToEdit != null ? 'Edit Blog' : 'Write a Blog',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (_isDraft)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Draft',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Image',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6D5DF6),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _coverImageUrl != null || _coverImageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _coverImageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _coverImageFile != null
                            ? Image.file(_coverImageFile!, fit: BoxFit.cover)
                            : _buildPlaceholder();
                      },
                    ),
                  )
                : _buildPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Add Cover Image',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6D5DF6),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter your blog title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.title, color: Color(0xFF6D5DF6)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            if (value.length < 3) {
              return 'Title must be at least 3 characters long';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6D5DF6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Write your blog content here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 15,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter content';
              }
              if (value.length < 10) {
                return 'Content must be at least 10 characters long';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6D5DF6),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._availableCategories.map((category) => FilterChip(
              label: Text(category),
              selected: _selectedCategories.contains(category),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            )),
            ActionChip(
              label: const Text('+ Add New'),
              onPressed: _showAddCategoryDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6D5DF6),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedTags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  _selectedTags.remove(tag);
                });
              },
            )),
            ActionChip(
              label: const Text('+ Add Tag'),
              onPressed: _showAddTagDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPublishOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Publish Options',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6D5DF6),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(
            'Publish immediately',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            'Uncheck to save as draft',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          value: _isPublished,
          onChanged: (value) {
            setState(() {
              _isPublished = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isPublished = false);
              await _submitBlog();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Save Draft',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitBlog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D5DF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isPublished ? 'Publish Blog' : 'Save Draft',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Category', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _selectedCategories.add(controller.text.trim());
                  if (!_availableCategories.contains(controller.text.trim())) {
                    _availableCategories.add(controller.text.trim());
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Tag', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tag Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _selectedTags.add(controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 