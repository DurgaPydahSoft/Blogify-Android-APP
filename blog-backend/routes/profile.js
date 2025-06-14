const express = require('express');
const router = express.Router();
const User = require('../models/User');
const auth = require('../middleware/auth');

// Get user profile
router.get('/:userId', auth, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      bio: user.bio,
      avatarUrl: user.avatarUrl
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update user profile
router.put('/:userId', auth, async (req, res) => {
  try {
    // Check if user is updating their own profile
    if (req.params.userId !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const updates = {
      name: req.body.name,
      bio: req.body.bio,
      avatarUrl: req.body.avatarUrl
    };

    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { $set: updates },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      bio: user.bio,
      avatarUrl: user.avatarUrl
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router; 