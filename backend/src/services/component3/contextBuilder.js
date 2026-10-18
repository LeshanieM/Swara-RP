const Child = require('../../models/Child');
const SpeechAssessment = require('../../models/SpeechAssessment');
const VideoAnalysis = require('../../models/VideoAnalysis');
const TherapySession = require('../../models/component3/TherapySession');
const ActivityResult = require('../../models/component3/ActivityResult');

/**
 * Context vector builder for LinUCB (Hybrid, on-device Dart implementation).
 *
 * Feature index mapping (MUST remain stable across Dart and Node):
 *   [0]  bias term                         always 1.0
 *   [1]  age band 5–10                    1.0 if child age 5–10, else 0.0
 *   [2]  age band 11–14                   1.0 if child age 11–14, else 0.0
 *   [3]  severity mild                    1.0 if C1 severity = Mild, else 0.0
 *   [4]  severity moderate                1.0 if C1 severity = Moderate, else 0.0
 *   [5]  severity severe                  1.0 if C1 severity = Severe, else 0.0
 *   [6]  C2 secondary behaviours present  1.0 if present, 0.0 if absent, 0.5 if unknown
 *   [7]  camera active flag               1.0 if camera active, 0.0 if logs-only
 *   [8]  recent engagement trend          mean engagement over last 3 completed sessions (0–1); 0.5 if unknown
 *   [9]  recent performance for type      mean performance/TSS for this activity type (0–1); 0.5 if unknown
 *   [10] session count normalised         min(completedSessions / 20, 1.0)
 *   [11] parent help level                0.0 (none) to 1.0 (full assistance)
 *
 * @param {string} childId  MongoDB ObjectId string for the child.
 * @param {string} sessionId  String session identifier (e.g. 'sess_…').
 * @param {object} [options]
 * @param {boolean} [options.cameraOn]
 * @param {string} [options.activityType]
 * @param {number} [options.parentHelpLevel]
 * @returns {{ vector: number[], metadata: object }} Context vector and provenance info.
 */
const buildContext = async (childId, sessionId, options = {}) => {
  const CONTEXT_DIM = 12;
  const context = new Array(CONTEXT_DIM).fill(0);
  const metadata = {
    childAge: null,
    ageBand: null,
    c1Severity: null,
    c1Source: null,
    c2SecondaryBehaviours: null,
    c2Source: null,
    cameraOn: Boolean(options.cameraOn),
    recentEngagement: null,
    recentPerformanceForType: null,
    completedSessions: null,
    parentHelpLevel: options.parentHelpLevel ?? 0.0,
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
      context[6] = 0.5;
      metadata.c2SecondaryBehaviours = null;
      metadata.missingFields.push('c2SecondaryBehaviours');
    }
    metadata.c2Source = 'VideoAnalysis';
  } else {
    context[6] = 0.5;
    metadata.c2Source = null;
    metadata.missingFields.push('c2Assessment');
  }

  // [7] Camera active flag (0.0 = logs only, 1.0 = camera on)
  context[7] = options.cameraOn ? 1.0 : 0.0;

  // [8] Recent engagement trend — mean engagementScore over last 3 completed sessions.
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
        context[8] = Math.max(0, Math.min(1, meanEngagement));
        metadata.recentEngagement = context[8];
      } else {
        context[8] = 0.5;
        metadata.missingFields.push('recentEngagement');
      }
    } else {
      context[8] = 0.5;
      metadata.missingFields.push('recentEngagement');
    }
  } catch (err) {
    context[8] = 0.5;
    metadata.missingFields.push('recentEngagement');
  }

  // [9] Recent performance / TSS for this activity type
  try {
    const activityQuery = { childId };
    if (options.activityType) {
      activityQuery.activityId = new RegExp(options.activityType, 'i');
    }
    const pastResults = await ActivityResult
      .find(activityQuery)
      .sort({ createdAt: -1 })
      .limit(5)
      .select('performanceScore completionFraction')
      .lean();

    if (pastResults.length > 0) {
      const avgPerf = pastResults.reduce((sum, r) => {
        const perf = r.performanceScore ?? r.completionFraction ?? 0.5;
        return sum + perf;
      }, 0) / pastResults.length;
      context[9] = Math.max(0, Math.min(1, avgPerf));
      metadata.recentPerformanceForType = context[9];
    } else {
      context[9] = 0.5; // neutral prior
      metadata.missingFields.push('recentPerformanceForType');
    }
  } catch (err) {
    context[9] = 0.5;
    metadata.missingFields.push('recentPerformanceForType');
  }

  // [10] Number of completed sessions (normalised).
  try {
    const completedSessions = await TherapySession
      .countDocuments({ childId, status: 'Completed' });
    context[10] = Math.min(completedSessions / 20, 1.0);
    metadata.completedSessions = completedSessions;
  } catch (err) {
    context[10] = 0;
    metadata.missingFields.push('sessionCount');
  }

  // [11] Parent help level (0.0 = none, 0.33 = minimal, 0.67 = moderate, 1.0 = full)
  if (options.parentHelpLevel != null) {
    const rawHelp = Number(options.parentHelpLevel);
    // Support both 0-3 scale and normalized 0.0-1.0 scale
    const normHelp = rawHelp > 1.0 ? rawHelp / 3.0 : rawHelp;
    context[11] = Math.max(0, Math.min(1, normHelp));
  } else {
    // Check if the most recent activity result had a parentHelpLevel recorded
    try {
      const lastResult = await ActivityResult
        .findOne({ childId, parentHelpLevel: { $ne: null } })
        .sort({ createdAt: -1 })
        .select('parentHelpLevel')
        .lean();
      if (lastResult && lastResult.parentHelpLevel != null) {
        context[11] = Math.max(0, Math.min(1, lastResult.parentHelpLevel / 3.0));
      } else {
        context[11] = 0.0;
      }
    } catch (_) {
      context[11] = 0.0;
    }
  }
  metadata.parentHelpLevel = context[11];

  // Validate dimension.
  if (context.length !== CONTEXT_DIM) {
    throw new Error(
      `Context vector dimension mismatch: expected ${CONTEXT_DIM}, got ${context.length}`
    );
  }

  return { vector: context, metadata };
};

module.exports = { buildContext, CONTEXT_DIM: 12 };
