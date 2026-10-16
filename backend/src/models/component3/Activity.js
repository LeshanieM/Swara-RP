const mongoose = require('mongoose');

/**
 * C3 Therapy Activity Pool — Level 1 actions (type × difficulty combinations).
 *
 * ageBand:      Strict eligibility filter. '5-10' or '11-14'.
 * difficulty:   'easy' | 'moderate' | 'difficult'
 * activityType: Internal identifier used by the recommender and Flutter route mapping.
 * slpApproved:  Only approved activities can be recommended. Default false for new seeds
 *               so they require explicit sign-off before exposure.
 * active:       Soft-delete flag.
 * linucbActionId: Stable string identifier used as the LinUCB arm key. Must match the
 *               id field in the Dart _therapyActivities list for cross-system consistency.
 *               If null, the activity is backend-only and not surfaced to the recommender.
 */
const activitySchema = new mongoose.Schema({
  // --- identifiers ---
  activityId:     { type: String, unique: true, required: true },
  linucbActionId: { type: String, index: true, sparse: true }, // matches Dart activity id

  // --- content ---
  name:        { type: String, required: true },
  description: { type: String },

  // --- classification ---
  activityType: {
    type: String,
    required: true,
    enum: [
      'breathing_relaxation',
      'syllable_practice',
      'word_phrase_practice',
      'reading_aloud',
      'picture_description',
      'sentence_building',
      'storytelling',
      'guided_conversation',
      'role_play',
      'show_and_tell',
      'easy_onset_practice',
      'slow_speech_practice',
    ],
  },
  // Strict eligibility filter — not a preference.
  ageBand: {
    type: String,
    required: true,
    enum: ['5-10', '11-14'],
  },
  difficulty: {
    type: String,
    required: true,
    enum: ['easy', 'moderate', 'difficult'],
  },

  // --- clinical metadata ---
  technique:          { type: String },  // e.g. 'Easy Onset', 'Pausing/Phrasing'
  targetSkill:        { type: String },  // e.g. 'fluency', 'articulation', 'rate_control'
  therapeuticPurpose: { type: String },
  suggestedDurationMinutes: { type: Number, default: 5 },

  // --- success criteria (used for performance score P = S/T × C) ---
  // Describes what counts as one 'successful opportunity' for this activity type.
  targetDefinition: { type: String },
  // Describes what counts as one 'eligible target opportunity'.
  targetType: { type: String },

  // --- SLP review ---
  slpApproved: { type: Boolean, default: false },
  slpNotes:    { type: String },

  // --- content reference ---
  // For activities with content items (pictures, passages), stores the content
  // set identifier used by the Flutter app to retrieve items from local assets
  // or a future content API.
  contentSetId: { type: String },

  // --- instructions ---
  instructions: { type: String },
  materials:    { type: String },
  prerequisites: [{ type: String }],

  // --- lifecycle ---
  active: { type: Boolean, default: true },
}, { timestamps: true });

// Prevent A12 (Open Topic Talk) from being stored in this collection at the
// DB level — it belongs to Component 4.
activitySchema.pre('save', function (next) {
  if (this.activityType === 'open_topic_talk') {
    return next(new Error(
      'Open Topic Talk belongs to Component 4 and must not be added to the C3 activity pool.'
    ));
  }
  next();
});

module.exports = mongoose.models.Activity
  || mongoose.model('Activity', activitySchema);
