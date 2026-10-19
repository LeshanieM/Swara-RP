const normalizeSinhala = value => String(value || '').normalize('NFC').replace(/[\u200B\uFEFF]/g, '').replace(/\s+/g, ' ').trim();
const words = value => normalizeSinhala(value).match(/[\p{L}\p{M}\p{N}]+(?:['’][\p{L}\p{M}]+)*/gu) || [];

function mattr(tokens, windowSize = 10) {
  if (!tokens.length) return { value: null, windowSize, windows: 0 };
  if (tokens.length < windowSize) return { value: new Set(tokens).size / tokens.length, windowSize, windows: 1, short: true };
  let total = 0;
  for (let i = 0; i <= tokens.length - windowSize; i++) total += new Set(tokens.slice(i, i + windowSize)).size / windowSize;
  return { value: total / (tokens.length - windowSize + 1), windowSize, windows: tokens.length - windowSize + 1 };
}

function analyzeTranscript(transcript, previousVocabulary = [], baselineReady = false) {
  const original = String(transcript || '');
  const normalized = normalizeSinhala(original);
  const tokens = words(normalized);
  const utterances = normalized ? normalized.split(/(?<=[.!?।])\s+|\n+/u).map((text, i) => ({ utteranceId: `u${i + 1}`, text, wordCount: words(text).length, start: null, end: null, syllableCount: null, complexityProxy: words(text).length, c1EventOverlap: null, c1EventTypes: [] })).filter(u => u.wordCount) : [];
  const vocabulary = new Set(previousVocabulary.map(w => normalizeSinhala(w).toLocaleLowerCase()));
  const observedNewWords = [...new Set(tokens.map(w => w.toLocaleLowerCase()).filter(w => !vocabulary.has(w)))];
  const newWords = baselineReady ? observedNewWords : [];
  const first50 = tokens.slice(0, 50).map(w => w.toLocaleLowerCase());
  return { originalTranscript: original, normalizedTranscript: normalized, utterances,
    measures: { wordCount: tokens.length, utteranceCount: utterances.length, MLU_words: utterances.length ? tokens.length / utterances.length : null,
      NDW: new Set(first50).size, NDW_observedWords: first50.length, NDW_shortSample: tokens.length < 50,
      MATTR: mattr(tokens.map(w => w.toLocaleLowerCase())), newWords, newWordStatus: baselineReady ? 'eligible' : 'baseline_pending',
      newWordMethod: 'Exact normalized token comparison; first two completed sessions establish a provisional baseline.' },
    reliabilityFlags: tokens.length < 50 || utterances.length < 5 ? ['short_sample'] : [], shortSample: tokens.length < 50 || utterances.length < 5 };
}

module.exports = { normalizeSinhala, words, mattr, analyzeTranscript };
