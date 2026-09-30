/**
 * Filters the activity pool to return only activities suitable for the child's basic constraints.
 * @param {Object} child Profile
 * @param {Array} allActivities 
 * @returns {Array} eligible activities
 */
const filterEligibleActivities = (child, allActivities) => {
  const age = child.age || 0;

  return allActivities.filter(activity => {
    // 1. Must be active
    if (!activity.active) return false;

    // 2. Age compatibility
    if (activity.ageRange && activity.ageRange.length === 2) {
      if (age < activity.ageRange[0] || age > activity.ageRange[1]) {
        return false;
      }
    }

    // Additional constraints like difficulty compatibility based on child's current level
    // can be added here.

    return true;
  });
};

module.exports = {
  filterEligibleActivities
};
