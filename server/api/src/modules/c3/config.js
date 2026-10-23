// C3 constants. The weights are a stated starting point; the reward ablation (C3_REWARD_MODE) tests whether they matter.
const env = require('../../config/env');

const POLICIES = ['hybrid', 'discounted'];
const REWARD_MODES = ['fused', 'performance', 'engagement', 'tap'];

function pick(value, allowed, name) {
  if (!allowed.includes(value)) throw new Error(`${name} must be one of ${allowed.join(', ')} (got "${value}")`);
  return value;
}

const between = (value, lo, hi, name) => {
  if (!(value >= lo && value <= hi)) throw new Error(`${name} must be between ${lo} and ${hi} (got ${value})`);
  return value;
};

module.exports = Object.freeze({
  policy: pick(env.c3Policy, POLICIES, 'C3_POLICY'),
  alpha: between(env.c3Alpha, 0, 10, 'C3_ALPHA'),
  discountGamma: between(env.c3DiscountGamma, 0.5, 1, 'C3_DISCOUNT_GAMMA'),
  childPrior: between(env.c3ChildPrior, 0.1, 100, 'C3_CHILD_PRIOR'),
  exploreEpsilon: between(env.c3ExploreEpsilon, 0, 1, 'C3_EXPLORE_EPSILON'),
  rewardMode: pick(env.c3RewardMode, REWARD_MODES, 'C3_REWARD_MODE'),
  maxActivitiesPerSession: between(env.c3MaxActivities, 1, 20, 'C3_MAX_ACTIVITIES'),
  POLICIES,
  REWARD_MODES,

  // Per-activity reward r = 0.6 P + 0.4 E.
  rewardWeights: { performance: 0.6, engagement: 0.4 },
  // The app's old three-button tap, kept as the "tap" ablation row.
  tapRewards: { too_hard: 0.2, just_right: 1, too_easy: 0.55 },
  tapRewardWithoutFeedback: 0.5,
  // Session TSS = 100 (0.5 P̄ + 0.3 Ē + 0.2 Q); re-normalised over the parts that exist.
  tssWeights: { performance: 0.5, engagement: 0.3, questionnaire: 0.2 },
  tssTrendMinChange: 5, // TSS points that count as a real change between sessions

  ageBands: [{ id: '5-10', minAge: 5, maxAge: 10 }, { id: '11-14', minAge: 11, maxAge: 14 }],
  defaultPlannedMinutes: 25,
  defaultBreakSec: 120,
  // An unfinished session can be continued for this many hours after it started; after that it is closed as
  // abandoned (time zones make "the same day" ambiguous between phone and server, so a window is used).
  resumeHours: 12,

  // Within-session adaptation: engagement below this, over at least this many activities and minutes, triggers advice.
  lowEngagement: { threshold: 0.4, minActivities: 2, minMinutes: 6 },

  // Context history windows.
  history: { parentHelpAttempts: 5, engagementSessions: 3, typeAttempts: 3, sessionsForFullExperience: 20 },
  neutralPrior: 0.5, // engagement trend and type score before any history
});
