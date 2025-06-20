import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../services/blog_service.dart';
import '../models/user.dart';
import '../models/blog_post.dart';
import 'blog_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _blogService = BlogService();
  
  late TabController _tabController;
  
  Map<String, dynamic> _stats = {};
  List<BlogPost> _bookmarks = [];
  List<BlogPost> _readingHistory = [];
  List<Map<String, dynamic>> _activityFeed = [];
  List<User> _following = [];
  List<User> _followers = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadStats(),
        _loadBookmarks(),
        _loadReadingHistory(),
        _loadActivityFeed(),
        _loadFollowing(),
        _loadFollowers(),
      ]);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _userService.getDashboardStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _blogService.getBookmarkedBlogs();
      setState(() {
        _bookmarks = bookmarks;
      });
    } catch (e) {
      print('Error loading bookmarks: $e');
    }
  }

  Future<void> _loadReadingHistory() async {
    try {
      final history = await _userService.getReadingHistory();
      setState(() {
        _readingHistory = history;
      });
    } catch (e) {
      print('Error loading reading history: $e');
    }
  }

  Future<void> _loadActivityFeed() async {
    try {
      final feed = await _userService.getActivityFeed();
      setState(() {
        _activityFeed = feed;
      });
    } catch (e) {
      print('Error loading activity feed: $e');
    }
  }

  Future<void> _loadFollowing() async {
    try {
      final following = await _userService.getFollowing();
      setState(() {
        _following = following;
      });
    } catch (e) {
      print('Error loading following: $e');
    }
  }

  Future<void> _loadFollowers() async {
    try {
      final followers = await _userService.getFollowers();
      setState(() {
        _followers = followers;
      });
    } catch (e) {
      print('Error loading followers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    
    if (user == null) {
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
          child: const Center(
            child: Text(
              'Please login to view dashboard',
              style: TextStyle(color: Colors.white, fontSize: 18),
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
                      : _error != null
                          ? _buildErrorWidget()
                          : _buildDashboardContent(),
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
            'Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading dashboard',
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
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        _buildStatsSection(),
        const SizedBox(height: 16),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookmarksTab(),
              _buildReadingHistoryTab(),
              _buildActivityFeedTab(),
              _buildSocialTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D5DF6), Color(0xFF46A0FC)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Blogs', _stats['totalBlogs']?.toString() ?? '0', Icons.article),
          _buildStatItem('Likes', _stats['totalLikes']?.toString() ?? '0', Icons.favorite),
          _buildStatItem('Comments', _stats['totalComments']?.toString() ?? '0', Icons.comment),
          _buildStatItem('Followers', _stats['followers']?.toString() ?? '0', Icons.people),
          _buildStatItem('Following', _stats['following']?.toString() ?? '0', Icons.people_outline),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        tabs: [
          Tab(text: 'Bookmarks (${_bookmarks.length})'),
          Tab(text: 'History (${_readingHistory.length})'),
          Tab(text: 'Activity'),
          Tab(text: 'Social'),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab() {
    if (_bookmarks.isEmpty) {
      return _buildEmptyState('No bookmarks yet', 'Start bookmarking blogs you love!', Icons.bookmark_border);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        return _buildBlogCard(_bookmarks[index]);
      },
    );
  }

  Widget _buildReadingHistoryTab() {
    if (_readingHistory.isEmpty) {
      return _buildEmptyState('No reading history', 'Start reading blogs to see your history here!', Icons.history);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _readingHistory.length,
      itemBuilder: (context, index) {
        return _buildBlogCard(_readingHistory[index]);
      },
    );
  }

  Widget _buildActivityFeedTab() {
    if (_activityFeed.isEmpty) {
      return _buildEmptyState('No activity yet', 'Your activity will appear here!', Icons.timeline);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activityFeed.length,
      itemBuilder: (context, index) {
        final activity = _activityFeed[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSocialSection('Following', _following, Icons.people_outline),
          const SizedBox(height: 24),
          _buildSocialSection('Followers', _followers, Icons.people),
        ],
      ),
    );
  }

  Widget _buildSocialSection(String title, List<User> users, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6D5DF6)),
            const SizedBox(width: 8),
            Text(
              '$title (${users.length})',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (users.isEmpty)
          Text(
            'No $title yet',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserCard(users[index]);
            },
          ),
      ],
    );
  }

  Widget _buildBlogCard(BlogPost blog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlogDetailScreen(blog: blog),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                blog.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                blog.excerpt,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF6D5DF6),
                    child: Text(
                      blog.author?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    blog.author?.name ?? 'Anonymous',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd').format(blog.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF6D5DF6),
              child: Icon(
                _getActivityIcon(activity['type']),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['message'] ?? 'Activity',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(DateTime.parse(activity['timestamp'])),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6D5DF6),
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.bio ?? 'No bio',
          style: GoogleFonts.poppins(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${user.totalBlogs} blogs',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'blog':
        return Icons.article;
      default:
        return Icons.notifications;
    }
  }
} 