const Child = require('../../models/Child');
const SpeechAssessment = require('../../models/SpeechAssessment');
const VideoAnalysis = require('../../models/VideoAnalysis');

/**
 * Builds the context vector for LinUCB based on the child's profile, C1 outputs, C2 outputs, and history.
 * @param {String} childId 
 * @param {String} sessionId 
 * @returns {Array<Number>} context vector
 */
const buildContext = async (childId, sessionId) => {
  try {
    const child = await Child.findById(childId);
    if (!child) throw new Error('Child not found');

    // Retrieve latest C1 (Speech) assessment
    const c1Assessment = await SpeechAssessment.findOne({ childId }).sort({ createdAt: -1 });

    // Retrieve latest C2 (Video) assessment
    const c2Assessment = await VideoAnalysis.findOne({ childId }).sort({ createdAt: -1 });

    // Initialize context features
    let ageFeature = child.age || 0; // Or calculate from dob
    let severityFeature = c1Assessment ? getSeverityScore(c1Assessment.severity) : 0;
    let secondaryBehaviorFeature = c2Assessment && c2Assessment.hasSecondaryBehaviors ? 1 : 0;

    // Additional features could include previous history performance 
    // (e.g., average TSS over last 5 sessions)
    // For now, let's keep it simple: [age, severity, secondaryBehavior]

    const contextVector = [
      ageFeature,
      severityFeature,
      secondaryBehaviorFeature,
      // Add more dynamic fields here as needed
    ];

    return contextVector;
  } catch (error) {
    console.error('Error building context:', error);
    throw error;
  }
};

const getSeverityScore = (severityStr) => {
  const map = { 'Mild': 1, 'Moderate': 2, 'Severe': 3 };
  return map[severityStr] || 0;
};

module.exports = {
  buildContext
};
