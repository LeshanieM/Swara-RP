require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes = require('./routes/auth');
const childRoutes = require('./routes/children');
const speechRoutes = require('./routes/speech');
const psychologyRoutes = require('./routes/psychology');
const therapyRoutes = require('./routes/therapy');
const communicationRoutes = require('./routes/communication');
const progressRoutes = require('./routes/progress');
const therapistRoutes = require('./routes/therapist');
const concomitantRoutes = require('./routes/concomitant');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/children', childRoutes);
app.use('/api/speech', speechRoutes);
app.use('/api/psychology', psychologyRoutes);
app.use('/api/therapy', therapyRoutes);
app.use('/api/communication', communicationRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/therapist', therapistRoutes);
app.use('/api/concomitant', concomitantRoutes);

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'swara-backend', version: '1.0.0' }));

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Internal server error', error: process.env.NODE_ENV === 'development' ? err.message : undefined });
});

// Connect to MongoDB
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/swara_db';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('✅ MongoDB connected');
    app.listen(PORT, () => console.log(`🚀 Swara Backend running on port ${PORT}`));
  })
  .catch(err => {
    console.error('❌ MongoDB connection failed:', err.message);
    console.log('ℹ️  Starting without MongoDB (some features will be unavailable)');
    app.listen(PORT, () => console.log(`🚀 Swara Backend running on port ${PORT} (no DB)`));
  });

module.exports = app;
