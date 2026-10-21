// Loads and saves Hybrid LinUCB state in MongoDB. Updates go through one in-process lock, because the shared
// population matrices are read-modify-written by every child's update (the API runs as a single process).
const BanditState = require('../models/BanditState');
const features = require('../bandit/features');
const hybrid = require('../bandit/hybridLinUCB');
const config = require('../config');
const { TYPES, DIFFICULTIES } = require('./catalogService');

const FEATURES = features.CONTEXT_FEATURES;
const SHARED = features.sharedNames(FEATURES, DIFFICULTIES, TYPES);

let chain = Promise.resolve();
/** Run fn while holding the bandit lock (FIFO). */
function withLock(fn) {
  const run = chain.then(fn, fn);
  chain = run.catch(() => {});
  return run;
}

function migrationNote(doc) {
  const oldNames = [...(doc.featureNames || []), ...(doc.sharedNames || [])];
  const newNames = [...FEATURES, ...SHARED];
  return {
    featureVersion: doc.featureVersion,
    at: new Date(),
    added: newNames.filter((n) => !oldNames.includes(n)),
    removed: oldNames.filter((n) => !newNames.includes(n)),
  };
}

const needsMigration = (doc) => !features.sameNames(doc.featureNames || [], FEATURES)
  || !features.sameNames(doc.sharedNames || [], SHARED);

/** Remap stored matrices to the current schema by feature name; new dimensions start at the prior. */
function migrate(doc) {
  const note = migrationNote(doc);
  if (doc.scope === 'population') {
    doc.A0 = features.remapSquare(doc.A0, doc.sharedNames, SHARED, 1);
    doc.b0 = features.remapVector(doc.b0, doc.sharedNames, SHARED);
  } else {
    for (const arm of Object.values(doc.arms)) {
      arm.A = features.remapSquare(arm.A, doc.featureNames, FEATURES, config.childPrior);
      arm.B = features.remapRect(arm.B, doc.featureNames, FEATURES, doc.sharedNames, SHARED);
      arm.b = features.remapVector(arm.b, doc.featureNames, FEATURES);
    }
    doc.markModified('arms');
  }
  doc.featureNames = FEATURES;
  doc.sharedNames = SHARED;
  doc.featureVersion = features.FEATURE_VERSION;
  doc.migratedFrom.push(note);
  console.warn(`[c3-bandit] migrated ${doc.scope}${doc.childId ? ` ${doc.childId}` : ''} state: +${note.added.length} / -${note.removed.length} features`);
  return doc;
}

async function loadPopulation() {
  let doc = await BanditState.findOne({ scope: 'population', childId: null });
  if (!doc) {
    const fresh = hybrid.newPopulation(SHARED.length);
    doc = new BanditState({ scope: 'population', childId: null, featureVersion: features.FEATURE_VERSION, featureNames: FEATURES, sharedNames: SHARED, ...fresh });
  } else if (needsMigration(doc)) {
    migrate(doc);
    await save(doc); // persist at once, so a read-only load doesn't redo the migration every time
  }
  return doc;
}

async function loadChild(childId, armIds = []) {
  let doc = await BanditState.findOne({ scope: 'child', childId });
  if (!doc) {
    doc = new BanditState({ scope: 'child', childId, featureVersion: features.FEATURE_VERSION, featureNames: FEATURES, sharedNames: SHARED, arms: {} });
  } else if (needsMigration(doc)) {
    migrate(doc);
    await save(doc);
  }
  for (const id of armIds) {
    if (!doc.arms[id]) {
      doc.arms[id] = hybrid.newArm(FEATURES.length, SHARED.length, config.childPrior);
      doc.markModified('arms');
    }
  }
  return doc;
}

/** Plain-array copy of the shared part, for the pure bandit functions; write it back with applyPopulation. */
const populationView = (doc) => ({ A0: doc.A0.map((row) => [...row]), b0: [...doc.b0] });
function applyPopulation(doc, view) {
  doc.A0 = view.A0;
  doc.b0 = view.b0;
}

async function save(...docs) {
  for (const doc of docs) {
    if (doc.scope === 'population') {
      doc.markModified('A0');
      doc.markModified('b0');
    } else {
      doc.markModified('arms');
    }
    await doc.save();
  }
}

module.exports = { FEATURES, SHARED, withLock, loadPopulation, loadChild, populationView, applyPopulation, save };
