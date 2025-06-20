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
const userRoutes = require('./routes/users');

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/blogs', blogRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/users', userRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Open in your browser: http://localhost:${PORT}`);
  console.log(`Accessible on your network at: http://<YOUR-IP-ADDRESS>:${PORT}`);
}); 