const express = require('express');
const axios = require('axios');
const multer = require('multer');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

const { auth } = require('../middleware/auth');
const SpeechAssessment = require('../models/SpeechAssessment');
const Child = require('../models/Child');
const VideoAnalysis = require('../models/VideoAnalysis');

const router = express.Router();

// Ensure upload directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer storage configuration with 25MB file limit
const upload = multer({
  dest: uploadDir,
  limits: { fileSize: 25 * 1024 * 1024 }, // 25 MB max
  fileFilter: (req, file, cb) => {
    // Accept audio files or common WAV/MP3/M4A/FLAC/AAC mimetypes
    if (file.mimetype.startsWith('audio/') || file.originalname.match(/\.(wav|mp3|m4a|aac|flac|ogg)$/i)) {
      cb(null, true);
    } else {
      cb(new Error('Only audio files (.wav, .mp3, .m4a, .flac) are allowed'));
    }
  }
});

/**
 * GET /api/speech/status
 * Health & configuration check of the speech analysis service
 */
router.get('/status', async (req, res) => {
  const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:8000';
  try {
    const aiResponse = await axios.get(`${aiServiceUrl}/speech/status`, { timeout: 5000 });
    res.json({
      backend: 'online',
      aiServiceUrl,
      aiService: aiResponse.data,
    });
  } catch (err) {
    res.status(503).json({
      backend: 'online',
      aiServiceUrl,
      aiService: 'offline_or_unreachable',
      error: err.message,
    });
  }
});

/**
 * GET /api/speech/compare
 * Returns comparative metrics between XLS-R-300M and wav2vec2-base (Section 3 & Page 1-4)
 */
router.get('/compare', async (req, res) => {
  const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:8000';
  try {
    const aiResponse = await axios.get(`${aiServiceUrl}/speech/compare-models`, { timeout: 5000 });
    res.json(aiResponse.data);
  } catch (err) {
    res.status(502).json({
      message: 'Failed to retrieve model comparison results from AI service',
      error: err.message,
    });
  }
});

router.use(auth);

/**
 * Helper to resolve a Child by MongoDB ObjectId or string childId (e.g. 'CH-001')
 */
async function resolveChild(childIdParam, userId, userRole) {
  if (!childIdParam) return null;

  let query = {};
  if (mongoose.Types.ObjectId.isValid(childIdParam)) {
    query = { _id: childIdParam };
  } else {
    query = { childId: childIdParam };
  }

  // Authorization scoping
  if (userRole === 'parent') {
    query.parentId = userId;
  } else if (userRole === 'therapist') {
    query.therapistId = userId;
  }

  let child = await Child.findOne(query);
  if (!child) {
    // Attempt fallback query without scoping for test/demo accounts if needed
    child = await Child.findOne(
      mongoose.Types.ObjectId.isValid(childIdParam) ? { _id: childIdParam } : { childId: childIdParam }
    );
  }
  return child;
}


/**
 * POST /api/speech/analyze
 * Accepts audio upload, validates age/task, calls FastAPI AI service, and persists results.
 */
router.post('/analyze', upload.single('audio'), async (req, res) => {
  const tempFilePath = req.file ? req.file.path : null;

  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No audio file provided. Please attach a WAV audio recording.' });
    }

    const {
      childId: childIdParam,
      taskType: rawTaskType,
      childAge: rawAge,
      age: altAge,
      extractor,
      transcript,
      referenceText,
      concomitantScore: rawConcomitantScore,
    } = req.body;

    // 1. Resolve Child from Database
    let child = null;
    let resolvedChildId = null;
    let childCode = null;
    let resolvedAge = rawAge ? parseFloat(rawAge) : (altAge ? parseFloat(altAge) : null);

    if (childIdParam) {
      child = await resolveChild(childIdParam, req.user.id, req.user.role);
      if (child) {
        resolvedChildId = child._id;
        childCode = child.childId;
        if (!resolvedAge && child.age) {
          resolvedAge = child.age;
        }
      }
    }

    if (!resolvedAge) {
      resolvedAge = 7.0; // Default age if not provided
    }

    // 2. Validate Age and Task Type per Section 2
    let taskType = rawTaskType || (resolvedAge <= 10 ? 'picture-description' : 'passage-reading');
    
    // Normalize taskType naming
    if (taskType.toLowerCase().includes('picture')) {
      taskType = 'picture-description';
    } else if (taskType.toLowerCase().includes('read') || taskType.toLowerCase().includes('passage')) {
      taskType = 'passage-reading';
    }

    if (taskType === 'picture-description' && (resolvedAge < 5 || resolvedAge > 10)) {
      return res.status(400).json({
        message: `Task 'picture-description' is designed for ages 5–10, but received age ${resolvedAge}.`,
        suggestedTask: 'passage-reading',
      });
    }

    if (taskType === 'passage-reading' && (resolvedAge < 11 || resolvedAge > 14)) {
      return res.status(400).json({
        message: `Task 'passage-reading' is designed for ages 11–14, but received age ${resolvedAge}.`,
        suggestedTask: 'picture-description',
      });
    }

    // Resolve optional C2 concomitant behavior score from request or latest VideoAnalysis
    let concomitantScore = rawConcomitantScore !== undefined && rawConcomitantScore !== null
      ? parseFloat(rawConcomitantScore)
      : null;

    if (concomitantScore === null && resolvedChildId) {
      try {
        const latestVideo = await VideoAnalysis.findOne({ childId: resolvedChildId.toString() }).sort({ createdAt: -1 });
        if (latestVideo && latestVideo.results && latestVideo.results.hasSecondaryBehaviors) {
          concomitantScore = latestVideo.results.secondaryBehaviorScore || 0.7;
        }
      } catch (c2Err) {
        console.warn('Could not query C2 VideoAnalysis for concomitant score:', c2Err.message);
      }
    }

    // 3. Prepare FormData for Python AI Service
    const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:8000';
    const formData = new FormData();
    formData.append('audio', fs.createReadStream(tempFilePath), {
      filename: req.file.originalname || 'recording.wav',
      contentType: req.file.mimetype || 'audio/wav',
    });
    formData.append('childAge', resolvedAge.toString());
    formData.append('taskType', taskType);
    if (resolvedChildId) {
      formData.append('childId', resolvedChildId.toString());
    }
    if (extractor) {
      formData.append('extractor', extractor);
    }
    if (transcript) {
      formData.append('transcript', transcript);
    }
    if (referenceText) {
      formData.append('referenceText', referenceText);
    }
    if (concomitantScore !== null && !isNaN(concomitantScore)) {
      formData.append('concomitantScore', concomitantScore.toString());
    }

    // 4. Send to FastAPI AI Service
    let aiResult;
    try {
      const aiResponse = await axios.post(`${aiServiceUrl}/analyze-speech`, formData, {
        headers: formData.getHeaders(),
        maxContentLength: Infinity,
        maxBodyLength: Infinity,
        timeout: 60000, // 60s timeout for ML inference
      });
      aiResult = aiResponse.data;
    } catch (aiErr) {
      console.error('AI Service call failed:', aiErr.response?.data || aiErr.message);
      const detail = aiErr.response?.data?.detail || aiErr.message;
      return res.status(aiErr.response?.status || 502).json({
        message: 'Speech analysis service failed to process audio',
        error: detail,
      });
    }

    // 5. Build and save SpeechAssessment in MongoDB
    // Normalize stutterType for backward compatibility with C2 and C3
    let legacyStutterType = aiResult.stutterType || 'None';
    if (legacyStutterType === 'Sound Repetition' || legacyStutterType === 'Word Repetition') {
      legacyStutterType = 'Repetition';
    }

    const assessmentDoc = {
      childId: resolvedChildId || new mongoose.Types.ObjectId(),
      childCode: childCode || (childIdParam || 'ANON'),
      recordedBy: req.user ? req.user.id : null,
      taskType: taskType,
      childAge: resolvedAge,
      stutterDetected: Boolean(aiResult.stutterDetected),
      stutterType: legacyStutterType,
      severity: aiResult.severity || 'None',
      clinicalStatus: aiResult.clinicalStatus || 'No / very mild stuttering detected',
      severityEstimateType: aiResult.severityEstimateType || 'SSI-4-inspired audio-based severity estimate',
      concomitantScore: aiResult.concomitantScore || concomitantScore,
      confidence: aiResult.confidence || 0,
      detectedEvents: aiResult.detectedEvents || [],
      eventCounts: aiResult.eventCounts || {},
      syllableMetrics: aiResult.syllableMetrics || {},
      durationMetrics: aiResult.durationMetrics || {},
      features: aiResult.features || {},
      analysisId: aiResult.analysisId,
      analysisStatus: aiResult.processingStatus || 'completed',
      modelInfo: aiResult.modelInfo || {},
      warnings: aiResult.warnings || [],
      clinicalDisclaimer: aiResult.clinicalDisclaimer,
      isPrototype: Boolean(aiResult.isPrototype),
    };

    let savedAssessment = null;
    if (mongoose.connection.readyState === 1) {
      if (!resolvedChildId && childIdParam) {
        // Ensure child profile exists in database for this identifier
        let existingChild = await Child.findOne({ childId: childIdParam });
        if (!existingChild) {
          existingChild = new Child({
            childId: childIdParam,
            firstName: 'Child ' + childIdParam,
            age: resolvedAge,
            parentId: req.user ? req.user.id : null,
            severity: aiResult.severity || 'Mild',
            stutterType: legacyStutterType,
          });
          try {
            await existingChild.save();
          } catch (createChildErr) {
            console.warn('Could not auto-create Child document:', createChildErr.message);
          }
        }
        if (existingChild) {
          child = existingChild;
          resolvedChildId = existingChild._id;
          childCode = existingChild.childId;
          assessmentDoc.childId = resolvedChildId;
          assessmentDoc.childCode = childCode;
        }
      }

      const assessment = new SpeechAssessment(assessmentDoc);
      savedAssessment = await assessment.save();

      // Update Child summary profile with latest assessment metrics
      if (child && savedAssessment.severity && savedAssessment.severity !== 'Unavailable') {
        child.severity = savedAssessment.severity;
        if (savedAssessment.stutterType && savedAssessment.stutterType !== 'None') {
          child.stutterType = savedAssessment.stutterType;
        }
        try {
          await child.save();
        } catch (updateChildErr) {
          console.warn('Could not update Child document:', updateChildErr.message);
        }
      }
    }

    // Return structured payload matching Flutter and C2/C3 requirements
    const responsePayload = savedAssessment ? savedAssessment.toObject() : assessmentDoc;
    res.status(201).json(responsePayload);

  } catch (err) {
    console.error('Speech analysis route error:', err);
    res.status(500).json({ message: 'Internal server error during speech analysis', error: err.message });
  } finally {
    // Privacy and cleanup: delete local temporary upload file
    if (tempFilePath && fs.existsSync(tempFilePath)) {
      try {
        fs.unlinkSync(tempFilePath);
      } catch (cleanupErr) {
        console.error('Failed to cleanup temp audio file:', cleanupErr.message);
      }
    }
  }
});

/**
 * GET /api/speech/:childId
 * Retrieves speech assessment history for a child (sorted newest first)
 */
router.get('/:childId', async (req, res) => {
  try {
    const { childId: param } = req.params;
    
    // Find child first to get ObjectId
    let query = {};
    if (mongoose.Types.ObjectId.isValid(param)) {
      query = { $or: [{ childId: param }, { _id: param }] };
    }

    const child = await Child.findOne(
      mongoose.Types.ObjectId.isValid(param) ? { _id: param } : { childId: param }
    );

    let filter = {};
    if (child) {
      filter = { $or: [{ childId: child._id }, { childCode: child.childId || child._id.toString() }] };
    } else if (mongoose.Types.ObjectId.isValid(param)) {
      filter = { $or: [{ childId: param }, { childCode: param }] };
    } else {
      filter = { childCode: param };
    }

    const history = await SpeechAssessment.find(filter).sort({ createdAt: -1 });
    res.json(history);
  } catch (err) {
    console.error('Error fetching speech history:', err);
    res.status(500).json({ message: 'Failed to fetch speech history', error: err.message });
  }
});

/**
 * GET /api/speech/assessment/:id
 * Retrieves a single speech assessment by its ObjectId
 */
router.get('/assessment/:id', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid assessment ID format' });
    }

    const assessment = await SpeechAssessment.findById(req.params.id)
      .populate('childId', 'firstName age gender severity stutterType childId');

    if (!assessment) {
      return res.status(404).json({ message: 'Speech assessment not found' });
    }

    res.json(assessment);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch assessment details', error: err.message });
  }
});

module.exports = router;
