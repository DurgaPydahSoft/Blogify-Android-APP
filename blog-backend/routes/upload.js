const express = require('express');
const multer = require('multer');
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();
const auth = require('../middleware/auth');

const router = express.Router();

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY,
  secretAccessKey: process.env.AWS_SECRET_KEY,
  region: process.env.AWS_REGION,
});

const storage = multer.memoryStorage();
const upload = multer({ storage });

router.post('/avatar', auth, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }
    const fileExt = req.file.originalname.split('.').pop();
    const key = `avatars/${req.user.userId}_${uuidv4()}.${fileExt}`;
    const params = {
      Bucket: process.env.AWS_S3_BUCKET,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
      ACL: 'public-read',
    };
    const uploadResult = await s3.upload(params).promise();
    res.json({ url: uploadResult.Location });
  } catch (error) {
    console.error('S3 upload error:', error);
    res.status(500).json({ message: 'Failed to upload image', error: error.message });
  }
});

module.exports = router; 