const express = require('express');
const axios = require('axios');
const multer = require('multer');
const FormData = require('form-data');
const { auth } = require('../middleware/auth');
const SpeechAssessment = require('../models/SpeechAssessment');
const Child = require('../models/Child');
const fs = require('fs');

const router = express.Router();
const upload = multer({ dest: 'uploads/' });

router.use(auth);

router.post('/analyze', upload.single('audio'), async (req, res) => {
  try {
    // In a real scenario, we would send the file to the Python service
    // const formData = new FormData();
    // formData.append('audio', fs.createReadStream(req.file.path));
    // const aiResponse = await axios.post(`${process.env.AI_SERVICE_URL}/analyze-speech`, formData, {
    //   headers: formData.getHeaders()
    // });
    // const result = aiResponse.data;

    // For prototype, we'll return mock data if AI service isn't reachable or for demonstration
    // We would normally save this to the DB.
    
    const mockResult = {
      stutterDetected: true,
      stutterType: "Repetition",
      severity: "Moderate",
      confidence: 0.82,
      features: {
        duration: 32,
        pauseCount: 14,
        averagePauseDuration: 0.82,
        speechRate: 2.1
      },
      isPrototype: true
    };

    if (req.body.childId) {
        // Save assessment if childId is provided
    }

    res.json(mockResult);
  } catch (err) {
    res.status(500).json({ message: 'Speech analysis failed', error: err.message });
  }
});

router.get('/:childId', async (req, res) => {
    try {
        const history = await SpeechAssessment.find({ childId: req.params.childId }).sort({ createdAt: -1 });
        res.json(history);
    } catch(err) {
        res.status(500).json({ message: 'Failed to fetch speech history' });
    }
});

module.exports = router;
