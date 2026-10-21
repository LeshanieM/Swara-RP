/**
 * Data for C4's two research questions.
 *
 * H4c: personalised topics elicit longer responses than fixed topics. Per child,
 * mean words per sample in personalised vs fixed sessions; a paired Wilcoxon
 * signed-rank test over children who have both. Exact (all sign assignments) up
 * to EXACT_MAX_N pairs, normal approximation with tie and continuity corrections
 * above (checked against scipy.stats.wilcoxon, verification log).
 *
 * H4d: utterances longer or more complex than the child's own MLU are more
 * likely to contain a stutter. One row per utterance with a known stutter flag
 * (C1 assessed and timed words); the descriptive split is here, the grouped
 * logistic regression is run offline on the exported rows.
 */
const LanguageSample = require('../models/LanguageSample');

const EXACT_MAX_N = 16;
const round = (x, nd = 4) => (x == null || Number.isNaN(x) ? null : Math.round(x * 10 ** nd) / 10 ** nd);
const mean = (xs) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null);

function normalCdf(z) {
  // Abramowitz–Stegun 7.1.26
  const t = 1 / (1 + 0.3275911 * Math.abs(z) / Math.SQRT2);
  const y = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * Math.exp(-(z * z) / 2);
  return z >= 0 ? (1 + y) / 2 : (1 - y) / 2;
}

/** Wilcoxon signed-rank on paired differences d (zeros dropped); alternative: median d > 0. */
function wilcoxon(diffs) {
  const d = diffs.filter((x) => x !== 0);
  const n = d.length;
  if (n === 0) return { n: 0, wPlus: null, pOneSided: null, pTwoSided: null, method: 'none' };
  const order = d.map((x, i) => ({ a: Math.abs(x), i })).sort((p, q) => p.a - q.a);
  const ranks = new Array(n);
  let tieTerm = 0; // Σ(t³ − t) over tie groups, for the variance correction
  for (let k = 0; k < n;) {
    let j = k;
    while (j + 1 < n && order[j + 1].a === order[k].a) j += 1;
    const r = (k + j + 2) / 2; // average rank for ties
    for (let m = k; m <= j; m += 1) ranks[order[m].i] = r;
    const t = j - k + 1;
    tieTerm += t ** 3 - t;
    k = j + 1;
  }
  const wPlus = d.reduce((s, x, i) => s + (x > 0 ? ranks[i] : 0), 0);
  const total = (n * (n + 1)) / 2;
  let pUpper;
  let pLower;
  let method;
  if (n <= EXACT_MAX_N) {
    // Enumerate every sign assignment of the (possibly tied) ranks.
    let atLeast = 0;
    let atMost = 0;
    const combos = 2 ** n;
    for (let mask = 0; mask < combos; mask += 1) {
      let w = 0;
      for (let i = 0; i < n; i += 1) if (mask & (1 << i)) w += ranks[i];
      if (w >= wPlus - 1e-9) atLeast += 1;
      if (w <= wPlus + 1e-9) atMost += 1;
    }
    pUpper = atLeast / combos;
    pLower = atMost / combos;
    method = 'exact';
  } else {
    const mu = total / 2;
    const sigma = Math.sqrt((n * (n + 1) * (2 * n + 1)) / 24 - tieTerm / 48);
    pUpper = 1 - normalCdf((wPlus - 0.5 - mu) / sigma);
    pLower = normalCdf((wPlus + 0.5 - mu) / sigma);
    method = 'normal_approximation';
  }
  return {
    n, wPlus, wMinus: total - wPlus, pOneSided: round(pUpper), pTwoSided: round(Math.min(1, 2 * Math.min(pUpper, pLower))), method,
  };
}

async function h4c() {
  const docs = await LanguageSample.find({ status: 'completed' }).select('childId mode analysis.measures.totalWords analysis.flags');
  const byChild = new Map();
  for (const doc of docs) {
    const entry = byChild.get(doc.childId) || { personalised: [], fixed: [] };
    entry[doc.mode].push(doc.analysis?.measures?.totalWords ?? 0);
    byChild.set(doc.childId, entry);
  }
  const children = [...byChild].map(([childId, v]) => ({
    childId,
    personalisedSamples: v.personalised.length,
    fixedSamples: v.fixed.length,
    meanWordsPersonalised: round(mean(v.personalised), 2),
    meanWordsFixed: round(mean(v.fixed), 2),
  }));
  const paired = children.filter((c) => c.personalisedSamples && c.fixedSamples);
  const diffs = paired.map((c) => c.meanWordsPersonalised - c.meanWordsFixed);
  return {
    hypothesis: 'H4c: personalised topics elicit longer responses (words per sample) than fixed topics',
    measure: 'mean words after maze removal per sample, per child',
    pairedChildren: paired.length,
    medianDifference: paired.length ? round([...diffs].sort((a, b) => a - b)[Math.floor((diffs.length - 1) / 2)], 2) : null,
    test: { name: 'Wilcoxon signed-rank (paired over children)', alternative: 'personalised > fixed', ...wilcoxon(diffs) },
    children,
  };
}

async function h4dRows(childId) {
  const docs = await LanguageSample.find({ status: 'completed', ...(childId && { childId }) })
    .sort({ childId: 1, createdAt: 1 })
    .select('childId sessionId createdAt ageBand analysis.source analysis.utterances analysis.measures.mluWords stuttering.status');
  // The child's own MLU: mean of their sample MLUs.
  const mluByChild = new Map();
  for (const doc of docs) {
    const m = doc.analysis?.measures?.mluWords;
    if (m != null) mluByChild.set(doc.childId, [...(mluByChild.get(doc.childId) || []), m]);
  }
  const rows = [];
  for (const doc of docs) {
    const childMlu = mean(mluByChild.get(doc.childId) || []);
    for (const u of doc.analysis?.utterances || []) {
      if (u.mazeOnly || u.stutter === null || u.stutter === undefined || !childMlu) continue;
      rows.push({
        childId: doc.childId,
        sampleId: doc.id,
        ageBand: doc.ageBand,
        transcriptSource: doc.analysis.source,
        utterance: u.index,
        start: u.start,
        end: u.end,
        words: u.wordCount,
        complexity: u.complexity,
        childMluWords: round(childMlu, 2),
        relativeLength: round(u.wordCount / childMlu, 3),
        longerThanOwnMlu: u.wordCount > childMlu,
        moreComplexThanOne: u.complexity > 1,
        stutter: u.stutter,
      });
    }
  }
  return rows;
}

function split(rows, key) {
  const group = (flag) => {
    const g = rows.filter((r) => r[key] === flag);
    return { utterances: g.length, withStutter: g.filter((r) => r.stutter).length, stutterRate: round(g.length ? g.filter((r) => r.stutter).length / g.length : null) };
  };
  return { true: group(true), false: group(false) };
}

async function h4d(childId) {
  const rows = await h4dRows(childId);
  return {
    hypothesis: 'H4d: utterances longer or more complex than the child\'s own MLU are more likely to contain a stutter',
    note: 'Rows need C1-assessed samples with timed words. Fit the logistic regression grouped by child offline on these rows.',
    children: new Set(rows.map((r) => r.childId)).size,
    utterances: rows.length,
    byLength: split(rows, 'longerThanOwnMlu'),
    byComplexity: split(rows, 'moreComplexThanOne'),
    rows,
  };
}

function toCsv(rows) {
  const cols = ['childId', 'sampleId', 'ageBand', 'transcriptSource', 'utterance', 'start', 'end', 'words', 'complexity',
    'childMluWords', 'relativeLength', 'longerThanOwnMlu', 'moreComplexThanOne', 'stutter'];
  const esc = (v) => (v == null ? '' : /[",\n]/.test(String(v)) ? `"${String(v).replace(/"/g, '""')}"` : String(v));
  return [cols.join(','), ...rows.map((r) => cols.map((c) => esc(r[c])).join(','))].join('\n');
}

module.exports = { h4c, h4d, h4dRows, toCsv, wilcoxon };
