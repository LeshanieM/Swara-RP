const assert = require('node:assert/strict');
const { normalizeSinhala, verifyExpectedAnswer } = require('../src/services/component3/speechMatcher');

assert.equal(normalizeSinhala('  මල!\u200B '), 'මල');

const exact = verifyExpectedAnswer({
  transcript: 'මල', expectedAnswers: ['මල'], confidence: 0.90,
});
assert.equal(exact.status, 'match');

const phrase = verifyExpectedAnswer({
  transcript: 'මම ලස්සන මල කියනවා', expectedAnswers: ['ලස්සන මල'], confidence: 0.90,
});
assert.equal(phrase.status, 'match');

const uncertain = verifyExpectedAnswer({
  transcript: 'මල', expectedAnswers: ['මල'], confidence: 0.10,
});
assert.equal(uncertain.status, 'could_not_recognize');

console.log('speechMatcher tests passed');
