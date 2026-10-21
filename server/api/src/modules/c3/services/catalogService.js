// Two-level activity pool. Level 1 arms (type × difficulty per age band) are what the bandit chooses between;
// Level 2 items are the content drawn for a chosen arm.
const catalog = require('../data/activityCatalog.json');
const questionnaire = require('../data/questionnaire.json');
const config = require('../config');
const ApiError = require('../../../lib/ApiError');

const MIN_AGE = config.ageBands[0].minAge;
const MAX_AGE = config.ageBands[config.ageBands.length - 1].maxAge;
const TYPES = catalog.types.map((t) => t.type);
const DIFFICULTIES = catalog.difficulties;
const armsById = new Map(catalog.arms.map((a) => [a.id, a]));
const itemsById = new Map(catalog.items.map((i) => [i.id, i]));

function bandForAge(age) {
  const band = config.ageBands.find((b) => age >= b.minAge && age <= b.maxAge);
  if (!band) {
    throw ApiError.unprocessable('age_out_of_range', `Swara supports ages ${MIN_AGE}–${MAX_AGE}; got ${age}.`, { minAge: MIN_AGE, maxAge: MAX_AGE });
  }
  return band.id;
}

const itemsForArm = (arm) => catalog.items.filter(
  (i) => i.type === arm.type && i.ageBand === arm.ageBand && i.difficulty === arm.difficulty && i.slpApproved,
);

/** Arms the bandit may choose for a band: strict age-band filter, SLP-approved, with at least one approved item. */
function eligibleArms(ageBand) {
  return catalog.arms.filter((a) => a.ageBand === ageBand && a.slpApproved && itemsForArm(a).length > 0);
}

function findArm(armId) {
  const arm = armsById.get(armId);
  if (!arm) throw ApiError.notFound('arm_not_found', `No activity arm with id ${armId}.`);
  return arm;
}

function activitiesForAge(age) {
  const ageBand = bandForAge(age);
  const arms = eligibleArms(ageBand).map((a) => ({ ...a, items: itemsForArm(a).length }));
  return { age, ageBand, catalogVersion: catalog.version, placeholder: true, count: arms.length, arms };
}

function items({ armId }) {
  const arm = findArm(armId);
  return { arm, items: itemsForArm(arm) };
}

const findItem = (itemId) => itemsById.get(itemId) || null;

/** The approved item for the arm this child used least recently (never-used items first, then catalog order). */
function drawItem(arm, lastUsedAt) {
  const pool = itemsForArm(arm);
  return [...pool].sort((a, b) => (lastUsedAt.get(a.id) ?? 0) - (lastUsedAt.get(b.id) ?? 0))[0];
}

function questionnaireFor(language) {
  const pickText = (text) => (language ? { [language]: text[language] } : text);
  return {
    version: questionnaire.version,
    _note: questionnaire._note,
    scale: { min: questionnaire.scale.min, max: questionnaire.scale.max, labels: language ? { [language]: questionnaire.scale.labels[language] } : questionnaire.scale.labels },
    items: questionnaire.items.map((i) => ({ id: i.id, text: pickText(i.text) })),
  };
}

function health() {
  const bands = Object.fromEntries(config.ageBands.map((b) => [b.id, eligibleArms(b.id).length]));
  return { version: catalog.version, arms: catalog.arms.length, items: catalog.items.length, eligibleArmsByBand: bands, questionnaire: questionnaire.version };
}

module.exports = {
  TYPES, DIFFICULTIES, MIN_AGE, MAX_AGE, questionnaire,
  bandForAge, eligibleArms, findArm, findItem, activitiesForAge, items, itemsForArm, drawItem, questionnaireFor, health,
};
