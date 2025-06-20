const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  password: {
    type: String,
    required: true
  },
  bio: {
    type: String,
    default: ''
  },
  avatarUrl: {
    type: String,
    default: null
  },
  following: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  followers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  bookmarks: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Blog'
  }],
  readingHistory: [{
    blog: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Blog'
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }],
  totalBlogs: {
    type: Number,
    default: 0
  },
  totalLikes: {
    type: Number,
    default: 0
  },
  totalComments: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  lastActive: {
    type: Date,
    default: Date.now
  }
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Update last active timestamp
userSchema.methods.updateLastActive = function() {
  this.lastActive = new Date();
  return this.save();
};

// Add to reading history
userSchema.methods.addToReadingHistory = function(blogId) {
  // Remove if already exists
  this.readingHistory = this.readingHistory.filter(
    item => item.blog.toString() !== blogId.toString()
  );
  
  // Add to beginning
  this.readingHistory.unshift({
    blog: blogId,
    readAt: new Date()
  });
  
  // Keep only last 50 entries
  if (this.readingHistory.length > 50) {
    this.readingHistory = this.readingHistory.slice(0, 50);
  }
  
  return this.save();
};

// Toggle bookmark
userSchema.methods.toggleBookmark = function(blogId) {
  const index = this.bookmarks.indexOf(blogId);
  if (index > -1) {
    this.bookmarks.splice(index, 1);
  } else {
    this.bookmarks.push(blogId);
  }
  return this.save();
};

// Toggle follow
userSchema.methods.toggleFollow = function(userId) {
  const index = this.following.indexOf(userId);
  if (index > -1) {
    this.following.splice(index, 1);
  } else {
    this.following.push(userId);
  }
  return this.save();
};

module.exports = mongoose.model('User', userSchema); 