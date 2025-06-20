import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/blog_post.dart';
import '../models/user.dart';
import '../services/blog_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';

class BlogDetailScreen extends StatefulWidget {
  final BlogPost blog;
  
  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final _blogService = BlogService();
  final _userService = UserService();
  final _commentController = TextEditingController();
  
  List<BlogComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isAddingComment = false;
  bool _isLiked = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _checkLikeStatus();
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _checkLikeStatus() {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser != null) {
      setState(() {
        _isLiked = widget.blog.likes.contains(currentUser.id);
      });
    }
  }

  void _checkBookmarkStatus() {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser != null) {
      setState(() {
        _isBookmarked = currentUser.hasBookmarked(widget.blog.id);
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _blogService.getComments(widget.blog.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() => _isLoadingComments = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAddingComment = true);
    try {
      final comments = await _blogService.addComment(widget.blog.id, text);
      setState(() {
        _comments = comments;
        _commentController.clear();
        _isAddingComment = false;
      });
    } catch (e) {
      setState(() => _isAddingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    try {
      if (_isLiked) {
        await _blogService.unlikeBlog(widget.blog.id);
      } else {
        await _blogService.likeBlog(widget.blog.id);
      }
      setState(() {
        _isLiked = !_isLiked;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleBookmark() async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    try {
      if (_isBookmarked) {
        await _blogService.unbookmarkBlog(widget.blog.id);
      } else {
        await _blogService.bookmarkBlog(widget.blog.id);
      }
      
      // Refresh the current user data to update bookmark status
      await context.read<AuthProvider>().getCurrentUser();
      
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked ? 'Blog bookmarked!' : 'Blog removed from bookmarks'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollow(String userId, String authorName) async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;
    final isFollowing = currentUser.isFollowing(userId);
    try {
      if (isFollowing) {
        await _userService.unfollowUser(userId);
      } else {
        await _userService.followUser(userId);
      }
      await context.read<AuthProvider>().getCurrentUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? 'Unfollowed $authorName' : 'Following $authorName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _shareBlog() {
    Share.share(
      'Check out this blog: ${widget.blog.title}\n\n${widget.blog.excerpt}',
      subject: widget.blog.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBlogHeader(),
                  const SizedBox(height: 24),
                  _buildBlogContent(),
                  const SizedBox(height: 32),
                  _buildBlogStats(),
                  const SizedBox(height: 24),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF6D5DF6),
      flexibleSpace: FlexibleSpaceBar(
        background: widget.blog.coverImage != null
            ? CachedNetworkImage(
                imageUrl: widget.blog.coverImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              )
            : Container(
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
                child: const Center(
                  child: Icon(Icons.article, size: 64, color: Colors.white),
                ),
              ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
          ),
          onPressed: _toggleLike,
        ),
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: _isBookmarked ? Colors.yellow : Colors.white,
          ),
          onPressed: _toggleBookmark,
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareBlog,
        ),
      ],
    );
  }

  Widget _buildBlogHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories
        if (widget.blog.categories.isNotEmpty)
          Wrap(
            spacing: 8,
            children: widget.blog.categories.map((category) => Chip(
              label: Text(
                category,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: const Color(0xFF6D5DF6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        
        const SizedBox(height: 16),
        
        // Title
        Text(
          widget.blog.title,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Author and Date
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF6D5DF6),
              child: Text(
                widget.blog.author?.name.substring(0, 1).toUpperCase() ?? 'A',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.blog.author?.name ?? 'Anonymous',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM dd, yyyy').format(widget.blog.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Follow button (only show if not the current user's blog)
            if (widget.blog.author != null)
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final currentUser = authProvider.user;
                  if (currentUser == null || widget.blog.author!.id == currentUser.id) {
                    return const SizedBox.shrink();
                  }
                  
                  final isFollowing = currentUser.isFollowing(widget.blog.author!.id);
                  return GestureDetector(
                    onTap: () => _toggleFollow(widget.blog.author!.id, widget.blog.author!.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFollowing ? Colors.grey[300] : const Color(0xFF6D5DF6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFollowing ? Colors.grey[400]! : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isFollowing ? Colors.grey[600] : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Tags
        if (widget.blog.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: widget.blog.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '#$tag',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildBlogContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reading time and word count
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${widget.blog.readingTime} min read',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Icon(Icons.text_fields, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${widget.blog.description.split(' ').length} words',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Blog content
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            widget.blog.description,
            style: GoogleFonts.poppins(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlogStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.visibility, '${widget.blog.readCount}', 'Views'),
          _buildStatItem(Icons.favorite, '${widget.blog.likes.length}', 'Likes'),
          _buildStatItem(Icons.comment, '${_comments.length}', 'Comments'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6D5DF6), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${_comments.length})',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Add comment
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isAddingComment ? null : _addComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D5DF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAddingComment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Comments list
        if (_isLoadingComments)
          const Center(child: CircularProgressIndicator())
        else if (_comments.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No comments yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to comment!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF6D5DF6),
                            child: Text(
                              comment.userName.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.userName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(comment.createdAt),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        comment.text,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
} 