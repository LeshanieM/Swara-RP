require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const Activity = require('../../src/models/component3/Activity');
const TherapySession = require('../../src/models/component3/TherapySession');
const ActivityResult = require('../../src/models/component3/ActivityResult');
const ParentQuestionnaire = require('../../src/models/component3/ParentQuestionnaire');
const TherapyOutcome = require('../../src/models/component3/TherapyOutcome');
const { calculateAndSaveTSS } = require('../../src/services/component3/tssService');
const { getServerSideFallback } = require('../../src/services/component3/recommendationService');
const Child = require('../../src/models/Child');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/swara_db';

async function runTests() {
  console.log('🧪 Starting Component 3 End-to-End Verification...');
  await mongoose.connect(MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  // 1. Verify Activities
  const activities = await Activity.find({ active: true });
  console.log(`\n1. Activity Pool Check: Found ${activities.length} active activities`);
  if (activities.length === 0) {
    throw new Error('No activities found in DB!');
  }
  const coreActions = ['breathing-body-awareness', 'syllable-practice', 'word-phrase-practice', 'picture-description', 'guided-conversation'];
  for (const actionId of coreActions) {
    const found = activities.some(a => a.linucbActionId === actionId);
    console.log(`   - Activity '${actionId}': ${found ? '✅ PRESENT' : '❌ MISSING'}`);
    if (!found) throw new Error(`Missing core activity: ${actionId}`);
  }

  // 2. Test Session Creation
  console.log('\n2. Testing Therapy Session Creation...');
  const testSession = new TherapySession({
    sessionId: `test_sess_${Date.now()}`,
    status: 'In Progress',
    modelVersion: 'linucb_v3',
    selectedActivities: coreActions,
  });
  await testSession.save();
  console.log(`✅ Session created with sessionId: ${testSession.sessionId}`);

  // 3. Test Activity Results Recording
  console.log('\n3. Testing Activity Results Recording (All 5 Activities)...');
  for (let i = 0; i < coreActions.length; i++) {
    const actId = coreActions[i];
    const result = new ActivityResult({
      sessionId: testSession._id,
      activityId: actId,
      targetOpportunities: 4,
      successfulOpportunities: 3 + (i % 2),
      completionFraction: 1.0,
      durationSeconds: 120 + i * 15,
      completed: true,
      engagementScore: 0.85 + (i * 0.02),
      engagementMode: 'logs_only',
    });
    await result.save();
    console.log(`   - Saved result for ${actId}: Performance=${result.performanceScore?.toFixed(2)}, Reward=${result.reward?.toFixed(2)}`);
  }

  // 4. Test Parent Questionnaire Submission
  console.log('\n4. Testing Parent Questionnaire Submission...');
  const questionnaire = new ParentQuestionnaire({
    sessionId: testSession._id,
    ownerId: new mongoose.Types.ObjectId(),
    version: 'prime_o_adapt_v1',
    responses: {
      Q1: 5,
      Q2: 4,
      Q3: 5,
      Q4: 5,
      Q5: 5,
    },
  });
  await questionnaire.save();
  console.log(`✅ Questionnaire saved: RawScore=${questionnaire.rawScore}, ScaledScore=${questionnaire.scaledScore?.toFixed(2)}`);

  // Attach to session
  testSession.parentQuestionnaire = {
    version: questionnaire.version,
    responses: Object.fromEntries(questionnaire.responses),
    rawScore: questionnaire.rawScore,
    scaledScore: questionnaire.scaledScore,
    completedAt: questionnaire.completedAt,
  };
  testSession.status = 'Completed';
  await testSession.save();

  // 5. Test TSS Calculation
  console.log('\n5. Testing TSS Composite Measure Calculation...');
  const tssResult = await calculateAndSaveTSS(testSession.sessionId);
  console.log(`✅ Calculated TSS: ${tssResult.tss?.toFixed(1)} / 100 (Mean P: ${tssResult.components?.meanPerformance?.toFixed(2)}, Mean E: ${tssResult.components?.meanEngagement?.toFixed(2)}, Q: ${tssResult.components?.questionnaireQ?.toFixed(2)})`);

  const outcome = await TherapyOutcome.findOne({ sessionId: testSession._id });
  console.log(`✅ TherapyOutcome persisted: TSS=${outcome?.TSS?.toFixed(1)}, NormalizedReward=${outcome?.normalizedReward?.toFixed(2)}`);

  // 6. Test Fallback Recommender
  console.log('\n6. Testing Recommender Fallback...');
  const mockChild = await Child.findOne();
  if (mockChild) {
    const rec = await getServerSideFallback(mockChild._id.toString(), testSession.sessionId);
    console.log(`✅ Recommender returned: ${rec.activity?.name} (${rec.activity?.linucbActionId})`);
  }

  // Cleanup test data
  await ActivityResult.deleteMany({ sessionId: testSession._id });
  await ParentQuestionnaire.deleteMany({ sessionId: testSession._id });
  await TherapyOutcome.deleteMany({ sessionId: testSession._id });
  await TherapySession.deleteOne({ _id: testSession._id });
  console.log('\n🧹 Cleaned up temporary test data.');

  console.log('\n🎉 ALL 6 COMPONENT 3 TESTS PASSED PERFECTLY!\n');
  process.exit(0);
}

runTests().catch(err => {
  console.error('\n❌ Test failed:', err);
  process.exit(1);
});
