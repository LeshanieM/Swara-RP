require('dotenv').config();
const mongoose = require('mongoose');
const Topic = require('../models/component4/Topic');

const categories = {
  animals: ['සතුන් ගැන', 'ඔබ කැමති සතෙකු ගැන', 'සතෙකුගේ දවස ගැන', 'සතුන්ට උදව් කිරීම ගැන', 'සතුන් සිටින තැනක් ගැන'],
  sports: ['ක්‍රීඩාව ගැන', 'ඔබ කැමති ක්‍රීඩාව ගැන', 'ක්‍රීඩා කරන දවස ගැන', 'කණ්ඩායමක් ගැන', 'අලුත් ක්‍රීඩාවක් ගැන'],
  games: ['සෙල්ලම ගැන', 'ඔබ කැමති සෙල්ලම ගැන', 'මිතුරන් සමඟ සෙල්ලම් කිරීම ගැන', 'අලුත් සෙල්ලමක් ගැන', 'සෙල්ලම් බඩුවක් ගැන'],
  school: ['පාසල ගැන', 'ඔබ කැමති පාඩම ගැන', 'පාසලේ විවේක කාලය ගැන', 'ගුරුවරයෙකු ගැන', 'පාසලේ විශේෂ දවසක් ගැන'],
  family: ['පවුල ගැන', 'පවුලේ අය සමඟ කරන දෙයක් ගැන', 'ගෙදර දවසක් ගැන', 'පවුලේ විශේෂ අවස්ථාවක් ගැන', 'ඔබට උදව් කරන කෙනෙකු ගැන'],
  food: ['කෑම ගැන', 'ඔබ කැමති කෑමක් ගැන', 'කෑමක් හදන හැටි ගැන', 'කෑම කන අවස්ථාවක් ගැන', 'අලුත් කෑමක් ගැන'],
  art: ['චිත්‍ර හා කලාව ගැන', 'ඔබ ඇඳීමට කැමති දෙයක් ගැන', 'කලා නිර්මාණයක් ගැන', 'පාට ගැන', 'අලුත් නිර්මාණයක් ගැන'],
  music: ['සංගීතය ගැන', 'ඔබ කැමති ගීතයක් ගැන', 'සංගීත භාණ්ඩයක් ගැන', 'ගීතයක් අසන අවස්ථාවක් ගැන', 'අලුත් තාලයක් ගැන'],
  nature: ['ස්වභාවධර්මය ගැන', 'ඔබ දැක ඇති ගසක් ගැන', 'වැස්ස හෝ අව්ව ගැන', 'උයනක් ගැන', 'පරිසරය රැකීම ගැන'],
  travel: ['ගමනක් ගැන', 'ඔබ ගිය තැනක් ගැන', 'ගමනකදී දුටු දේ ගැන', 'යන්න කැමති තැනක් ගැන', 'ගමනක් සැලසුම් කිරීම ගැන'],
  vehicles: ['වාහන ගැන', 'ඔබ කැමති වාහනය ගැන', 'ගමනකදී භාවිත කරන වාහනය ගැන', 'අලුත් වාහනයක් ගැන', 'වාහනයක ගමනක් ගැන'],
  stories: ['කතාවක් ගැන', 'ඔබ කැමති චරිතයක් ගැන', 'කතාවක සිදුවීමක් ගැන', 'අලුත් කතාවක් ගැන', 'කතාවක අවසානයක් ගැන'],
  friends: ['මිතුරන් ගැන', 'මිතුරෙකු සමඟ කළ දෙයක් ගැන', 'මිතුරන්ට උදව් කිරීම ගැන', 'කණ්ඩායමක් ගැන', 'අලුත් මිතුරෙකු ගැන'],
  technology: ['තාක්ෂණය ගැන', 'ඔබ භාවිත කරන උපකරණයක් ගැන', 'දුරකථනයක් හෝ පරිගණකයක් ගැන', 'තාක්ෂණයෙන් කළ හැකි දෙයක් ගැන', 'අනාගත උපකරණයක් ගැන'],
  festivals: ['උත්සව ගැන', 'ඔබ කැමති උත්සවයක් ගැන', 'උත්සවයකදී කරන දෙයක් ගැන', 'විශේෂ දිනයක් ගැන', 'උත්සවයක් සූදානම් කිරීම ගැන'],
  occupations: ['රැකියා ගැන', 'ඔබ දන්නා රැකියාවක් ගැන', 'අන් අයට උදව් කරන රැකියාවක් ගැන', 'ඔබ කැමති වෘත්තියක් ගැන', 'අනාගත රැකියාවක් ගැන'],
  sea: ['මුහුද ගැන', 'මුහුදු වෙරළ ගැන', 'මුහුදු සතෙකු ගැන', 'වෙරළේ කරන දෙයක් ගැන', 'මුහුද රැකීම ගැන'],
  books: ['පොත් ගැන', 'ඔබ කියවූ පොතක් ගැන', 'පුස්තකාලයක් ගැන', 'කැමති චරිතයක් ගැන', 'අලුත් පොතක් ගැන'],
  health: ['සෞඛ්‍යය ගැන', 'සෞඛ්‍ය සම්පන්න පුරුද්දක් ගැන', 'ව්‍යායාම ගැන', 'විවේක ගැන', 'ශරීරය රැකබලා ගැනීම ගැන'],
  community: ['අපේ ප්‍රදේශය ගැන', 'ඔබ කැමති ස්ථානයක් ගැන', 'අසල්වැසියන්ට උදව් කිරීම ගැන', 'ප්‍රදේශයේ උත්සවයක් ගැන', 'අපේ පරිසරය ගැන'],
};
const suffixes = ['කවුද එහි සිටියේ?', 'ඔබට එය දැනුණේ කොහොමද?', 'ඊළඟට මොකද වුණේ?'];
const englishCategories = {
  animals: 'animals', sports: 'sports', games: 'games and toys', school: 'school', family: 'your family', food: 'food',
  art: 'art and drawing', music: 'music', nature: 'nature', travel: 'a trip or place', vehicles: 'vehicles', stories: 'stories',
  friends: 'friends', technology: 'technology', festivals: 'a festival', occupations: 'jobs', sea: 'the sea', books: 'books',
  health: 'health and wellbeing', community: 'your community',
};
const rows = [];
for (const ageBand of ['5-10', '11-14']) for (const [category, prompts] of Object.entries(categories)) {
  prompts.forEach((prompt, index) => rows.push({ topicId: `c4_${ageBand.replace('-', '_')}_${category}_${index + 1}`, ageBand, category,
    prompt_si: `${prompt} කියන්න.`, prompt_en: `Tell me about ${englishCategories[category]}.`,
    followUps_si: suffixes.slice(0, index === 4 ? 2 : 3), level: index < 3 ? 'concrete' : 'open', approvalStatus: 'unreviewed' }));
}

async function main() {
  if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI is required');
  await mongoose.connect(process.env.MONGODB_URI);
  const ops = rows.map(row => ({ updateOne: { filter: { topicId: row.topicId }, update: { $setOnInsert: row }, upsert: true } }));
  const result = await Topic.bulkWrite(ops, { ordered: false });
  console.log(`C4 topic seed complete: ${rows.length} defined, ${result.upsertedCount} inserted; existing topics preserved.`);
  await mongoose.disconnect();
}
main().catch(async error => { console.error(error.message); await mongoose.disconnect(); process.exitCode = 1; });
