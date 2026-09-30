require('dotenv').config({ path: '../../.env' });
const mongoose = require('mongoose');
const Child = require('../models/Child');
const Activity = require('../models/component3/Activity');
const TherapyPlan = require('../models/component3/TherapyPlan');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/swara_db';

const seedDB = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB for Seeding...');

    // 1. Create a Mock Child
    const mockChild = new Child({
      childId: 'MOCK_CHILD_001',
      firstName: 'Amal',
      age: 7,
      dateOfBirth: new Date('2017-04-15'),
      severity: 'Mild',
      stutterType: 'Repetition',
      interests: ['animals', 'drawing'],
      assignedTheme: 'Forest Adventure'
    });
    await mockChild.save();
    console.log(`✅ Created Mock Child with ID: ${mockChild._id}`);

    // 2. Create Mock Activities
    const activities = [
      {
        activityId: 'act_001',
        name: 'Syllable Practice',
        technique: 'Pausing/Phrasing',
        activityType: 'syllable_practice',
        difficulty: 1,
        active: true,
        ageRange: [4, 12]
      },
      {
        activityId: 'act_002',
        name: 'Reading',
        technique: 'Prolonged Speech',
        activityType: 'reading',
        difficulty: 2,
        active: true,
        ageRange: [6, 12]
      },
      {
        activityId: 'act_003',
        name: 'Picture Description',
        technique: 'Easy Onset',
        activityType: 'picture_description',
        difficulty: 2,
        active: true,
        ageRange: [4, 10]
      },
      {
        activityId: 'act_004',
        name: 'Guided Conversation',
        technique: 'Pausing/Phrasing',
        activityType: 'guided_conversation',
        difficulty: 3,
        active: true,
        ageRange: [6, 12]
      }
    ];

    const insertedActivities = await Activity.insertMany(activities);
    console.log(`✅ Created ${insertedActivities.length} Mock Activities`);

    // 3. Create a Mock Therapy Plan
    const plan = new TherapyPlan({
      planId: 'PLAN_001',
      therapeuticGoal: 'Pausing and Phrasing',
      activities: insertedActivities.map(a => a._id),
      active: true
    });
    await plan.save();
    console.log(`✅ Created Mock Therapy Plan with ID: ${plan._id}`);

    console.log('\n=======================================');
    console.log('🎉 Seeding Complete! Please use these IDs to test:');
    console.log(`Child ID: ${mockChild._id}`);
    console.log(`Plan ID: ${plan._id}`);
    console.log(`Activity 1 ID (Syllable): ${insertedActivities[0]._id}`);
    console.log(`Activity 2 ID (Reading): ${insertedActivities[1]._id}`);
    console.log('=======================================\n');

    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
  }
};

seedDB();
