import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/blog_post.dart';
import '../services/blog_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'write_blog_screen.dart';
import 'blog_detail_screen.dart';

class ViewBlogsScreen extends StatefulWidget {
  const ViewBlogsScreen({super.key});

  @override
  State<ViewBlogsScreen> createState() => _ViewBlogsScreenState();
}

class _ViewBlogsScreenState extends State<ViewBlogsScreen> with TickerProviderStateMixin {
  final _blogService = BlogService();
  final _userService = UserService();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  List<BlogPost> _blogs = [];
  List<BlogPost> _followingBlogs = [];
  List<BlogPost> _filteredBlogs = [];
  List<String> _categories = [];
  List<String> _tags = [];
  
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  
  // Search and filter state
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedTag;
  String _sortBy = 'newest';
  
  // UI state
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  
  // Tab controller
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      _loadBlogsForCurrentTab();
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadBlogs(),
        _loadFollowingBlogs(),
        _loadCategories(),
        _loadTags(),
      ]);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBlogs() async {
    try {
      final blogs = await _blogService.getBlogs(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        tag: _selectedTag,
        sortBy: _sortBy,
      );
      setState(() {
        _blogs = blogs;
        _filteredBlogs = blogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFollowingBlogs() async {
    try {
      final currentUser = context.read<AuthProvider>().user;
      if (currentUser != null && currentUser.following.isNotEmpty) {
        final blogs = await _blogService.getBlogsFromFollowing();
        setState(() {
          _followingBlogs = blogs;
          _updateFilteredBlogs();
        });
      } else {
        setState(() {
          _followingBlogs = [];
          _updateFilteredBlogs();
        });
      }
    } catch (e) {
      print('Error loading following blogs: $e');
      setState(() {
        _followingBlogs = [];
        _updateFilteredBlogs();
      });
    }
  }

  Future<void> _loadBlogsForCurrentTab() async {
    if (_currentTabIndex == 0) {
      await _loadBlogs();
    } else {
      await _loadFollowingBlogs();
    }
  }

  void _updateFilteredBlogs() {
    final currentBlogs = _currentTabIndex == 0 ? _blogs : _followingBlogs;
    setState(() {
      _filteredBlogs = currentBlogs.where((blog) {
        bool matchesSearch = _searchQuery.isEmpty ||
            blog.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            blog.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            blog.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        
        bool matchesCategory = _selectedCategory == null ||
            blog.categories.contains(_selectedCategory);
        
        bool matchesTag = _selectedTag == null ||
            blog.tags.contains(_selectedTag);
        
        return matchesSearch && matchesCategory && matchesTag;
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _blogService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _blogService.getTags();
      setState(() {
        _tags = tags;
      });
    } catch (e) {
      print('Error loading tags: $e');
    }
  }

  void _onRefresh() async {
    await _loadBlogsForCurrentTab();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await _loadBlogsForCurrentTab();
    _refreshController.loadComplete();
  }

  void _applyFilters() {
    _updateFilteredBlogs();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedTag = null;
      _sortBy = 'newest';
      _searchController.clear();
    });
    _updateFilteredBlogs();
  }

  Future<void> _deleteBlog(String id) async {
    try {
      await _blogService.deleteBlog(id);
      setState(() {
        _blogs.removeWhere((blog) => blog.id == id);
        _filteredBlogs.removeWhere((blog) => blog.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blog deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting blog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(BlogPost blog) async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;
    
    final isLiked = blog.likes.contains(currentUser.id);
    try {
      if (isLiked) {
        await _blogService.unlikeBlog(blog.id);
      } else {
        await _blogService.likeBlog(blog.id);
      }
      await _loadBlogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleBookmark(BlogPost blog) async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;
    
    final isBookmarked = currentUser.hasBookmarked(blog.id);
    try {
      if (isBookmarked) {
        await _blogService.unbookmarkBlog(blog.id);
      } else {
        await _blogService.bookmarkBlog(blog.id);
      }
      // Refresh the current user data to update bookmark status
      await context.read<AuthProvider>().getCurrentUser();
      setState(() {}); // Rebuild to show updated bookmark status
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
      setState(() {});
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareBlog(BlogPost blog) {
    Share.share(
      'Check out this blog: ${blog.title}\n\n${blog.excerpt}',
      subject: blog.title,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Column(
                    children: [
                      _buildSearchAndFilters(),
                      Expanded(
                        child: _buildContent(),
                      ),
                    ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Discover Blogs',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
          IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WriteBlogScreen()),
              );
            },
          ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF6D5DF6),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'All Blogs'),
                Tab(text: 'Following'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search blogs...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6D5DF6)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),
          
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category Filter
                if (_categories.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      hint: Text('Category', style: GoogleFonts.poppins(fontSize: 12)),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, style: GoogleFonts.poppins(fontSize: 12)),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                
                // Tag Filter
                if (_tags.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: DropdownButton<String>(
                      value: _selectedTag,
                      hint: Text('Tag', style: GoogleFonts.poppins(fontSize: 12)),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Tags'),
                        ),
                        ..._tags.map((tag) => DropdownMenuItem<String>(
                          value: tag,
                          child: Text(tag, style: GoogleFonts.poppins(fontSize: 12)),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTag = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                
                // Sort Options
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    hint: Text('Sort', style: GoogleFonts.poppins(fontSize: 12)),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'newest',
                        child: Text('Newest', style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                      DropdownMenuItem<String>(
                        value: 'oldest',
                        child: Text('Oldest', style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                      DropdownMenuItem<String>(
                        value: 'popular',
                        child: Text('Popular', style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                      DropdownMenuItem<String>(
                        value: 'mostLiked',
                        child: Text('Most Liked', style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                      _loadBlogs();
                    },
                  ),
                ),
                
                // Clear Filters
                if (_searchQuery.isNotEmpty || _selectedCategory != null || _selectedTag != null)
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Clear',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6D5DF6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading blogs',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredBlogs.isEmpty) {
      return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
              'No blogs found',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      enablePullDown: true,
      enablePullUp: true,
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 200,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 150,
                  color: Colors.white,
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBlogs.length,
      itemBuilder: (context, index) {
        return _buildBlogCard(_filteredBlogs[index], isGrid: true);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
                      padding: const EdgeInsets.all(16),
      itemCount: _filteredBlogs.length,
                      itemBuilder: (context, index) {
        return _buildBlogCard(_filteredBlogs[index], isGrid: false);
      },
    );
  }

  Widget _buildBlogCard(BlogPost blog, {required bool isGrid}) {
                        final currentUser = context.read<AuthProvider>().user;
    final isLiked = currentUser != null && blog.likes.contains(currentUser.id);
    final isBookmarked = currentUser != null && currentUser.hasBookmarked(blog.id);
    final isAuthor = currentUser != null && blog.author?.id == currentUser.id;

                        return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
        onTap: () async {
          await _blogService.incrementReadCount(blog.id);
          if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlogDetailScreen(blog: blog),
                                ),
                              );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            if (blog.coverImage != null)
              Container(
                height: isGrid ? 120 : 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(blog.coverImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                  // Categories
                  if (blog.categories.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: blog.categories.take(2).map((category) => Chip(
                        label: Text(
                          category,
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                        backgroundColor: const Color(0xFF6D5DF6).withOpacity(0.1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Title
                  Text(
                    blog.title,
                    style: GoogleFonts.poppins(
                      fontSize: isGrid ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: isGrid ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    blog.excerpt,
                    style: GoogleFonts.poppins(
                      fontSize: isGrid ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: isGrid ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Author and Date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF6D5DF6),
                        child: Text(
                          blog.author?.name.substring(0, 1).toUpperCase() ?? 'A',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog.author?.name ?? 'Anonymous',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(blog.createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Follow button (only show if not the current user's blog)
                      if (currentUser != null && blog.author?.id != currentUser.id)
                        GestureDetector(
                          onTap: () => _toggleFollow(blog.author!.id, blog.author!.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentUser.isFollowing(blog.author!.id) 
                                  ? Colors.grey[300] 
                                  : const Color(0xFF6D5DF6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentUser.isFollowing(blog.author!.id) ? 'Following' : 'Follow',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: currentUser.isFollowing(blog.author!.id) 
                                    ? Colors.grey[600] 
                                    : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Stats and Actions
                  Row(
                    children: [
                      // Reading time
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${blog.readingTime} min read',
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                      ),
                      
                      const Spacer(),
                      
                      // Like button
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isLiked ? Colors.red : Colors.grey[500],
                        ),
                        onPressed: () => _toggleLike(blog),
                      ),
                      
                      // Bookmark button
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 20,
                          color: isBookmarked ? Colors.yellow : Colors.grey[500],
                        ),
                        onPressed: () => _toggleBookmark(blog),
                      ),
                      
                      // Share button
                      IconButton(
                        icon: Icon(Icons.share, size: 20, color: Colors.grey[500]),
                        onPressed: () => _shareBlog(blog),
                      ),
                      
                      // More options for author
                      if (isAuthor)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[500]),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WriteBlogScreen(blogToEdit: blog),
                                  ),
                                );
                                break;
                              case 'delete':
                                _showDeleteDialog(blog);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                    ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
      ),
    );
  }

  void _showDeleteDialog(BlogPost blog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Blog', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete "${blog.title}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBlog(blog.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 