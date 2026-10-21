// The child's overall progress across the four components: one shared measure, the stuttering rate (%SS) over time
// from C1's assessments and C4's spontaneous-speech samples (C4 runs every recording through C1), with the other
// components as supporting evidence: C3's Therapy Success Score trend, C4's language band and C2's behaviour flag.
//
// Verdict (provisional, to be agreed with an SLP; RULE below):
// - insufficient_data: fewer than RULE.minPoints %SS measurements;
// - improved: the mean of the last RULE.recent points is at least RULE.changePP below the mean of the earlier ones,
//   and neither C3's TSS nor C4's band is getting worse (otherwise: no_clear_change, with the reason);
// - needs_attention: the recent mean is at least RULE.changePP above the earlier one;
// - no_clear_change: anything in between.
const SpeechAssessment = require('../modules/c1/models/SpeechAssessment');
const LanguageSample = require('../modules/c4/models/LanguageSample');

const RULE = Object.freeze({ minPoints: 4, recent: 3, earlier: 3, changePP: 1.5, provisional: true });

const mean = (xs) => xs.reduce((a, b) => a + b, 0) / xs.length;
const r2 = (x) => (x == null ? null : Math.round(x * 100) / 100);

async function percentSSSeries(childId) {
  const [assessments, samples] = await Promise.all([
    SpeechAssessment.find({ childId, status: 'completed' }).select('createdAt taskType result.percentSS'),
    LanguageSample.find({ childId, status: 'completed', 'stuttering.status': 'assessed' })
      .select('createdAt topic stuttering.percentSS stuttering.percentSSCurrent'),
  ]);
  return [
    ...assessments.map((a) => ({ date: a.createdAt, source: 'c1', task: a.taskType, percentSS: a.result.percentSS })),
    ...samples.map((s) => ({
      date: s.createdAt, source: 'c4', task: 'spontaneous', percentSS: s.stuttering.percentSSCurrent ?? s.stuttering.percentSS,
    })),
  ].filter((p) => Number.isFinite(p.percentSS)).sort((a, b) => a.date - b.date);
}

/** Summaries are read in-process through each component's own service (a missing component is reported, not fatal). */
async function safe(fn) {
  try {
    return await fn();
  } catch (err) {
    return { error: err.message };
  }
}

async function overall(childId) {
  /* eslint-disable global-require */
  const [series, c1, c2, c3, c4] = await Promise.all([
    percentSSSeries(childId),
    safe(() => require('../modules/c1/services/assessmentService').summaryForChild(childId)),
    safe(() => require('../modules/c2/services/analysisService').summaryForChild(childId)),
    safe(() => require('../modules/c3/services/sessionService').summaryForChild(childId)),
    safe(() => require('../modules/c4/services/childService').summary(childId)),
  ]);
  /* eslint-enable global-require */
  const evidence = {
    c1: { latestPercentSS: c1.latest?.percentSS ?? null, severity: c1.latest?.severity ?? null, assessments: c1.completedAssessments ?? 0 },
    c2: { flag: c2.c2Flag ?? 'missing', trend: c2.trend ?? 'insufficient_data' },
    c3: { tssLatest: c3.tss?.latest ?? null, tssTrend: c3.tss?.trend ?? 'insufficient_data', sessions: c3.sessionsCompleted ?? 0 },
    c4: { band: c4.band?.effective ?? null, trend: c4.trend ?? 'insufficient_data', samples: c4.completedSamples ?? 0 },
  };

  const pss = { series: series.map((p) => ({ ...p, percentSS: r2(p.percentSS) })), points: series.length };
  let status;
  const reasons = [];
  if (series.length < RULE.minPoints) {
    status = 'insufficient_data';
    reasons.push(`${series.length} %SS measurement(s) so far; ${RULE.minPoints} are needed (C1 assessments and C4 speech sessions both count).`);
  } else {
    const values = series.map((p) => p.percentSS);
    const recent = values.slice(-RULE.recent);
    const earlier = values.slice(0, -RULE.recent).slice(-RULE.earlier);
    pss.recentMean = r2(mean(recent));
    pss.earlierMean = r2(mean(earlier));
    pss.change = r2(pss.recentMean - pss.earlierMean);
    if (pss.change <= -RULE.changePP) {
      status = 'improved';
      reasons.push(`Stuttering went down from ${pss.earlierMean}% to ${pss.recentMean}% of syllables.`);
      const worse = [];
      if (evidence.c3.tssTrend === 'needs_attention') worse.push('the therapy success score (C3) is falling');
      if (evidence.c4.band === 'below') worse.push('the language measures (C4) are below the child\'s starting level');
      if (worse.length) {
        status = 'no_clear_change';
        reasons.push(`But ${worse.join(' and ')}, so the overall picture is mixed.`);
      }
    } else if (pss.change >= RULE.changePP) {
      status = 'needs_attention';
      reasons.push(`Stuttering went up from ${pss.earlierMean}% to ${pss.recentMean}% of syllables.`);
    } else {
      status = 'no_clear_change';
      reasons.push(`Stuttering stayed about the same (${pss.earlierMean}% → ${pss.recentMean}%).`);
    }
  }
  if (evidence.c3.tssTrend === 'improving') reasons.push('Therapy sessions are going better (C3).');
  if (evidence.c4.trend === 'improving') reasons.push('Sentences are getting longer (C4).');
  if (evidence.c2.flag === 'yes') reasons.push('Secondary behaviours were seen at stutter moments (C2).');
  return { childId, verdict: { status, reasons, rule: RULE }, percentSS: pss, evidence };
}

module.exports = { overall, percentSSSeries, RULE };
