const express = require('express');
const router = express.Router();
const Blog = require('../models/Blog');
const auth = require('../middleware/auth');

// Get all blogs
router.get('/', async (req, res) => {
  console.log('GET /blogs - Fetching all blogs');
  try {
    const blogs = await Blog.find()
      .sort({ createdAt: -1 })
      .populate('author', 'name email')
      .populate('comments.user', 'name email');
    console.log(`Found ${blogs.length} blogs`);
    res.json(blogs);
  } catch (error) {
    console.error('Error fetching blogs:', error);
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
    createdAt: req.body.createdAt || new Date(),
    author: req.user.userId
  });

  try {
    const newBlog = await blog.save();
    await newBlog.populate('author', 'name email');
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
    const blog = await Blog.findById(req.params.id).populate('author', 'name email');
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
    await blog.save();
    await blog.populate('author', 'name email');
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
    await blog.populate('comments.user', 'name email');
    res.status(201).json(blog.comments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get comments
router.get('/:id/comments', async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id).populate('comments.user', 'name email');
    if (!blog) return res.status(404).json({ message: 'Blog not found' });
    res.json(blog.comments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router; 