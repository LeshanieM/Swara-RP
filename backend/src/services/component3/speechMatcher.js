/** Conservative Sinhala text matching for structured C3 expected-word prompts. */
const normalizeSinhala = (value) => String(value || '')
  .normalize('NFC')
  .toLocaleLowerCase('si-LK')
  .replace(/[\u200B-\u200D\uFEFF]/g, '')
  .replace(/[\p{P}\p{S}]/gu, ' ')
  .replace(/\s+/g, ' ')
  .trim();

const distance = (a, b) => {
  const row = Array.from({ length: a.length + 1 }, (_, i) => i);
  for (let j = 1; j <= b.length; j += 1) {
    let diagonal = row[0]; row[0] = j;
    for (let i = 1; i <= a.length; i += 1) {
      const previous = row[i];
      row[i] = Math.min(row[i] + 1, row[i - 1] + 1, diagonal + (a[i - 1] === b[j - 1] ? 0 : 1));
      diagonal = previous;
    }
  }
  return row[a.length];
};

const verifyExpectedAnswer = ({ transcript, expectedAnswers, confidence }) => {
  const recognized = normalizeSinhala(transcript);
  const expected = (expectedAnswers || []).map(normalizeSinhala).filter(Boolean);
  if (!recognized || confidence == null || confidence < 0.45) {
    return { status: 'could_not_recognize', normalizedTranscript: recognized, matchedExpectedAnswer: null, similarity: null };
  }
  if (!expected.length) return { status: 'not_applicable', normalizedTranscript: recognized, matchedExpectedAnswer: null, similarity: null };
  const candidates = expected.map((answer) => ({ answer, score: 1 - distance(recognized, answer) / Math.max(recognized.length, answer.length) }));
  const best = candidates.sort((a, b) => b.score - a.score)[0];
  const matched = best.score >= 0.84 || expected.some((answer) => recognized.includes(answer));
  return { status: matched ? 'match' : 'mismatch', normalizedTranscript: recognized, matchedExpectedAnswer: matched ? best.answer : null, similarity: Number(best.score.toFixed(3)) };
};

module.exports = { normalizeSinhala, verifyExpectedAnswer };
