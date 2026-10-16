const ActivityResult = require('../../models/component3/ActivityResult');
const TherapyOutcome = require('../../models/component3/TherapyOutcome');
const TherapySession = require('../../models/component3/TherapySession');

/**
 * TSS (Therapy Success Score) — proposed composite research measure.
 *
 * IMPORTANT: TSS is NOT a validated clinical severity or outcome score.
 * It is a composite research measure proposed for this study and should
 * be interpreted with caution. It must not be reported as a clinical result.
 *
 * Formula:
 *   TSS = 100 × (wP × P̄ + wE × Ē + wQ × Q)
 *
 * Default weights (configurable):
 *   wP = 0.5, wE = 0.3, wQ = 0.2   (sum = 1.0)
 *
 * Missing-data rules:
 *   - If Q is missing (questionnaire not completed), renormalise wP and wE
 *     proportionally: wP' = 0.5/0.8 = 0.625, wE' = 0.3/0.8 = 0.375.
 *   - If P is missing (no valid performance observations), renormalise over E and Q.
 *   - If E is missing (all engagement unavailable), renormalise over P and Q.
 *   - If all three are missing, TSS is null (do not return 0).
 *
 * Per-activity reward (r = 0.6P + 0.4E) is separate from TSS.
 * Parent questionnaire is a session-level signal only; it is NOT used as
 * the immediate reward for individual activities.
 */

const DEFAULT_WEIGHTS = { wP: 0.5, wE: 0.3, wQ: 0.2 };

/**
 * Renormalise weights to sum to 1.0 when some components are missing.
 * Components with null values are excluded.
 *
 * @param {{ wP: number, wE: number, wQ: number }} weights
 * @param {{ P: number|null, E: number|null, Q: number|null }} values
 * @returns {{ wP: number, wE: number, wQ: number, tss: number|null }}
 */
function computeTSS(weights, values) {
  const { wP, wE, wQ } = weights;
  const { P, E, Q } = values;

  // Collect available components.
  const available = [];
  let rawTotal = 0;

  if (P !== null && P !== undefined) available.push({ key: 'P', w: wP, v: P });
  if (E !== null && E !== undefined) available.push({ key: 'E', w: wE, v: E });
  if (Q !== null && Q !== undefined) available.push({ key: 'Q', w: wQ, v: Q });

  if (available.length === 0) {
    return { wP: null, wE: null, wQ: null, tss: null };
  }

  // Renormalise weights over available components.
  const wSum = available.reduce((acc, c) => acc + c.w, 0);
  const result = { wP: null, wE: null, wQ: null };
  available.forEach(c => {
    const normW = c.w / wSum;
    result[`w${c.key}`] = normW;
    rawTotal += normW * c.v;
  });

  return { ...result, tss: Math.max(0, Math.min(100, rawTotal * 100)) };
}

/**
 * Calculates and persists TSS for a completed session.
 *
 * Bug fix (original): used TherapySession.findById(sessionId) where sessionId
 * is the string token (e.g. 'sess_…'), not the MongoDB ObjectId. Corrected to
 * findOne({ sessionId }).
 *
 * @param {string} sessionIdString  The session's string identifier (e.g. 'sess_…')
 * @returns {{ tss: number|null, reward: number|null, components: object }}
 */
const calculateAndSaveTSS = async (sessionIdString) => {
  // Bug fix: original code did findById with the string ID — correct to findOne.
  const session = await TherapySession.findOne({ sessionId: sessionIdString });
  if (!session) throw new Error(`Session not found: ${sessionIdString}`);

  const results = await ActivityResult.find({ sessionId: session._id });

  // --- Mean performance score ---
  const perfResults = results.filter(r => r.performanceScore != null);
  const meanP = perfResults.length > 0
    ? perfResults.reduce((sum, r) => sum + r.performanceScore, 0) / perfResults.length
    : null;

  // --- Mean engagement score ---
  const engResults = results.filter(r => r.engagementScore != null);
  const meanE = engResults.length > 0
    ? engResults.reduce((sum, r) => sum + r.engagementScore, 0) / engResults.length
    : null;

  // --- Questionnaire score ---
  const Q = session.parentQuestionnaire?.scaledScore ?? null;

  const { wP, wE, wQ, tss } = computeTSS(DEFAULT_WEIGHTS, { P: meanP, E: meanE, Q });

  // Update session with TSS.
  await TherapySession.findByIdAndUpdate(session._id, {
    tss,
    tssComponents: {
      meanPerformance: meanP,
      meanEngagement: meanE,
      questionnaireQ: Q,
      weightPerformance: wP,
      weightEngagement: wE,
      weightQuestionnaire: wQ,
    },
  });

  // Persist outcome record.
  const normalizedReward = tss !== null ? tss / 100 : null;

  // Only save an outcome if we have a valid TSS.
  if (tss !== null) {
    // Upsert to avoid duplicates on retry.
    await TherapyOutcome.findOneAndUpdate(
      { sessionId: session._id },
      {
        sessionId: session._id,
        childId: session.childId,
        planId: session.planId,
        TSS: tss,
        normalizedReward,
        meanPerformance: meanP,
        meanEngagement: meanE,
        questionnaireQ: Q,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }

  return {
    tss,
    reward: normalizedReward,
    components: { meanPerformance: meanP, meanEngagement: meanE, questionnaireQ: Q },
  };
};

module.exports = {
  calculateAndSaveTSS,
  computeTSS,         // exported for unit testing
  DEFAULT_WEIGHTS,    // exported for documentation / overrides
};
