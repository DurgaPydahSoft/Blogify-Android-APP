const express = require('express');
const router = express.Router();
const Blog = require('../models/Blog');
const auth = require('../middleware/auth');
const User = require('../models/User');

// Get all blogs with search and filtering
router.get('/', async (req, res) => {
  console.log('GET /blogs - Fetching blogs with filters:', req.query);
  try {
    let query = { isPublished: true };
    
    // Search functionality
    if (req.query.search) {
      query.$or = [
        { title: { $regex: req.query.search, $options: 'i' } },
        { description: { $regex: req.query.search, $options: 'i' } },
        { tags: { $in: [new RegExp(req.query.search, 'i')] } }
      ];
    }
    
    // Category filter
    if (req.query.category) {
      query.categories = { $in: [req.query.category] };
    }
    
    // Tag filter
    if (req.query.tag) {
      query.tags = { $in: [req.query.tag] };
    }
    
    // Sort options
    let sortOption = { createdAt: -1 }; // Default: newest first
    if (req.query.sortBy) {
      switch (req.query.sortBy) {
        case 'popular':
          sortOption = { readCount: -1, likes: -1 };
          break;
        case 'oldest':
          sortOption = { createdAt: 1 };
          break;
        case 'mostLiked':
          sortOption = { 'likes.length': -1 };
          break;
        case 'mostCommented':
          sortOption = { 'comments.length': -1 };
          break;
        default:
          sortOption = { createdAt: -1 };
      }
    }

    const blogs = await Blog.find(query)
      .sort(sortOption)
      .populate('author', 'name email avatarUrl')
      .populate('comments.user', 'name email avatarUrl');
    
    console.log(`Found ${blogs.length} blogs`);
    res.json(blogs);
  } catch (error) {
    console.error('Error fetching blogs:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get categories
router.get('/categories', async (req, res) => {
  try {
    const categories = await Blog.distinct('categories');
    res.json(categories.filter(cat => cat && cat.trim() !== ''));
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get tags
router.get('/tags', async (req, res) => {
  try {
    const tags = await Blog.distinct('tags');
    res.json(tags.filter(tag => tag && tag.trim() !== ''));
  } catch (error) {
    console.error('Error fetching tags:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get blogs from following users
router.get('/following', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.following.length === 0) {
      return res.json([]);
    }

    const blogs = await Blog.find({
      author: { $in: user.following },
      isPublished: true
    })
    .sort({ createdAt: -1 })
    .populate('author', 'name email avatarUrl')
    .populate('comments.user', 'name email avatarUrl');

    res.json(blogs);
  } catch (error) {
    console.error('Error fetching following blogs:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get bookmarked blogs for current user
router.get('/bookmarked', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const bookmarkedBlogs = await Blog.find({
      _id: { $in: user.bookmarks },
      isPublished: true
    }).populate('author', 'name email avatarUrl');

    res.json(bookmarkedBlogs);
  } catch (error) {
    console.error('Error getting bookmarked blogs:', error);
    res.status(500).json({ message: error.message });
  }
});

// Create a new blog (protected)
router.post('/', auth, async (req, res) => {
  console.log('POST /blogs - Creating new blog');
  console.log('Request body:', req.body);
  
  const blog = new Blog({
    title: req.body.title,
    description: req.body.description,
    richContent: req.body.richContent,
    categories: req.body.categories || [],
    tags: req.body.tags || [],
    coverImage: req.body.coverImage,
    isPublished: req.body.isPublished !== undefined ? req.body.isPublished : true,
    createdAt: req.body.createdAt || new Date(),
    author: req.user.userId
  });

  try {
    const newBlog = await blog.save();
    await newBlog.populate('author', 'name email avatarUrl');
    console.log('Blog created successfully:', newBlog);
    res.status(201).json(newBlog);
  } catch (error) {
    console.error('Error creating blog:', error);
    res.status(400).json({ message: error.message });
  }
});

// Get a specific blog
router.get('/:id', async (req, res) => {
  console.log(`GET /blogs/${req.params.id} - Fetching specific blog`);
  try {
    const blog = await Blog.findById(req.params.id)
      .populate('author', 'name email avatarUrl bio')
      .populate('comments.user', 'name email avatarUrl');
    
    if (blog) {
      console.log('Blog found:', blog);
      res.json(blog);
    } else {
      console.log('Blog not found');
      res.status(404).json({ message: 'Blog not found' });
    }
  } catch (error) {
    console.error('Error fetching blog:', error);
    res.status(500).json({ message: error.message });
  }
});

// Increment read count
router.post('/:id/read', async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (blog) {
      blog.readCount += 1;
      await blog.save();
      res.json({ readCount: blog.readCount });
    } else {
      res.status(404).json({ message: 'Blog not found' });
    }
  } catch (error) {
    console.error('Error incrementing read count:', error);
    res.status(500).json({ message: error.message });
  }
});

// Delete a blog (protected)
router.delete('/:id', auth, async (req, res) => {
  console.log(`DELETE /blogs/${req.params.id} - Deleting blog`);
  try {
    const blog = await Blog.findById(req.params.id);
    if (blog) {
      // Only author can delete
      if (blog.author.toString() !== req.user.userId) {
        return res.status(403).json({ message: 'Not authorized' });
      }
      await blog.deleteOne();
      console.log('Blog deleted successfully');
      res.json({ message: 'Blog deleted' });
    } else {
      console.log('Blog not found');
      res.status(404).json({ message: 'Blog not found' });
    }
  } catch (error) {
    console.error('Error deleting blog:', error);
    res.status(500).json({ message: error.message });
  }
});

// Edit a blog (protected)
router.put('/:id', auth, async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) {
      return res.status(404).json({ message: 'Blog not found' });
    }
    // Only author can edit
    if (blog.author.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    blog.title = req.body.title ?? blog.title;
    blog.description = req.body.description ?? blog.description;
    blog.richContent = req.body.richContent ?? blog.richContent;
    blog.categories = req.body.categories ?? blog.categories;
    blog.tags = req.body.tags ?? blog.tags;
    blog.coverImage = req.body.coverImage ?? blog.coverImage;
    blog.isPublished = req.body.isPublished !== undefined ? req.body.isPublished : blog.isPublished;
    blog.updatedAt = new Date();
    
    await blog.save();
    await blog.populate('author', 'name email avatarUrl');
    res.json(blog);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Like a blog
router.post('/:id/like', auth, async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) return res.status(404).json({ message: 'Blog not found' });
    if (!blog.likes.includes(req.user.userId)) {
      blog.likes.push(req.user.userId);
      await blog.save();
    }
    res.json({ likes: blog.likes.length });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Unlike a blog
router.post('/:id/unlike', auth, async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) return res.status(404).json({ message: 'Blog not found' });
    blog.likes = blog.likes.filter(uid => uid.toString() !== req.user.userId);
    await blog.save();
    res.json({ likes: blog.likes.length });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Add a comment
router.post('/:id/comments', auth, async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) return res.status(404).json({ message: 'Blog not found' });
    const comment = {
      user: req.user.userId,
      text: req.body.text,
      createdAt: new Date()
    };
    blog.comments.push(comment);
    await blog.save();
    await blog.populate('comments.user', 'name email avatarUrl');
    res.status(201).json(blog.comments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get comments
router.get('/:id/comments', async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id).populate('comments.user', 'name email avatarUrl');
    if (!blog) return res.status(404).json({ message: 'Blog not found' });
    res.json(blog.comments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Bookmark a blog
router.post('/:id/bookmark', auth, async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) {
      return res.status(404).json({ message: 'Blog not found' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    await user.toggleBookmark(req.params.id);
    res.json({ message: 'Blog bookmarked successfully' });
  } catch (error) {
    console.error('Error bookmarking blog:', error);
    res.status(500).json({ message: error.message });
  }
});

// Unbookmark a blog
router.post('/:id/unbookmark', auth, async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) {
      return res.status(404).json({ message: 'Blog not found' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    await user.toggleBookmark(req.params.id);
    res.json({ message: 'Blog removed from bookmarks' });
  } catch (error) {
    console.error('Error unbookmarking blog:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router; 