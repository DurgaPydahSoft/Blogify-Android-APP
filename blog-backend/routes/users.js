const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Blog = require('../models/Blog');
const auth = require('../middleware/auth');

// Get user dashboard statistics
router.get('/dashboard', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Get user's blogs count
    const blogsCount = await Blog.countDocuments({ author: req.user.userId });
    
    // Get total likes received
    const userBlogs = await Blog.find({ author: req.user.userId });
    const totalLikes = userBlogs.reduce((sum, blog) => sum + blog.likes.length, 0);
    
    // Get total comments received
    const totalComments = userBlogs.reduce((sum, blog) => sum + blog.comments.length, 0);

    res.json({
      totalBlogs: blogsCount,
      totalLikes,
      totalComments,
      followers: user.followers.length,
      following: user.following.length,
      bookmarks: user.bookmarks.length,
      readingHistory: user.readingHistory.length
    });
  } catch (error) {
    console.error('Error getting dashboard stats:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get user's bookmarked blogs
router.get('/bookmarks', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).populate('bookmarks');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const bookmarkedBlogs = await Blog.find({
      _id: { $in: user.bookmarks },
      isPublished: true
    }).populate('author', 'name email avatarUrl');

    res.json(bookmarkedBlogs);
  } catch (error) {
    console.error('Error getting bookmarks:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get user's reading history
router.get('/reading-history', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const blogIds = user.readingHistory.map(item => item.blog);
    const readingHistory = await Blog.find({
      _id: { $in: blogIds },
      isPublished: true
    }).populate('author', 'name email avatarUrl');

    // Sort by reading order
    const sortedHistory = blogIds.map(id => 
      readingHistory.find(blog => blog._id.toString() === id.toString())
    ).filter(Boolean);

    res.json(sortedHistory);
  } catch (error) {
    console.error('Error getting reading history:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get user's activity feed
router.get('/activity-feed', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const activityFeed = [];

    // Get recent blog activities from followed users
    const followedUsers = await User.find({ _id: { $in: user.following } });
    const followedUserIds = followedUsers.map(u => u._id);

    // Recent blogs from followed users
    const recentBlogs = await Blog.find({
      author: { $in: followedUserIds },
      isPublished: true
    })
    .sort({ createdAt: -1 })
    .limit(10)
    .populate('author', 'name');

    recentBlogs.forEach(blog => {
      activityFeed.push({
        type: 'blog',
        message: `${blog.author.name} published a new blog: ${blog.title}`,
        timestamp: blog.createdAt,
        blogId: blog._id,
        userId: blog.author._id
      });
    });

    // Recent likes on user's blogs
    const userBlogs = await Blog.find({ author: req.user.userId });
    for (const blog of userBlogs) {
      if (blog.likes.length > 0) {
        const recentLikes = blog.likes.slice(-5); // Last 5 likes
        for (const likeUserId of recentLikes) {
          const liker = await User.findById(likeUserId);
          if (liker) {
            activityFeed.push({
              type: 'like',
              message: `${liker.name} liked your blog: ${blog.title}`,
              timestamp: new Date(),
              blogId: blog._id,
              userId: liker._id
            });
          }
        }
      }
    }

    // Recent comments on user's blogs
    for (const blog of userBlogs) {
      if (blog.comments.length > 0) {
        const recentComments = blog.comments.slice(-5); // Last 5 comments
        for (const comment of recentComments) {
          const commenter = await User.findById(comment.user);
          if (commenter) {
            activityFeed.push({
              type: 'comment',
              message: `${commenter.name} commented on your blog: ${blog.title}`,
              timestamp: comment.createdAt,
              blogId: blog._id,
              userId: commenter._id
            });
          }
        }
      }
    }

    // Sort by timestamp and limit to 20 activities
    activityFeed.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    res.json(activityFeed.slice(0, 20));
  } catch (error) {
    console.error('Error getting activity feed:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get users that the current user follows
router.get('/following', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).populate('following', 'name email bio avatarUrl totalBlogs');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user.following);
  } catch (error) {
    console.error('Error getting following:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get users following the current user
router.get('/followers', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).populate('followers', 'name email bio avatarUrl totalBlogs');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user.followers);
  } catch (error) {
    console.error('Error getting followers:', error);
    res.status(500).json({ message: error.message });
  }
});

// Follow a user
router.post('/:userId/follow', auth, async (req, res) => {
  try {
    if (req.user.userId === req.params.userId) {
      return res.status(400).json({ message: 'Cannot follow yourself' });
    }

    const userToFollow = await User.findById(req.params.userId);
    if (!userToFollow) {
      return res.status(404).json({ message: 'User to follow not found' });
    }

    const currentUser = await User.findById(req.user.userId);
    if (!currentUser) {
      return res.status(404).json({ message: 'Current user not found' });
    }

    // Add to following
    if (!currentUser.following.includes(req.params.userId)) {
      currentUser.following.push(req.params.userId);
      await currentUser.save();
    }

    // Add to followers
    if (!userToFollow.followers.includes(req.user.userId)) {
      userToFollow.followers.push(req.user.userId);
      await userToFollow.save();
    }

    res.json({ message: 'Successfully followed user' });
  } catch (error) {
    console.error('Error following user:', error);
    res.status(500).json({ message: error.message });
  }
});

// Unfollow a user
router.post('/:userId/unfollow', auth, async (req, res) => {
  try {
    const userToUnfollow = await User.findById(req.params.userId);
    if (!userToUnfollow) {
      return res.status(404).json({ message: 'User to unfollow not found' });
    }

    const currentUser = await User.findById(req.user.userId);
    if (!currentUser) {
      return res.status(404).json({ message: 'Current user not found' });
    }

    // Remove from following
    currentUser.following = currentUser.following.filter(
      id => id.toString() !== req.params.userId
    );
    await currentUser.save();

    // Remove from followers
    userToUnfollow.followers = userToUnfollow.followers.filter(
      id => id.toString() !== req.user.userId
    );
    await userToUnfollow.save();

    res.json({ message: 'Successfully unfollowed user' });
  } catch (error) {
    console.error('Error unfollowing user:', error);
    res.status(500).json({ message: error.message });
  }
});

// Search users
router.get('/search', auth, async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.status(400).json({ message: 'Search query is required' });
    }

    const users = await User.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
        { bio: { $regex: q, $options: 'i' } }
      ],
      _id: { $ne: req.user.userId } // Exclude current user
    })
    .select('name email bio avatarUrl totalBlogs followers')
    .limit(20);

    res.json(users);
  } catch (error) {
    console.error('Error searching users:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router; 
 