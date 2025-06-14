const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const { ApiConfig } = require('./config');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
mongoose.connect(ApiConfig.mongoConnectionString)
  .then(() => console.log('Connected to MongoDB'))
  .catch((err) => console.error('MongoDB connection error:', err));

// Import routes
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const blogRoutes = require('./routes/blogs');
const uploadRoutes = require('./routes/upload');

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/blogs', blogRoutes);
app.use('/api/upload', uploadRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Listen on all network interfaces

app.listen(PORT, HOST, () => {
  console.log(`Server is running on http://${HOST}:${PORT}`);
  console.log('Local: http://localhost:3000');
  console.log('Network: http://192.168.128.93:3000');
}); 