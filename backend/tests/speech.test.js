/**
 * Automated test suite for Swara Backend Component 1:
 * Speech Assessment routes, validation, and Mongoose schema models.
 */

const { test, describe, before } = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

const SpeechAssessment = require('../src/models/SpeechAssessment');
const Child = require('../src/models/Child');

describe('Component 1: Speech Assessment Model & Schema Tests', () => {
  test('SpeechAssessment schema should validate required fields and defaults', () => {
    const mockChildId = new mongoose.Types.ObjectId();
    const assessment = new SpeechAssessment({
      childId: mockChildId,
      stutterDetected: true,
      stutterType: 'Repetition',
      severity: 'Moderate',
      confidence: 0.88,
      detectedEvents: [
        { startTime: 1.2, endTime: 3.5, eventType: 'Sound Repetition', confidence: 0.88, duration: 2.3 }
      ],
      eventCounts: {
        blocks: 0,
        prolongations: 0,
        soundRepetitions: 1,
        wordRepetitions: 0,
        interjections: 0,
        total: 1
      },
      syllableMetrics: {
        totalSyllables: 24,
        stutteredSyllables: 3,
        percentSyllablesStuttered: 12.5,
        syllableCountMethod: 'Acoustic Intensity Nucleus Peak Detection',
        isReliable: true
      },
      durationMetrics: {
        totalDuration: 5.0,
        speechDuration: 4.2,
        longestEventDuration: 2.3,
        averageEventDuration: 2.3
      },
      features: {
        duration: 5.0,
        pauseCount: 2,
        averagePauseDuration: 0.4,
        speechRate: 4.8,
        estimatedWordCount: 11
      },
      analysisStatus: 'completed',
      clinicalStatus: 'Moderate stuttering detected',
      severityEstimateType: 'SSI-4-inspired audio-based severity estimate',
      concomitantScore: 0.65,
    });

    assert.strictEqual(assessment.stutterDetected, true);
    assert.strictEqual(assessment.stutterType, 'Repetition');
    assert.strictEqual(assessment.severity, 'Moderate');
    assert.strictEqual(assessment.clinicalStatus, 'Moderate stuttering detected');
    assert.strictEqual(assessment.severityEstimateType, 'SSI-4-inspired audio-based severity estimate');
    assert.strictEqual(assessment.concomitantScore, 0.65);
    assert.strictEqual(assessment.detectedEvents.length, 1);
    assert.strictEqual(assessment.detectedEvents[0].duration, 2.3);
    assert.strictEqual(assessment.syllableMetrics.percentSyllablesStuttered, 12.5);
    assert.strictEqual(assessment.durationMetrics.longestEventDuration, 2.3);
    assert.strictEqual(assessment.features.pauseCount, 2);
    assert.strictEqual(assessment.isPrototype, false);
  });

  test('SpeechAssessment should enforce required childId and stutterDetected', () => {
    const invalidDoc = new SpeechAssessment({});
    const validationError = invalidDoc.validateSync();
    assert.ok(validationError, 'Validation error expected');
    assert.ok(validationError.errors['childId'], 'childId should be required');
    assert.ok(validationError.errors['stutterDetected'], 'stutterDetected should be required');
  });

  test('SpeechAssessment should accept backward-compatible severity levels for Component 3', () => {
    const mockId = new mongoose.Types.ObjectId();
    const severities = ['Mild', 'Moderate', 'Severe', 'None', 'Unavailable'];

    for (const sev of severities) {
      const doc = new SpeechAssessment({
        childId: mockId,
        stutterDetected: sev !== 'None',
        severity: sev,
      });
      const err = doc.validateSync();
      assert.strictEqual(err, undefined, `Severity level ${sev} should be valid`);
    }
  });
});

describe('Component 1: JWT Auth and Scoping', () => {
  const secret = process.env.JWT_SECRET || 'swara_research_jwt_secret_change_in_production';

  test('Valid JWT token encodes and decodes user context', () => {
    const payload = { id: 'user_123', role: 'parent' };
    const token = jwt.sign(payload, secret, { expiresIn: '1h' });
    const decoded = jwt.verify(token, secret);

    assert.strictEqual(decoded.id, 'user_123');
    assert.strictEqual(decoded.role, 'parent');
  });
});
