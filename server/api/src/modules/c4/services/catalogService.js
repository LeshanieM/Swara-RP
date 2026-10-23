/**
 * Topic banks, the parent checklist and the fixed-topic sequence (H4c control).
 * Loaded and checked once at startup: a broken bank stops the API with a clear
 * message instead of failing later inside a session.
 */
const bank = require('../data/topicBank.json');
const checklistData = require('../data/checklist.json');
const fixedData = require('../data/fixedTopics.json');
const ApiError = require('../../../lib/ApiError');

const MIN_AGE = 5;
const MAX_AGE = 14;
const TARGET_CATEGORIES = 20;
const TOPICS_PER_CATEGORY = 5;
const RANKED = 5;

const topicsById = new Map();
const categoriesByBand = new Map();

function load() {
  const problems = [];
  const warnings = [];
  for (const band of bank.bands) {
    const ids = new Set();
    for (const cat of band.categories) {
      if (ids.has(cat.id)) problems.push(`band ${band.id}: duplicate category "${cat.id}"`);
      ids.add(cat.id);
      if (cat.topics.length < TOPICS_PER_CATEGORY) warnings.push(`band ${band.id}, ${cat.id}: ${cat.topics.length} topics (target ${TOPICS_PER_CATEGORY})`);
      for (const t of cat.topics) {
        if (topicsById.has(t.id)) problems.push(`duplicate topic id "${t.id}"`);
        if (!['concrete', 'open'].includes(t.level)) problems.push(`${t.id}: level must be concrete or open`);
        if (!t.mainPrompt?.si || !t.mainPrompt?.en) problems.push(`${t.id}: main prompt needs en and si`);
        if (!Array.isArray(t.followUps) || t.followUps.length < 2 || t.followUps.length > 4) {
          problems.push(`${t.id}: needs 2-4 follow-ups`);
        }
        topicsById.set(t.id, { ...t, categoryId: cat.id, ageBand: band.id });
      }
    }
    if (band.categories.length < TARGET_CATEGORIES) {
      warnings.push(`band ${band.id}: ${band.categories.length} categories (target ${TARGET_CATEGORIES})`);
    }
    categoriesByBand.set(band.id, band.categories);
  }
  for (const [bandId, ids] of Object.entries(fixedData.bands)) {
    for (const id of ids) {
      const t = topicsById.get(id);
      if (!t || t.ageBand !== bandId) problems.push(`fixed sequence ${bandId}: unknown topic "${id}"`);
    }
  }
  if (problems.length) throw new Error(`C4 topic bank is invalid:\n- ${problems.join('\n- ')}`);
  for (const w of warnings) console.warn(`[c4] topic bank: ${w}`);
}
load();

function bandForAge(age) {
  const band = bank.bands.find((b) => age >= b.minAge && age <= b.maxAge);
  if (!band) throw ApiError.unprocessable('age_out_of_range', `C4 supports ages ${MIN_AGE}-${MAX_AGE}; got ${age}.`);
  return band.id;
}

const summariseCategory = (c) => ({
  id: c.id,
  title: c.title,
  icon: c.icon,
  topicCount: c.topics.length,
  levels: {
    concrete: c.topics.filter((t) => t.level === 'concrete').length,
    open: c.topics.filter((t) => t.level === 'open').length,
  },
});

function categories(ageBand) {
  return categoriesByBand.get(ageBand).map(summariseCategory);
}

function topics(ageBand, { category, level } = {}) {
  const cats = categoriesByBand.get(ageBand);
  if (category && !cats.some((c) => c.id === category)) {
    throw ApiError.unprocessable('unknown_category', `No category "${category}" in band ${ageBand}.`);
  }
  return cats
    .filter((c) => !category || c.id === category)
    .flatMap((c) => c.topics.map((t) => ({ ...t, categoryId: c.id })))
    .filter((t) => !level || t.level === level);
}

const findTopic = (id) => topicsById.get(id);

/** Check an onboarding ranking: exactly 5 distinct categories from the child's band. */
function checkRanking(ageBand, ranked) {
  const valid = new Set(categoriesByBand.get(ageBand).map((c) => c.id));
  const unknown = ranked.filter((id) => !valid.has(id));
  if (unknown.length) {
    throw ApiError.unprocessable('unknown_category', `Not categories of band ${ageBand}: ${unknown.join(', ')}.`, { allowed: [...valid] });
  }
  if (new Set(ranked).size !== RANKED) {
    throw ApiError.unprocessable('duplicate_category', 'Each of the 5 ranked categories must be different.');
  }
}

function checklistFor(ageBand) {
  const band = checklistData.bands.find((b) => b.id === ageBand);
  return { version: checklistData.version, reviewed: checklistData.reviewed, ageBand, items: band.items, levels: checklistData.levels };
}

function levelForYes(yes) {
  return checklistData.levels.find((l) => yes >= l.minYes && yes <= l.maxYes).id;
}

const fixedSequence = (ageBand) => fixedData.bands[ageBand].map((id) => topicsById.get(id));

const meta = () => ({
  version: bank.version,
  reviewed: bank.reviewed,
  bands: bank.bands.map((b) => ({
    id: b.id, categories: b.categories.length, topics: b.categories.reduce((n, c) => n + c.topics.length, 0),
  })),
  fixedTopics: Object.fromEntries(Object.entries(fixedData.bands).map(([k, v]) => [k, v.length])),
});

module.exports = {
  bandForAge, categories, topics, findTopic, checkRanking, checklistFor, levelForYes, fixedSequence, meta, RANKED,
};
