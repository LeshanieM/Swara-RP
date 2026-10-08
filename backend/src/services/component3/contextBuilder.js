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
    let ageFeature = child.age || 0;

    // C1 severity: prefer latest SpeechAssessment, fall back to child profile severity
    let severityFeature = c1Assessment
      ? getSeverityScore(c1Assessment.severity)
      : getSeverityScore(child.severity);

    // C2 secondary behavior: presence flag from VideoAnalysis results payload
    let secondaryBehaviorFeature =
      c2Assessment && c2Assessment.results && c2Assessment.results.hasSecondaryBehaviors ? 1 : 0;

    // Context vector: [age, severity (1=Mild/2=Mod/3=Severe), secondaryBehavior (0/1)]
    // Dimensions must match context_dim in linucb.py (currently 3)
    const contextVector = [
      ageFeature,
      severityFeature,
      secondaryBehaviorFeature,
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
