#!/usr/bin/env node
// Lists the C3 activity content that still needs the team's material or an SLP's check:
// pictures that are missing or still the generated placeholder, items without a passage or keywords, and every
// item marked placeholder.   node src/modules/c3/scripts/checkContent.js [path/to/mobile]
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const catalog = require('../data/activityCatalog.json');
const placeholders = require('../data/placeholderImages.json').sha1;

const mobile = path.resolve(process.argv[2] || path.join(__dirname, '../../../../../../mobile'));
// A picture is still the generated placeholder while its file has the recorded hash.
const isPlaceholderPng = (file) => placeholders[path.basename(file)] === crypto.createHash('sha1').update(fs.readFileSync(file)).digest('hex');

const rows = [];
for (const item of catalog.items) {
  const problems = [];
  if (item.type === 'picture_naming' || item.type === 'picture_description') {
    if (!item.image) problems.push('no picture set');
    else {
      const file = path.join(mobile, item.image);
      if (!fs.existsSync(file)) problems.push(`picture missing: ${item.image}`);
      else if (isPlaceholderPng(file)) problems.push('placeholder picture');
    }
  }
  if (item.type === 'picture_description' && !item.keywords?.si?.length) problems.push('no keywords');
  if (item.type === 'passage_reading' && !item.text?.si) problems.push('no passage text');
  if (['picture_naming', 'syllable_practice', 'word_phrase_practice'].includes(item.type) && !item.targetWords?.si?.length) problems.push('no target words');
  if (item.placeholder) problems.push('content not yet checked by an SLP (placeholder: true)');
  if (problems.length) rows.push(`${item.id.padEnd(9)} ${item.ageBand.padEnd(6)} ${item.type.padEnd(21)} ${problems.join('; ')}`);
}
console.log(`catalog ${catalog.version}: ${catalog.items.length} items; ${rows.length} need attention\n`);
console.log(rows.join('\n'));
