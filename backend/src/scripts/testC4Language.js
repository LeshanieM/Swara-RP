const assert = require('assert');
const { normalizeSinhala, words, mattr, analyzeTranscript } = require('../services/component4/languageMeasures');

assert.equal(normalizeSinhala('අ  බ‍'), 'අ බ‍');
assert.deepEqual(words('මම මම අම්මේ...'), ['මම', 'මම', 'අම්මේ']);
const measures = analyzeTranscript('මම ගෙදර ගියා. මම සෙල්ලම් කළා.');
assert.equal(measures.measures.MLU_words, 3);
assert.equal(measures.measures.NDW, 5);
assert.equal(measures.shortSample, true);
assert.deepEqual(analyzeTranscript('අලුත් වචන', [], false).measures.newWords, []);
assert.deepEqual(analyzeTranscript('මම අලුත්', ['මම'], true).measures.newWords, ['අලුත්']);
const first50 = Array.from({ length: 51 }, (_, i) => `වචනය${i + 1}`).join(' ');
assert.equal(analyzeTranscript(first50).measures.NDW, 50);
assert.equal(mattr([], 10).value, null);
assert.equal(mattr(['අ', 'අ'], 10).value, 0.5);
console.log('C4 language utility checks passed');
