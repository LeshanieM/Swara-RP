/**
 * Activity eligibility filter for the C3 recommender.
 *
 * Rules (all must pass for an activity to be eligible):
 *   1. active === true
 *   2. slpApproved === true
 *   3. ageBand matches the child's age (strict)
 *   4. Activity type is NOT 'open_topic_talk' (A12 — belongs to Component 4)
 *   5. Excluded from recently-used IDs where alternatives exist
 *
 * Age-band mapping:
 *   5–10  → ageBand = '5-10'
 *   11–14 → ageBand = '11-14'
 *   Outside range → no activities eligible (returns empty array with reason)
 *
 * @param {object} child    Mongoose Child document
 * @param {Array}  allActivities  Array of Activity documents from DB
 * @param {object} [options]
 * @param {string[]} [options.recentlyUsedIds]  linucbActionIds used in current session
 * @param {number}   [options.recentWindowSize] Number of recent IDs to avoid (default 3)
 * @returns {{ eligible: Array, excluded: Array, reason: string|null }}
 */
const filterEligibleActivities = (child, allActivities, options = {}) => {
  const { recentlyUsedIds = [], recentWindowSize = 3 } = options;
  const age = child.age;

  // Determine age band.
  let requiredBand = null;
  if (age >= 5 && age <= 10)  requiredBand = '5-10';
  else if (age >= 11 && age <= 14) requiredBand = '11-14';

  const excluded = [];
  const eligible = allActivities.filter(activity => {
    // Rule 1: must be active.
    if (!activity.active) {
      excluded.push({ id: activity.activityId, reason: 'inactive' });
      return false;
    }

    // Rule 2: must be SLP-approved.
    if (!activity.slpApproved) {
      excluded.push({ id: activity.activityId, reason: 'not_slp_approved' });
      return false;
    }

    // Rule 3: age band must match (strict eligibility filter).
    if (!requiredBand) {
      excluded.push({ id: activity.activityId, reason: 'age_outside_supported_range' });
      return false;
    }
    if (activity.ageBand !== requiredBand) {
      excluded.push({ id: activity.activityId, reason: 'age_band_mismatch' });
      return false;
    }

    // Rule 4: exclude A12 (Open Topic Talk — Component 4 responsibility).
    if (activity.activityType === 'open_topic_talk') {
      excluded.push({ id: activity.activityId, reason: 'a12_reserved_for_c4' });
      return false;
    }

    return true;
  });

  if (eligible.length === 0) {
    const reason = requiredBand
      ? 'no_eligible_activities_for_age_band'
      : 'child_age_outside_supported_range';
    return { eligible: [], excluded, reason };
  }

  // Rule 5: avoid recently-used activities where alternatives exist.
  const recentWindow = recentlyUsedIds.slice(-recentWindowSize);
  if (recentWindow.length > 0) {
    const withoutRecent = eligible.filter(a => !recentWindow.includes(a.linucbActionId));
    if (withoutRecent.length > 0) {
      return { eligible: withoutRecent, excluded, reason: null };
    }
    // All eligible activities are in the recent window — allow repetition rather than failure.
  }

  return { eligible, excluded, reason: null };
};

module.exports = { filterEligibleActivities };
