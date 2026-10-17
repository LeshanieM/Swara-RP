const { buildContext } = require('./contextBuilder');
const { filterEligibleActivities } = require('./eligibilityService');
const Activity = require('../../models/component3/Activity');
const ActivityResult = require('../../models/component3/ActivityResult');
const Child = require('../../models/Child');
const TherapySession = require('../../models/component3/TherapySession');

/**
 * Server-side recommendation service for C3.
 *
 * Architecture note:
 * The primary LinUCB recommender runs on-device in Dart (linucb_activity_selector.dart).
 * This service provides:
 *   1. Context vector construction for research logging.
 *   2. A server-side fallback recommendation (random eligible selection) used when
 *      the Dart engine cannot run (e.g. new install, model corruption).
 *   3. Engagement estimation (logs-only mode) for backend-side reward computation.
 *   4. Eligibility validation before the Dart engine selects.
 *
 * The broken Python FastAPI call (original recommendationService.js) has been removed.
 * Python is retained for offline training, simulation and evaluation only.
 */

// ============================================================================
// Logs-only engagement estimator
// ============================================================================
/**
 * Estimates engagement from activity-log signals (Mode B: no camera).
 *
 * This is a transparent, weighted score — NOT a trained or validated model.
 * It will be replaced by a trained logistic regression model if labelled
 * pilot data becomes available.
 *
 * Weights (initial research design — not clinically validated):
 *   completionFraction   : 0.40  (primary signal: did the child finish?)
 *   attemptRate          : 0.25  (attempts / opportunities — indicates willingness)
 *   skipPenalty          : 0.20  (skipped = lower engagement)
 *   parentHelpInverse    : 0.15  (high help level may indicate difficulty, not disengagement)
 *
 * Output range: 0.0–1.0.
 * Returns null if insufficient data to estimate.
 *
 * IMPORTANT: A low engagement score must NOT automatically stop the session or
 * be interpreted as distress. It is a proxy signal only.
 *
 * @param {object} params
 * @param {number|null} params.completionFraction  0–1; null if unavailable
 * @param {number|null} params.targetOpportunities
 * @param {number|null} params.successfulOpportunities
 * @param {boolean}     params.skipped
 * @param {number|null} params.parentHelpLevel  0–3; null if unavailable
 * @returns {number|null}
 */
const estimateEngagementLogsOnly = ({
  completionFraction,
  targetOpportunities,
  successfulOpportunities,
  skipped,
  parentHelpLevel,
}) => {
  // If the activity was skipped and we have no other info, return a low estimate.
  if (skipped && completionFraction == null) return 0.2;

  const components = [];

  // Completion fraction (weight 0.40).
  if (completionFraction != null) {
    components.push({ w: 0.40, v: Math.max(0, Math.min(1, completionFraction)) });
  }

  // Attempt rate (weight 0.25): successful / total opportunities.
  if (targetOpportunities != null && targetOpportunities > 0 && successfulOpportunities != null) {
    const attemptRate = Math.max(0, Math.min(1, successfulOpportunities / targetOpportunities));
    components.push({ w: 0.25, v: attemptRate });
  }

  // Skip penalty (weight 0.20): 1.0 if not skipped, 0.0 if skipped.
  components.push({ w: 0.20, v: skipped ? 0.0 : 1.0 });

  // Parent help (weight 0.15): high help → lower engagement estimate.
  // 0 = no help (1.0), 3 = significant (0.25).
  if (parentHelpLevel != null) {
    const helpSignal = Math.max(0, Math.min(1, 1.0 - (parentHelpLevel / 3) * 0.75));
    components.push({ w: 0.15, v: helpSignal });
  }

  if (components.length === 0) return null;

  // Renormalise weights over available components.
  const wSum = components.reduce((s, c) => s + c.w, 0);
  const score = components.reduce((s, c) => s + (c.w / wSum) * c.v, 0);
  return Math.max(0, Math.min(1, score));
};

// ============================================================================
// Within-session recommendation (fallback — random eligible selection)
// ============================================================================
/**
 * Server-side fallback: selects a random eligible activity when the Dart
 * engine cannot produce a recommendation.
 *
 * This is NOT the primary recommender. The Dart LinUCB in
 * linucb_activity_selector.dart is the authoritative selector.
 *
 * @param {string} childId
 * @param {string} sessionId  String session ID (e.g. 'sess_...')
 * @param {string[]} [recentlyUsedIds]
 * @returns {{ activity: object|null, context: object, reason: string }}
 */
const getServerSideFallback = async (childId, sessionId, recentlyUsedIds = []) => {
  const child = await Child.findById(childId);
  if (!child) throw new Error(`Child not found: ${childId}`);

  const allActivities = await Activity.find({ active: true });
  const { eligible, reason } = filterEligibleActivities(child, allActivities, {
    recentlyUsedIds,
  });

  if (eligible.length === 0) {
    return {
      activity: null,
      context: { vector: null, metadata: {} },
      reason: reason || 'no_eligible_activities',
    };
  }

  const { vector, metadata } = await buildContext(childId, sessionId).catch(() => ({
    vector: null,
    metadata: { missingFields: ['all'] },
  }));

  // Random selection as fallback.
  const selected = eligible[Math.floor(Math.random() * eligible.length)];

  return {
    activity: selected,
    context: { vector, metadata },
    reason: 'server_fallback_random',
  };
};

// ============================================================================
// Get eligible activities for the Dart engine
// ============================================================================
/**
 * Returns the list of eligible activities and the context vector for the
 * Dart LinUCB engine to use.
 *
 * @param {string} childId
 * @param {string} sessionId
 * @param {string[]} [recentlyUsedIds]
 * @returns {{ eligible: Array, context: object, reason: string|null }}
 */
const getEligibleActivitiesWithContext = async (childId, sessionId, recentlyUsedIds = []) => {
  const child = await Child.findById(childId);
  if (!child) throw new Error(`Child not found: ${childId}`);

  const allActivities = await Activity.find({ active: true });
  const { eligible, excluded, reason } = filterEligibleActivities(child, allActivities, {
    recentlyUsedIds,
  });

  const { vector, metadata } = await buildContext(childId, sessionId);

  return { eligible, excluded, context: { vector, metadata }, reason };
};

// ============================================================================
// Record engagement estimate for an activity result
// ============================================================================
/**
 * Computes and saves an engagement estimate for an existing ActivityResult.
 * Used after an activity completes when camera mode is not available.
 *
 * @param {string} activityResultId  MongoDB ObjectId string
 * @returns {object} Updated ActivityResult
 */
const addLogsOnlyEngagement = async (activityResultId) => {
  const result = await ActivityResult.findById(activityResultId);
  if (!result) throw new Error(`ActivityResult not found: ${activityResultId}`);

  if (result.engagementMode !== 'unavailable') {
    // Already has an engagement estimate — do not overwrite.
    return result;
  }

  const engagement = estimateEngagementLogsOnly({
    completionFraction: result.completionFraction,
    targetOpportunities: result.targetOpportunities,
    successfulOpportunities: result.successfulOpportunities,
    skipped: result.skipped,
    parentHelpLevel: result.parentHelpLevel,
  });

  result.engagementScore = engagement;
  result.engagementMode = engagement !== null ? 'logs_only' : 'unavailable';
  await result.save(); // triggers reward recalculation in pre-save hook

  return result;
};

// ============================================================================
// Primary Recommendation Service Wrapper
// ============================================================================
const recommendNextActivity = async (childId, sessionId, recentlyUsedIds = []) => {
  return await getServerSideFallback(childId, sessionId, recentlyUsedIds);
};

module.exports = {
  getEligibleActivitiesWithContext,
  getServerSideFallback,
  recommendNextActivity,
  estimateEngagementLogsOnly,
  addLogsOnlyEngagement,
};
