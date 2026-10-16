const Child = require('../../models/Child');
const SpeechAssessment = require('../../models/SpeechAssessment');
const VideoAnalysis = require('../../models/VideoAnalysis');
const TherapySession = require('../../models/component3/TherapySession');
const ActivityResult = require('../../models/component3/ActivityResult');

/**
 * Context vector builder for LinUCB (Hybrid, on-device Dart implementation).
 *
 * CRITICAL: The context vector MUST match the Dart implementation in
 * linucb_activity_selector.dart → _LinUcbModel.contextSize = 9.
 *
 * Feature index mapping (MUST remain stable across updates):
 *   [0]  bias term                         always 1.0
 *   [1]  age band 5–10                    1.0 if child age 5–10, else 0.0
 *   [2]  age band 11–14                   1.0 if child age 11–14, else 0.0
 *   [3]  severity mild                    1.0 if C1 severity = Mild, else 0.0
 *   [4]  severity moderate                1.0 if C1 severity = Moderate, else 0.0
 *   [5]  severity severe                  1.0 if C1 severity = Severe, else 0.0
 *   [6]  C2 secondary behaviours present  1.0 if present, 0.0 if absent, 0.5 if unknown
 *   [7]  recent engagement trend          mean engagement over last 3 completed sessions (0–1); 0.5 if unknown
 *   [8]  session count normalised         min(completedSessions / 20, 1.0)
 *
 * Missing-data policy:
 *   - Missing C1 severity: all severity features [3–5] = 0.333... (uniform distribution)
 *     This is NOT interpreted as "no severity" — it signals uncertainty.
 *   - Missing C2: feature [6] = 0.5 (neutral/unknown), NOT 0 (not absent).
 *   - Missing engagement trend: feature [7] = 0.5 (neutral/unknown).
 *   - Missing age: features [1–2] = [0.5, 0.5] (unknown band).
 *
 * IMPORTANT: Missing C1/C2 results must never be encoded as if the child has
 * no severity or no secondary behaviours. This encoding uses the midpoint 0.5
 * or uniform 0.333 to represent genuine uncertainty.
 *
 * @param {string} childId  MongoDB ObjectId string for the child.
 * @param {string} sessionId  String session identifier (e.g. 'sess_…').
 * @returns {{ vector: number[], metadata: object }}  Context vector and provenance info.
 */
const buildContext = async (childId, sessionId) => {
  const CONTEXT_DIM = 9;
  const context = new Array(CONTEXT_DIM).fill(0);
  const metadata = {
    childAge: null,
    ageBand: null,
    c1Severity: null,
    c1Source: null,
    c2SecondaryBehaviours: null,
    c2Source: null,
    recentEngagement: null,
    completedSessions: null,
    missingFields: [],
  };

  // [0] Bias term — always 1.0.
  context[0] = 1.0;

  // --- Load child profile ---
  const child = await Child.findById(childId);
  if (!child) throw new Error(`Child not found: ${childId}`);

  // [1,2] Age band (strict eligibility bands: 5–10 and 11–14).
  const age = child.age;
  metadata.childAge = age;
  if (age >= 5 && age <= 10) {
    context[1] = 1.0;
    context[2] = 0.0;
    metadata.ageBand = '5-10';
  } else if (age >= 11 && age <= 14) {
    context[1] = 0.0;
    context[2] = 1.0;
    metadata.ageBand = '11-14';
  } else {
    // Age outside supported bands or missing — encode uncertainty.
    context[1] = 0.5;
    context[2] = 0.5;
    metadata.ageBand = 'unknown';
    metadata.missingFields.push('ageBand');
  }

  // [3,4,5] C1 severity — prefer latest SpeechAssessment, fall back to child.severity.
  let severity = null;
  const c1Assessment = await SpeechAssessment.findOne({ childId }).sort({ createdAt: -1 }).lean();
  if (c1Assessment && c1Assessment.severity) {
    severity = c1Assessment.severity;
    metadata.c1Severity = severity;
    metadata.c1Source = 'SpeechAssessment';
  } else if (child.severity) {
    severity = child.severity;
    metadata.c1Severity = severity;
    metadata.c1Source = 'child_profile';
  } else {
    metadata.c1Source = null;
    metadata.missingFields.push('c1Severity');
  }

  if (severity === 'Mild') {
    context[3] = 1.0; context[4] = 0.0; context[5] = 0.0;
  } else if (severity === 'Moderate') {
    context[3] = 0.0; context[4] = 1.0; context[5] = 0.0;
  } else if (severity === 'Severe') {
    context[3] = 0.0; context[4] = 0.0; context[5] = 1.0;
  } else {
    // Severity unknown — uniform encoding to represent uncertainty, not absence.
    context[3] = 1/3; context[4] = 1/3; context[5] = 1/3;
  }

  // [6] C2 secondary behaviours.
  // VideoAnalysis stores results as a nested object. We check the 'results' field.
  // Bug fix: original code checked results.hasSecondaryBehaviors which does not exist.
  // The actual field path in the C2 analysis is results.behavior.hasSecondaryBehaviors
  // or a top-level summary flag. We check both with safe fallback.
  const c2Assessment = await VideoAnalysis.findOne({ childId }).sort({ createdAt: -1 }).lean();
  if (c2Assessment) {
    const results = c2Assessment.results || c2Assessment.analysis || {};
    const hasSecondary =
      results.hasSecondaryBehaviors ??
      results.behavior?.hasSecondaryBehaviors ??
      results.summary?.hasSecondaryBehaviors ??
      null;

    if (hasSecondary === true) {
      context[6] = 1.0;
      metadata.c2SecondaryBehaviours = true;
    } else if (hasSecondary === false) {
      context[6] = 0.0;
      metadata.c2SecondaryBehaviours = false;
    } else {
      // Field exists but result indeterminate — encode as unknown.
      context[6] = 0.5;
      metadata.c2SecondaryBehaviours = null;
      metadata.missingFields.push('c2SecondaryBehaviours');
    }
    metadata.c2Source = 'VideoAnalysis';
  } else {
    // No C2 assessment — encode as unknown, NOT as absent.
    context[6] = 0.5;
    metadata.c2Source = null;
    metadata.missingFields.push('c2Assessment');
  }

  // [7] Recent engagement trend — mean engagementScore over last 3 completed sessions.
  try {
    const recentSessions = await TherapySession
      .find({ childId, status: 'Completed' })
      .sort({ endTime: -1 })
      .limit(3)
      .select('_id')
      .lean();

    if (recentSessions.length > 0) {
      const sessionIds = recentSessions.map(s => s._id);
      const recentResults = await ActivityResult
        .find({ sessionId: { $in: sessionIds }, engagementScore: { $ne: null } })
        .select('engagementScore')
        .lean();

      if (recentResults.length > 0) {
        const meanEngagement =
          recentResults.reduce((sum, r) => sum + r.engagementScore, 0) / recentResults.length;
        context[7] = Math.max(0, Math.min(1, meanEngagement));
        metadata.recentEngagement = context[7];
      } else {
        context[7] = 0.5; // No engagement data yet — neutral
        metadata.missingFields.push('recentEngagement');
      }
    } else {
      context[7] = 0.5; // First session — neutral
      metadata.missingFields.push('recentEngagement');
    }
  } catch (err) {
    context[7] = 0.5;
    metadata.missingFields.push('recentEngagement');
  }

  // [8] Number of completed sessions (normalised).
  try {
    const completedSessions = await TherapySession
      .countDocuments({ childId, status: 'Completed' });
    context[8] = Math.min(completedSessions / 20, 1.0);
    metadata.completedSessions = completedSessions;
  } catch (err) {
    context[8] = 0;
    metadata.missingFields.push('sessionCount');
  }

  // Validate dimension.
  if (context.length !== CONTEXT_DIM) {
    throw new Error(
      `Context vector dimension mismatch: expected ${CONTEXT_DIM}, got ${context.length}`
    );
  }

  return { vector: context, metadata };
};

module.exports = { buildContext };
