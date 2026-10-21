// The bandit's feature schema. Stored state records the names it was built with, so a schema change is migrated by name.

/** Per-arm context x_{t,a}: the child's state plus the arm-specific recent score for the arm's activity type. */
const CONTEXT_FEATURES = [
  'bias',
  'band11to14',        // 1 for the 11–14 band
  'c1Severity',        // C1 severity ordinal ÷ 3 (0 when missing)
  'c1Missing',         // 1 when the child has no completed C1 assessment
  'c1PercentSS',       // C1 %SS ÷ 20, capped at 1 (0 when missing)
  'c1Repetition',      // C1's main stutter type is repetition (sound or word)
  'c1BlockProlong',    // C1's main stutter type is a block or a prolongation ("Mixed" / none: both 0)
  'c2Yes',             // C2 secondary-behaviour flag = yes
  'c2Missing',         // C2 not assessed ("no" is c2Yes = c2Missing = 0)
  'c2FG',              // C2 saw facial grimacing at stutter moments
  'c2HM',              // C2 saw head movement at stutter moments
  'cameraOn',          // camera + logs engagement mode in use
  'parentHelp',        // mean parent-help level over recent activities, 0–1
  'engagementTrend',   // mean engagement over the last 3 sessions
  'typeRecentScore',   // mean reward of the last 3 activities of this arm's type
  'sessionsCompleted', // completed sessions ÷ 20, capped at 1
  'sessionElapsed',    // share of the planned session already used
];
const FEATURE_VERSION = 2; // 2: C1 %SS and type, C2 FG / HM added

/** Shared (population) features z_{t,a}: context × difficulty one-hot, plus a type one-hot. */
function sharedNames(featureNames, difficulties, types) {
  const crossed = difficulties.flatMap((d) => featureNames.map((f) => `${d}*${f}`));
  return [...crossed, ...types.map((t) => `type:${t}`)];
}

function contextVector(values, featureNames = CONTEXT_FEATURES) {
  return featureNames.map((name) => {
    const v = values[name];
    if (!Number.isFinite(v)) throw new Error(`context feature ${name} is missing or not a number`);
    return v;
  });
}

function sharedVector(x, arm, featureNames, difficulties, types) {
  const z = [];
  for (const d of difficulties) for (let i = 0; i < featureNames.length; i += 1) z.push(arm.difficulty === d ? x[i] : 0);
  for (const t of types) z.push(arm.type === t ? 1 : 0);
  return z;
}

// ---- migration by name: kept entries are copied; new dimensions start as identity (A) or zero (B, b) ----

const indexMap = (from, to) => to.map((name) => from.indexOf(name));

function remapSquare(M, from, to, diag) {
  const idx = indexMap(from, to);
  return to.map((_, i) => to.map((__, j) => {
    if (idx[i] >= 0 && idx[j] >= 0) return M[idx[i]][idx[j]];
    return i === j ? diag : 0;
  }));
}

function remapRect(M, rowsFrom, rowsTo, colsFrom, colsTo) {
  const ri = indexMap(rowsFrom, rowsTo);
  const ci = indexMap(colsFrom, colsTo);
  return rowsTo.map((_, i) => colsTo.map((__, j) => (ri[i] >= 0 && ci[j] >= 0 ? M[ri[i]][ci[j]] : 0)));
}

function remapVector(v, from, to) {
  return indexMap(from, to).map((k) => (k >= 0 ? v[k] : 0));
}

const sameNames = (a, b) => a.length === b.length && a.every((n, i) => n === b[i]);

module.exports = {
  CONTEXT_FEATURES, FEATURE_VERSION, sharedNames, contextVector, sharedVector,
  remapSquare, remapRect, remapVector, sameNames,
};
