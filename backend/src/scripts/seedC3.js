require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const Child = require('../models/Child');
const Activity = require('../models/component3/Activity');
const TherapyPlan = require('../models/component3/TherapyPlan');
const { CORE_ACTIVITIES } = require('../controllers/component3/activityController');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/swara_db';

const seedDB = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB for Seeding...');

    // 1. Seed the 5 Core Activities for both age bands
    const ageBands = ['5-10', '11-14'];
    const seededActivities = [];

    for (const band of ageBands) {
      for (const act of CORE_ACTIVITIES) {
        const doc = {
          ...act,
          activityId: `${act.activityId}_${band.replace('-', '_')}`,
          ageBand: band,
        };
        const updated = await Activity.findOneAndUpdate(
          { activityId: doc.activityId },
          doc,
          { upsert: true, new: true, setDefaultsOnInsert: true }
        );
        seededActivities.push(updated);
      }
    }
    console.log(`✅ Seeded ${seededActivities.length} activities (5 core × 2 age bands)`);

    // 2. Create or update Mock Child
    let mockChild = await Child.findOne({ childId: 'MOCK_CHILD_001' });
    if (!mockChild) {
      mockChild = new Child({
        childId: 'MOCK_CHILD_001',
        firstName: 'Amal',
        age: 7,
        dateOfBirth: new Date('2017-04-15'),
        severity: 'Mild',
        stutterType: 'Repetition',
        interests: ['animals', 'drawing'],
        assignedTheme: 'Forest Adventure',
      });
      await mockChild.save();
    }
    console.log(`✅ Mock Child ID: ${mockChild._id}`);

    // 3. Create or update Mock Therapy Plan
    const actIds = seededActivities.filter(a => a.ageBand === '5-10').map(a => a._id);
    let plan = await TherapyPlan.findOne({ planId: 'PLAN_001' });
    if (!plan) {
      plan = new TherapyPlan({
        planId: 'PLAN_001',
        therapeuticGoal: 'Fluency and Easy Onset Mastery',
        activities: actIds,
        active: true,
      });
      await plan.save();
    }
    console.log(`✅ Mock Therapy Plan ID: ${plan._id}`);

    console.log('\n=======================================');
    console.log('🎉 C3 Seeding Complete!');
    console.log(`Child ID: ${mockChild._id}`);
    console.log(`Plan ID: ${plan._id}`);
    console.log(`Core Activities Seeded: 5 activities in 2 age bands (10 total)`);
    console.log('=======================================\n');

    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
  }
};

seedDB();
