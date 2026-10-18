const Activity = require('../../models/component3/Activity');

// Core 5 clinical speech therapy activities
const CORE_ACTIVITIES = [
  {
    linucbActionId: 'breathing-body-awareness',
    activityId: 'act_c3_breathing',
    name: 'Breathing and Body Awareness',
    description: 'Diaphragmatic breathing and muscle tension release before speech.',
    activityType: 'breathing_relaxation',
    technique: 'Diaphragmatic Breathing & Muscle Relaxation',
    targetSkill: 'respiratory_control',
    therapeuticPurpose: 'Release body tension and regulate breathing rhythm for speech preparation.',
    suggestedDurationMinutes: 3,
    targetDefinition: 'Completed breathing cycles and body relaxation check-ins',
    targetType: 'breathing_cycle',
    difficulty: 'easy',
    slpApproved: true,
    active: true,
  },
  {
    linucbActionId: 'syllable-practice',
    activityId: 'act_c3_syllable',
    name: 'Syllable Practice',
    description: 'Calm syllable segmentation and smooth phonation practice.',
    activityType: 'syllable_practice',
    technique: 'Easy Onset & Syllable Prolongation',
    targetSkill: 'articulation',
    therapeuticPurpose: 'Build words one smooth syllable at a time with gentle vowel onset.',
    suggestedDurationMinutes: 5,
    targetDefinition: 'Fluent syllable pronunciation without block or repetition',
    targetType: 'syllable_target',
    difficulty: 'easy',
    slpApproved: true,
    active: true,
  },
  {
    linucbActionId: 'word-phrase-practice',
    activityId: 'act_c3_word_phrase',
    name: 'Word and Phrase Practice',
    description: 'Gradual expansion from single words to short connected phrases.',
    activityType: 'word_phrase_practice',
    technique: 'Pausing & Phrasing',
    targetSkill: 'fluency',
    therapeuticPurpose: 'Maintain smooth speech transitions from isolated words to multi-word phrases.',
    suggestedDurationMinutes: 5,
    targetDefinition: 'Smooth phrase completion with easy onset and natural pause',
    targetType: 'phrase_target',
    difficulty: 'moderate',
    slpApproved: true,
    active: true,
  },
  {
    linucbActionId: 'picture-description',
    activityId: 'act_c3_picture',
    name: 'Picture Description',
    description: 'Describing visual scene cues using short fluent phrases.',
    activityType: 'picture_description',
    technique: 'Continuous Phonation & Pacing',
    targetSkill: 'fluency',
    therapeuticPurpose: 'Practice expressive language and descriptive fluency using engaging scene stimuli.',
    suggestedDurationMinutes: 5,
    targetDefinition: 'Spontaneous descriptive response with fluent utterance initiation',
    targetType: 'description_utterance',
    difficulty: 'moderate',
    slpApproved: true,
    active: true,
  },
  {
    linucbActionId: 'guided-conversation',
    activityId: 'act_c3_conversation',
    name: 'Guided Conversation',
    description: 'Interactive conversational dialogue with prompt support.',
    activityType: 'guided_conversation',
    technique: 'Turn-taking & Rhythmic Pacing',
    targetSkill: 'conversational_fluency',
    therapeuticPurpose: 'Foster confidence and natural speech timing during interactive dialogues.',
    suggestedDurationMinutes: 6,
    targetDefinition: 'Conversational response delivered with controlled rate and confidence',
    targetType: 'conversation_turn',
    difficulty: 'difficult',
    slpApproved: true,
    active: true,
  },
];

/**
 * GET /api/c3/activities
 * List all active, SLP-approved activities
 */
const getActivities = async (req, res) => {
  try {
    const filter = { active: true };
    if (req.query.ageBand) filter.ageBand = req.query.ageBand;
    if (req.query.slpApproved !== undefined) filter.slpApproved = req.query.slpApproved === 'true';
    if (req.query.activityType) filter.activityType = req.query.activityType;

    const activities = await Activity.find(filter).sort({ difficulty: 1, name: 1 });
    res.json({ success: true, count: activities.length, data: activities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/c3/activities/:id
 */
const getActivityById = async (req, res) => {
  try {
    const { id } = req.params;
    const activity = await Activity.findOne({
      $or: [{ activityId: id }, { linucbActionId: id }],
      active: true,
    });
    if (!activity) {
      return res.status(404).json({ success: false, message: 'Activity not found' });
    }
    res.json({ success: true, data: activity });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * POST /api/c3/activities/seed
 * Seed / reset the 5 necessary activities for 5-10 and 11-14 age bands
 */
const seedActivities = async (req, res) => {
  try {
    const ageBands = ['5-10', '11-14'];
    const docs = [];

    for (const band of ageBands) {
      for (const act of CORE_ACTIVITIES) {
        docs.push({
          ...act,
          activityId: `${act.activityId}_${band.replace('-', '_')}`,
          ageBand: band,
        });
      }
    }

    // Upsert each activity
    const results = [];
    for (const doc of docs) {
      const updated = await Activity.findOneAndUpdate(
        { activityId: doc.activityId },
        doc,
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
      results.push(updated);
    }

    res.json({
      success: true,
      message: `Successfully seeded ${results.length} activities (5 core activities × 2 age bands)`,
      data: results,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  CORE_ACTIVITIES,
  getActivities,
  getActivityById,
  seedActivities,
};
