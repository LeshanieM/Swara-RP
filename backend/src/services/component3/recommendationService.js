const { buildContext } = require('./contextBuilder');
const { filterEligibleActivities } = require('./eligibilityService');
const Activity = require('../../models/component3/Activity');
const Child = require('../../models/Child');
const axios = require('axios'); // To communicate with FastAPI LinUCB engine

const PYTHON_API_URL = process.env.C3_PYTHON_API_URL || 'http://localhost:8000';

/**
 * Recommends the next activity for a child in a given session using LinUCB
 */
const recommendNextActivity = async (childId, sessionId) => {
  try {
    // 1. Get Child Profile
    const child = await Child.findById(childId);
    if (!child) throw new Error('Child not found');

    // 2. Build Context
    const contextVector = await buildContext(childId, sessionId);

    // 3. Get all activities and filter eligible ones
    const allActivities = await Activity.find();
    const eligibleActivities = filterEligibleActivities(child, allActivities);
    
    if (eligibleActivities.length === 0) {
      throw new Error('No eligible activities found for this child');
    }

    const eligibleActivityIds = eligibleActivities.map(a => a._id.toString());

    // 4. Call Python LinUCB Engine
    const response = await axios.post(`${PYTHON_API_URL}/recommend`, {
      context: contextVector,
      eligible_activities: eligibleActivityIds
    });

    const selectedActivityId = response.data.selected_activity;
    
    // Find the full activity document
    const selectedActivity = eligibleActivities.find(a => a._id.toString() === selectedActivityId);

    // TODO: Record recommendation information for research logging

    return selectedActivity;
  } catch (error) {
    console.error('Error in recommendationService:', error);
    throw error;
  }
};

module.exports = {
  recommendNextActivity
};
