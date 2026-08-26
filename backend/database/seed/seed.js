const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('../../src/models/User');
const Child = require('../../src/models/Child');
const TherapyActivity = require('../../src/models/TherapyActivity');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/swara_db';

const seedDatabase = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB for seeding');

    // Clear existing data
    await User.deleteMany({});
    await Child.deleteMany({});
    await TherapyActivity.deleteMany({});
    console.log('🧹 Cleared existing data');

    // Create demo users
    const password = await bcrypt.hash('demo123', 10);
    const parent = await User.create({
      name: 'Demo Parent',
      email: 'parent@demo.com',
      password,
      role: 'parent'
    });

    const therapist = await User.create({
      name: 'Dr. Demo Therapist',
      email: 'therapist@demo.com',
      password,
      role: 'therapist'
    });
    console.log('👤 Created demo users');

    // Create demo children
    const children = await Child.insertMany([
      {
        childId: 'CH-001',
        firstName: 'Amal',
        age: 7,
        gender: 'Male',
        severity: 'Moderate',
        stutterType: 'Repetition',
        supportIndicator: 55,
        communicationScore: 7.5,
        interests: ['Animals', 'Forest'],
        parentId: parent._id,
        therapistId: therapist._id,
        assignedTheme: 'Animal Adventure'
      },
      {
        childId: 'CH-002',
        firstName: 'Nimal',
        age: 9,
        gender: 'Male',
        severity: 'Mild',
        stutterType: 'Prolongation',
        supportIndicator: 80,
        communicationScore: 8.2,
        interests: ['Space', 'Science'],
        parentId: parent._id,
        therapistId: therapist._id,
        assignedTheme: 'Space Explorer'
      },
      {
        childId: 'CH-003',
        firstName: 'Savi',
        age: 6,
        gender: 'Female',
        severity: 'Severe',
        stutterType: 'Block',
        supportIndicator: 42,
        communicationScore: 5.4,
        interests: ['Forest', 'Nature'],
        parentId: parent._id,
        therapistId: therapist._id,
        assignedTheme: 'Forest Friends'
      },
    ]);
    console.log(`🧒 Created ${children.length} demo children`);

    // Create Therapy Activities
    const activities = await TherapyActivity.insertMany([
      {
        activityId: 'ka_001',
        name: 'Slow Speech Practice',
        description: 'Practise speaking slowly and clearly to reduce stuttering episodes.',
        ageRange: [5, 12],
        severity: ['Mild', 'Moderate'],
        stutterTypes: ['Repetition', 'Block'],
        difficulty: 'Beginner',
        duration: 10,
        theme: 'General',
        therapistNotes: 'Reduce speech rate to approximately 120 words per minute.',
      },
      {
        activityId: 'ka_002',
        name: 'Easy Onset Practice',
        description: 'Begin sounds gently without forcing airflow.',
        ageRange: [6, 14],
        severity: ['Moderate', 'Severe'],
        stutterTypes: ['Block', 'Prolongation'],
        difficulty: 'Beginner',
        duration: 8,
        theme: 'General',
        therapistNotes: 'Focus on smooth airflow initiation at sentence start.',
      },
      {
        activityId: 'ka_003',
        name: 'Picture Description',
        description: 'Describe a scene picture using 3-5 sentences.',
        ageRange: [5, 10],
        severity: ['Mild', 'Moderate'],
        stutterTypes: ['Repetition', 'Prolongation', 'Block'],
        difficulty: 'Intermediate',
        duration: 7,
        theme: 'Storytelling',
        therapistNotes: 'Use colourful scene pictures relevant to child interests.',
      }
    ]);
    console.log(`📚 Created ${activities.length} therapy activities`);

    console.log('✅ Seeding completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
  }
};

seedDatabase();
