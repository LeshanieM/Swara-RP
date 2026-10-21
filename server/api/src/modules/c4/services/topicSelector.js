/**
 * One topic per session, chosen by weights rather than a strict order (otherwise
 * the favourite category would always win). Priorities, in order:
 *   1. the child's age group (the bank is per band; done by the caller);
 *   2. the ranked interests (category weights);
 *   3. progress: C3's TSS trend, the C4 band and the parent checklist (topic level, levelPolicy in sessionService);
 *   4. variety (no topic repeats until all 25 of the child's topics were used; last session's category blocked)
 *      and the stuttering rate: when %SS from C1 / C4 is rising, the weights favour the top-ranked, most
 *      liked categories more strongly (STEEP_RANK_WEIGHTS) and concrete topics are preferred.
 *
 * Two seeded weighted draws:
 *
 * 1. Category: 5:4:3:2:1 by the child's ranking (8:4:2:1:0.5 when stuttering is rising); 0 for last session's
 *    category, unless nothing else is left; 0 for a category whose topics were all used in this cycle.
 * 2. Topic within that category: level weight × recency weight.
 *    - Level: when the progress signal asks for concrete topics, open topics get
 *      OPEN_WHEN_CONCRETE; otherwise both levels weigh 1.
 *    - Recency: topics are ranked least-recently-used first (never-used topics
 *      share the top rank) and weigh LRU_DECAY ** rank, i.e. 1, 0.1, 0.01, ...
 *      so a category's topics rotate before any repeats.
 *
 * Splitting the draw keeps the category shares at the ranking's weights over
 * time; one combined draw flattened them. Every candidate's weights and
 * probability are returned, so a choice can be explained.
 *
 * Note: blocking last session's category changes the long-run shares from
 * 5:4:3:2:1 to w·(15 − w), i.e. about 29 / 26 / 21 / 15 / 8 %.
 */
const ApiError = require('../../../lib/ApiError');

const RANK_WEIGHTS = [5, 4, 3, 2, 1];
const STEEP_RANK_WEIGHTS = [8, 4, 2, 1, 0.5];
const OPEN_WHEN_CONCRETE = 0.2;
// Recency weight by least-recently-used rank inside the category: 1, 0.1, 0.01, ...
const LRU_DECAY = 0.1;

/** mulberry32: small, fast, seedable PRNG. */
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const round = (x) => Math.round(x * 10000) / 10000;

function draw(items, weightOf, u) {
  const total = items.reduce((s, it) => s + weightOf(it), 0);
  let acc = 0;
  for (const it of items) {
    acc += weightOf(it);
    if (weightOf(it) > 0 && u * total < acc) return { item: it, total };
  }
  return { item: [...items].reverse().find((it) => weightOf(it) > 0), total };
}

/**
 * @param {object} p
 * @param {string[]} p.rankedCategories  most favourite first
 * @param {(categoryId: string) => object[]} p.topicsOf  topics of a category in the child's band
 * @param {{topicId: string, categoryId: string}[]} p.history  earlier sessions, oldest first
 * @param {{preferConcrete: boolean}} p.levelPolicy
 * @param {string[]} [p.exclude]  topic ids already offered in this session
 * @param {number} p.seed
 */
/**
 * Topics of the child's ranked categories used since the last full cycle: walking the history oldest first, a cycle
 * ends when every topic of the pool has been used, and then starts again empty.
 */
function usedThisCycle(pool, history) {
  const used = new Set();
  for (const h of history) {
    if (!pool.has(h.topicId)) continue;
    used.add(h.topicId);
    if (used.size === pool.size) used.clear();
  }
  return used;
}

function select({ rankedCategories, topicsOf, history, levelPolicy, exclude = [], seed }) {
  const lastCategory = history.length ? history[history.length - 1].categoryId : null;
  const lastUsed = new Map();
  history.forEach((h, i) => lastUsed.set(h.topicId, i));
  const pool = new Set(rankedCategories.flatMap((c) => topicsOf(c).map((t) => t.id)));
  let cycleUsed = usedThisCycle(pool, history);
  // A topic skipped in this session can't come back either; if that leaves nothing unused, start a new cycle.
  if ([...pool].every((id) => cycleUsed.has(id) || exclude.includes(id))) cycleUsed = new Set();
  const rankWeights = levelPolicy.stutteringRising ? STEEP_RANK_WEIGHTS : RANK_WEIGHTS;

  const categories = rankedCategories.map((categoryId, rank) => {
    const available = topicsOf(categoryId).filter((t) => !exclude.includes(t.id) && !cycleUsed.has(t.id));
    // LRU rank: never-used topics share rank 0; then by how long ago they were used.
    // When concrete topics are preferred, each level is ranked on its own, so level
    // outranks recency (an unused open topic can't beat a used concrete one by recency alone).
    const lastIdx = (t) => (lastUsed.has(t.id) ? lastUsed.get(t.id) : -1);
    const group = (t) => (levelPolicy.preferConcrete ? t.level : 'all');
    const ranksIn = (g) => [...new Set(available.filter((t) => group(t) === g).map(lastIdx))].sort((a, b) => a - b);
    const topics = available.map((t) => {
      const level = levelPolicy.preferConcrete && t.level === 'open' ? OPEN_WHEN_CONCRETE : 1;
      const since = lastUsed.has(t.id) ? history.length - lastUsed.get(t.id) : null;
      const lruRank = ranksIn(group(t)).indexOf(lastIdx(t));
      const recency = LRU_DECAY ** lruRank;
      return { topic: t, level, recency, since, lruRank, score: level * recency };
    });
    return { categoryId, rank: rank + 1, topics, weight: topics.length ? rankWeights[rank] : 0 };
  });

  let lastCategoryBlocked = false;
  const open = categories.filter((c) => c.weight > 0);
  if (!open.length) {
    throw ApiError.unprocessable('no_topics_left', 'Every topic in the child\'s categories was skipped in this session.');
  }
  if (open.some((c) => c.categoryId !== lastCategory)) {
    for (const c of categories) {
      if (c.categoryId === lastCategory && c.weight > 0) {
        c.weight = 0;
        lastCategoryBlocked = true;
      }
    }
  }

  const random = rng(seed);
  const { item: category, total: categoryTotal } = draw(categories, (c) => c.weight, random());
  const { item: picked } = draw(category.topics, (t) => t.score, random());

  const candidates = categories.flatMap((c) => {
    const pCategory = categoryTotal ? c.weight / categoryTotal : 0;
    const topicTotal = c.topics.reduce((s, t) => s + t.score, 0);
    return c.topics.map((t) => ({
      topicId: t.topic.id,
      categoryId: c.categoryId,
      rank: c.rank,
      level: t.topic.level,
      sessionsSinceUsed: t.since,
      lruRank: t.lruRank,
      weights: { category: c.weight, level: t.level, recency: round(t.recency) },
      probability: round(pCategory * (topicTotal ? t.score / topicTotal : 0)),
    }));
  }).sort((a, b) => b.probability - a.probability);

  return {
    topic: picked.topic,
    selection: {
      method: 'weighted-draw:category-then-topic',
      seed,
      lastCategory,
      lastCategoryBlocked,
      levelPolicy,
      rankWeights,
      cycle: { topics: pool.size, usedBefore: cycleUsed.size, remaining: pool.size - cycleUsed.size },
      priorities: ['age_group', 'ranked_interests', 'progress (C3 TSS trend, C4 band, checklist)', 'variety and stuttering rate'],
      chosen: {
        topicId: picked.topic.id,
        categoryId: category.categoryId,
        probability: candidates.find((c) => c.topicId === picked.topic.id).probability,
      },
      candidates,
    },
  };
}

module.exports = { select, usedThisCycle, RANK_WEIGHTS, STEEP_RANK_WEIGHTS, OPEN_WHEN_CONCRETE };
