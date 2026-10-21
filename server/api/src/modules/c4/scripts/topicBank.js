#!/usr/bin/env node
// C4 topic bank <-> CSV, so the team's topic document can be pasted into a spreadsheet and loaded.
//
//   node src/modules/c4/scripts/topicBank.js export topic-bank.csv     current bank -> CSV (the template)
//   node src/modules/c4/scripts/topicBank.js import topic-bank.csv     CSV -> data/topicBank.json (+ fixedTopics.json)
//
// One row per topic: band (5-10 | 11-14), category_id, category_en, category_si, category_icon, topic_id (optional:
// made from band.category.NN), level (concrete | open), title_en, title_si, main_en, main_si, then 2-4 follow-ups as
// follow1_en, follow1_si ... follow4_en, follow4_si. Import checks the bank the way the API does at startup, and
// more strictly: each band needs at least 20 categories with exactly 5 topics each. The bank is saved with
// reviewed: false until an SLP or teacher has checked it.
const fs = require('fs');
const path = require('path');

const BANK = path.join(__dirname, '..', 'data', 'topicBank.json');
const FIXED = path.join(__dirname, '..', 'data', 'fixedTopics.json');
const BANDS = { '5-10': { minAge: 5, maxAge: 10 }, '11-14': { minAge: 11, maxAge: 14 } };
const MIN_CATEGORIES = 20;
const TOPICS_PER_CATEGORY = 5;
const FIXED_LENGTH = 8;
const COLUMNS = ['band', 'category_id', 'category_en', 'category_si', 'category_icon', 'topic_id', 'level', 'title_en', 'title_si',
  'main_en', 'main_si', ...[1, 2, 3, 4].flatMap((i) => [`follow${i}_en`, `follow${i}_si`])];

const quote = (v) => {
  const s = v == null ? '' : String(v);
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

/** RFC 4180 CSV (quoted fields may hold commas, quotes and newlines). */
function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    if (inQuotes) {
      if (ch === '"' && text[i + 1] === '"') { field += '"'; i += 1; } else if (ch === '"') inQuotes = false; else field += ch;
    } else if (ch === '"') inQuotes = true;
    else if (ch === ',') { row.push(field); field = ''; } else if (ch === '\n' || ch === '\r') {
      if (ch === '\r' && text[i + 1] === '\n') i += 1;
      row.push(field); field = '';
      if (row.some((f) => f.trim() !== '')) rows.push(row);
      row = [];
    } else field += ch;
  }
  row.push(field);
  if (row.some((f) => f.trim() !== '')) rows.push(row);
  return rows;
}

function exportCsv(file) {
  const bank = JSON.parse(fs.readFileSync(BANK, 'utf8'));
  const lines = [COLUMNS.join(',')];
  for (const band of bank.bands) {
    for (const cat of band.categories) {
      for (const t of cat.topics) {
        const follow = [0, 1, 2, 3].flatMap((i) => [t.followUps[i]?.en ?? '', t.followUps[i]?.si ?? '']);
        lines.push([band.id, cat.id, cat.title.en, cat.title.si, cat.icon ?? '', t.id, t.level, t.title.en, t.title.si,
          t.mainPrompt.en, t.mainPrompt.si, ...follow].map(quote).join(','));
      }
    }
  }
  fs.writeFileSync(file, `﻿${lines.join('\n')}\n`); // BOM: spreadsheets then read the Sinhala as UTF-8
  console.log(`wrote ${lines.length - 1} topics to ${file}`);
}

function importCsv(file) {
  const rows = parseCsv(fs.readFileSync(file, 'utf8').replace(/^﻿/, ''));
  const header = rows.shift().map((h) => h.trim().toLowerCase());
  const missing = COLUMNS.slice(0, 11).filter((c) => c !== 'topic_id' && c !== 'category_icon' && !header.includes(c));
  if (missing.length) {
    console.error(`Not imported: the CSV is missing the columns ${missing.join(', ')} (export the template to see them).`);
    process.exit(1);
  }
  const col = (r, name) => (header.includes(name) ? (r[header.indexOf(name)] ?? '').trim() : '');
  const problems = [];
  const bands = new Map(Object.keys(BANDS).map((b) => [b, new Map()]));
  rows.forEach((r, i) => {
    const line = i + 2;
    const band = col(r, 'band');
    if (!bands.has(band)) { problems.push(`line ${line}: band must be 5-10 or 11-14 (got "${band}")`); return; }
    const catId = col(r, 'category_id').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    if (!catId) { problems.push(`line ${line}: category_id is empty`); return; }
    const cats = bands.get(band);
    if (!cats.has(catId)) {
      cats.set(catId, { id: catId, title: { en: col(r, 'category_en'), si: col(r, 'category_si') }, icon: col(r, 'category_icon') || undefined, topics: [] });
    }
    const cat = cats.get(catId);
    const level = col(r, 'level').toLowerCase();
    const followUps = [1, 2, 3, 4].map((k) => ({ en: col(r, `follow${k}_en`), si: col(r, `follow${k}_si`) })).filter((f) => f.en || f.si);
    const topic = {
      id: col(r, 'topic_id') || `${band}.${catId}.${String(cat.topics.length + 1).padStart(2, '0')}`,
      level,
      title: { en: col(r, 'title_en'), si: col(r, 'title_si') },
      mainPrompt: { en: col(r, 'main_en'), si: col(r, 'main_si') },
      followUps,
    };
    if (!['concrete', 'open'].includes(level)) problems.push(`line ${line} (${topic.id}): level must be concrete or open`);
    if (!topic.mainPrompt.en || !topic.mainPrompt.si) problems.push(`line ${line} (${topic.id}): main prompt needs English and Sinhala`);
    if (!cat.title.en || !cat.title.si) problems.push(`line ${line}: category ${catId} needs an English and a Sinhala name`);
    if (followUps.length < 2 || followUps.length > 4) problems.push(`line ${line} (${topic.id}): needs 2-4 follow-ups (got ${followUps.length})`);
    if (followUps.some((f) => !f.en || !f.si)) problems.push(`line ${line} (${topic.id}): every follow-up needs English and Sinhala`);
    cat.topics.push(topic);
  });
  const ids = new Set();
  for (const [band, cats] of bands) {
    if (cats.size < MIN_CATEGORIES) problems.push(`band ${band}: ${cats.size} categories (at least ${MIN_CATEGORIES} needed)`);
    for (const cat of cats.values()) {
      if (cat.topics.length !== TOPICS_PER_CATEGORY) problems.push(`band ${band}, ${cat.id}: ${cat.topics.length} topics (exactly ${TOPICS_PER_CATEGORY} needed)`);
      for (const t of cat.topics) {
        if (ids.has(t.id)) problems.push(`duplicate topic id ${t.id}`);
        ids.add(t.id);
      }
    }
  }
  if (problems.length) {
    console.error(`Not imported: ${problems.length} problem(s)\n- ${problems.join('\n- ')}`);
    process.exit(1);
  }
  const old = JSON.parse(fs.readFileSync(BANK, 'utf8'));
  const bank = {
    version: `c4-topics-${new Date().toISOString().slice(0, 10)}`,
    reviewed: false,
    note: `Imported from ${path.basename(file)}. An SLP or teacher must check every prompt before use with children, then set reviewed: true.`,
    bands: [...bands].map(([id, cats]) => ({ id, ...BANDS[id], categories: [...cats.values()] })),
  };
  fs.writeFileSync(BANK, `${JSON.stringify(bank, null, 1)}\n`);
  // The fixed-topic research sequence must point at topics that exist: rebuild it from the new bank.
  const fixed = JSON.parse(fs.readFileSync(FIXED, 'utf8'));
  fixed.bands = Object.fromEntries(bank.bands.map((b) => [b.id, b.categories.slice(0, FIXED_LENGTH).map((c) => c.topics[0].id)]));
  fs.writeFileSync(FIXED, `${JSON.stringify(fixed, null, 1)}\n`);
  console.log(`imported ${ids.size} topics (${bank.bands.map((b) => `${b.id}: ${b.categories.length} categories`).join(', ')}); previous version ${old.version}`);
}

const [cmd, file] = process.argv.slice(2);
if (cmd === 'export' && file) exportCsv(file);
else if (cmd === 'import' && file) importCsv(file);
else {
  console.error('usage: topicBank.js export <file.csv> | import <file.csv>');
  process.exit(2);
}
