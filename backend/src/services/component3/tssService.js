const ActivityResult = require('../../models/component3/ActivityResult');
const TherapyOutcome = require('../../models/component3/TherapyOutcome');
const TherapySession = require('../../models/component3/TherapySession');
// const { updateLinUCB } = require('./linucbService'); // Assuming python microservice or local service

/**
 * Calculates the cumulative TSS for a completed therapy plan session.
 * @param {String} sessionId 
 * @returns {Object} { tss, reward }
 */
const calculatePlanTSS = async (sessionId) => {
  const session = await TherapySession.findById(sessionId);
  if (!session) throw new Error('Session not found');

  const results = await ActivityResult.find({ sessionId });
  if (results.length === 0) return { tss: 0, reward: 0 };

  let totalSuccessful = 0;
  let totalTarget = 0;

  for (const res of results) {
    if (res.attempted && res.targetOpportunities > 0) {
      totalSuccessful += res.successfulOpportunities;
      totalTarget += res.targetOpportunities;
    }
  }

  let tss = 0;
  if (totalTarget > 0) {
    tss = (totalSuccessful / totalTarget) * 100;
  }

  const reward = tss / 100; // Normalized reward for LinUCB

  // Save the outcome
  const outcome = new TherapyOutcome({
    sessionId: session._id,
    childId: session.childId,
    planId: session.planId,
    TSS: tss,
    normalizedReward: reward
  });
  await outcome.save();

  // Trigger LinUCB model update logic here based on reward
  // await updateLinUCB(session, context, reward);

  return { tss, reward };
};

module.exports = {
  calculatePlanTSS
};
