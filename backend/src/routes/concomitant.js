const express = require('express');
const router = express.Router();
const ConcomitantAssessment = require('../models/ConcomitantAssessment');
const SpeechAssessment = require('../models/SpeechAssessment');
const { auth } = require('../middleware/auth');

// POST /api/concomitant/sessions - Analyze new assessment (MOCK AI SERVICE)
router.post('/sessions', auth, async (req, res) => {
  try {
    const { childId, speechAssessmentId, taskType, duration, audioUrl, videoUrl } = req.body;

    // Simulate calling the Python AI Service / Vision + Audio Pipeline
    const mockPhysicalConcomitants = {
      facialTension: { score: 2, candidateEvents: 5, confidence: 0.82 },
      eyeMovements: { score: 1, candidateEvents: 3, confidence: 0.74 },
      headMovements: { score: 0, candidateEvents: 0, confidence: 0.95 },
      extremityMovements: { score: 1, candidateEvents: 2, confidence: 0.68 }
    };

    const mockVocalAvoidance = {
      responseLatency: {
        baseline: 0.5,
        elevated: true,
        timestamps: [1.2, 18.1]
      },
      wordSubstitution: [
        { originalWord: 'dog', detectedAlternative: 'puppy', confidence: 0.75, timestamp: 14.5 }
      ],
      circumlocution: [
        { utterance: 'the animal that barks', confidence: 0.81, timestamp: 32.1 }
      ],
      acousticTension: { summary: 'Slight elevation in pitch', candidateTimestamps: [14.0, 31.5], confidence: 0.72 }
    };

    const mockTimeline = [
      { timestamp: 14.0, eventType: 'Primary Stutter (Component 1)', source: 'Component 1', details: 'Repetition', confidence: 0.9 },
      { timestamp: 14.1, eventType: 'Facial Tension', source: 'Component 2', details: 'Mouth region movement', confidence: 0.82 },
      { timestamp: 14.5, eventType: 'Possible Word Substitution', source: 'Component 2', details: 'dog -> puppy', confidence: 0.75 },
      { timestamp: 31.2, eventType: 'Primary Stutter (Component 1)', source: 'Component 1', details: 'Prolongation', confidence: 0.88 },
      { timestamp: 31.5, eventType: 'Eye Blink', source: 'Component 2', details: 'Rapid blinking', confidence: 0.74 },
      { timestamp: 32.1, eventType: 'Possible Circumlocution', source: 'Component 2', details: 'the animal that barks', confidence: 0.81 }
    ];

    const assessment = new ConcomitantAssessment({
      childId,
      speechAssessmentId,
      taskType,
      duration,
      audioUrl,
      videoUrl,
      analysisStatus: 'completed',
      physicalConcomitants: mockPhysicalConcomitants,
      vocalAvoidanceIndicators: mockVocalAvoidance,
      eventTimeline: mockTimeline,
      modelConfidence: 0.8,
      isPrototype: true,
      clinicianVerification: { status: 'Pending' }
    });

    await assessment.save();

    res.status(201).json(assessment);
  } catch (error) {
    console.error('Error creating concomitant assessment:', error);
    res.status(500).json({ message: 'Server error during assessment generation' });
  }
});

// GET /api/concomitant/history/:childId
router.get('/history/:childId', auth, async (req, res) => {
  try {
    const assessments = await ConcomitantAssessment.find({ childId: req.params.childId })
      .sort({ createdAt: -1 });
    res.json(assessments);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// GET /api/concomitant/results/:id
router.get('/results/:id', auth, async (req, res) => {
  try {
    const assessment = await ConcomitantAssessment.findById(req.params.id)
      .populate('childId')
      .populate('speechAssessmentId');
      
    if (!assessment) {
      return res.status(404).json({ message: 'Assessment not found' });
    }
    res.json(assessment);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// PATCH /api/concomitant/results/:id/verify
router.patch('/results/:id/verify', auth, async (req, res) => {
  try {
    const { status, notes } = req.body;
    
    const assessment = await ConcomitantAssessment.findById(req.params.id);
    if (!assessment) {
      return res.status(404).json({ message: 'Assessment not found' });
    }

    assessment.clinicianVerification = {
      status,
      notes,
      verifiedAt: new Date(),
      verifiedBy: req.user.id
    };

    await assessment.save();
    res.json(assessment);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
