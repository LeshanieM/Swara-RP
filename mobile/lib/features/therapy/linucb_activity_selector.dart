part of 'therapy_ui.dart';

// ============================================================================
// Level 1 Arm Definition: (Activity Type × Difficulty)
// Filtered strictly by Age Band (5-10 or 11-14)
// ============================================================================
class _LinUcbLevel1Arm {
  final String armId;
  final String activityId;
  final String difficulty; // 'easy' | 'moderate' | 'difficult'
  final String ageBand; // '5-10' | '11-14'
  final String titleSinhala;
  final String titleEnglish;
  final String difficultyLabelSinhala;
  final String targetSkill;
  final int suggestedDurationMinutes;
  final List<_Level2ContentItem> level2Items;

  const _LinUcbLevel1Arm({
    required this.armId,
    required this.activityId,
    required this.difficulty,
    required this.ageBand,
    required this.titleSinhala,
    required this.titleEnglish,
    required this.difficultyLabelSinhala,
    required this.targetSkill,
    this.suggestedDurationMinutes = 4,
    required this.level2Items,
  });

  _TherapyActivityDefinition get baseActivity {
    for (final act in _therapyActivities) {
      if (act.id == activityId) return act;
    }
    return _therapyActivities.first;
  }
}

// ============================================================================
// Level 2 Content Item: The specific stimulus drawn without recent repetition
// ============================================================================
class _Level2ContentItem {
  final String id;
  final String prompt;
  final String hint;
  final List<String> items;

  const _Level2ContentItem({
    required this.id,
    required this.prompt,
    required this.hint,
    this.items = const [],
  });
}

// ============================================================================
// Clinically-Calibrated Level 1 Arms Pool (5-10 and 11-14 Age Bands)
// ============================================================================
final List<_LinUcbLevel1Arm> _allLevel1Arms = [
  // --- Age Band 5-10 ---
  const _LinUcbLevel1Arm(
    armId: 'breathing-body-awareness:easy:5-10',
    activityId: 'breathing-body-awareness',
    difficulty: 'easy',
    ageBand: '5-10',
    titleSinhala: 'හුස්ම ගැනීමේ විවේකය (පහසු)',
    titleEnglish: 'Breathing Pause (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Diaphragmatic Calm & Tension Release',
    suggestedDurationMinutes: 3,
    level2Items: [
      _Level2ContentItem(
        id: 'br_510_e_1',
        prompt: 'සෙමින් හුස්ම ගෙන බැලූනයක් මෙන් පපුව පිම්බෙන්නට ඉඩ දෙන්න.',
        hint: 'Gently breathe in, relax shoulders down',
      ),
      _Level2ContentItem(
        id: 'br_510_e_2',
        prompt: 'මලක් සුවඳ බලනවාක් මෙන් සෙමින් හුස්ම ගෙන, ඉටිපන්දමක් නිවන සේ පිට කරන්න.',
        hint: 'Smell the flower, blow the candle softly',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'breathing-body-awareness:moderate:5-10',
    activityId: 'breathing-body-awareness',
    difficulty: 'moderate',
    ageBand: '5-10',
    titleSinhala: 'කොටු හුස්ම ගැනීමේ රටාව (මධ්‍යස්ථ)',
    titleEnglish: 'Box Breathing Pattern (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Paced Inhalation-Hold-Exhalation Rhythm',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'br_510_m_1',
        prompt: '4 ගණන් කරන තුරු හුස්ම ගන්න, 4ක් රඳවන්න, 4ක් පිට කරන්න.',
        hint: 'Inhale 4s, pause 4s, exhale smoothly',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'syllable-practice:easy:5-10',
    activityId: 'syllable-practice',
    difficulty: 'easy',
    ageBand: '5-10',
    titleSinhala: 'අක්ෂර දෙකේ වචන (පහසු)',
    titleEnglish: '2-Syllable Familiar Words (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Gentle Vowel Onset & Syllable Segmentation',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'syl_510_e_1',
        prompt: 'අම්-මා, ම-ල, පො-ත, ගෙ-දර',
        hint: 'Gentle contact on first consonant, smooth vowel glide',
        items: ['අම්-මා', 'ම-ල', 'පො-ත', 'ගෙ-දර'],
      ),
      _Level2ContentItem(
        id: 'syl_510_e_2',
        prompt: 'පා-ට, අ-ල, බෝ-ල, කිරි',
        hint: 'Soft breath before start, natural pause between syllables',
        items: ['පා-ට', 'අ-ල', 'බෝ-ල', 'කි-රි'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'syllable-practice:moderate:5-10',
    activityId: 'syllable-practice',
    difficulty: 'moderate',
    ageBand: '5-10',
    titleSinhala: 'අක්ෂර තුනේ වචන (මධ්‍යස්ථ)',
    titleEnglish: '3-Syllable Rhythmic Words (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Continuous Phonation Across 3 Syllables',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'syl_510_m_1',
        prompt: 'කැ-රට්, පු-ටු-ව, බෝ-ත-ලය',
        hint: 'Keep air flowing evenly through all three parts',
        items: ['කැ-රට්', 'පු-ටු-ව', 'බෝ-ත-ලය'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'syllable-practice:difficult:5-10',
    activityId: 'syllable-practice',
    difficulty: 'difficult',
    ageBand: '5-10',
    titleSinhala: 'සංකීර්ණ බහු-අක්ෂර වචන (අභියෝගාත්මක)',
    titleEnglish: 'Multisyllabic Blend Words (Challenging)',
    difficultyLabelSinhala: 'අභියෝගාත්මක (Difficult)',
    targetSkill: 'Light Articulatory Contact on Consonant Blends',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'syl_510_d_1',
        prompt: 'ඉස්-කෝ-ලෙ, සම-න-ල-යා, ක්‍රී-ඩා-පි-ටිය',
        hint: 'Easy start on vowels, no tension in tongue or jaw',
        items: ['ඉස්-කෝ-ලෙ', 'සම-න-ල-යා', 'ක්‍රී-ඩා-පි-ටිය'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'word-phrase-practice:easy:5-10',
    activityId: 'word-phrase-practice',
    difficulty: 'easy',
    ageBand: '5-10',
    titleSinhala: 'වචනයෙන් කෙටි වාක්‍ය ඛණ්ඩයට (පහසු)',
    titleEnglish: 'Single Word to Short Phrase (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Word-to-Phrase Expansion with Easy Onset',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'wpp_510_e_1',
        prompt: 'මල ➔ ලස්සන මල',
        hint: 'Pause between word and phrase, maintain gentle start',
        items: ['මල', 'ලස්සන මල'],
      ),
      _Level2ContentItem(
        id: 'wpp_510_e_2',
        prompt: 'බල්ලා ➔ සුදු බල්ලා',
        hint: 'Light breath initiation',
        items: ['බල්ලා', 'සුදු බල්ලා'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'word-phrase-practice:moderate:5-10',
    activityId: 'word-phrase-practice',
    difficulty: 'moderate',
    ageBand: '5-10',
    titleSinhala: 'වාක්‍ය ඛණ්ඩයේ සිට සම්පූර්ණ වාක්‍යයට (මධ්‍යස්ථ)',
    titleEnglish: 'Phrase to Simple Sentence (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Breath-Group Pacing & Sentence Rhythm',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'wpp_510_m_1',
        prompt: 'ලස්සන මල ➔ වත්තේ ලස්සන මලක් තියෙනවා',
        hint: 'Take a gentle breath at the comma, finish calmly',
        items: ['ලස්සන මල', 'වත්තේ ලස්සන මලක් තියෙනවා'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'word-phrase-practice:difficult:5-10',
    activityId: 'word-phrase-practice',
    difficulty: 'difficult',
    ageBand: '5-10',
    titleSinhala: 'සම්බන්ධිත සුමට වාක්‍ය (අභියෝගාත්මක)',
    titleEnglish: 'Connected Carrier Sentences (Challenging)',
    difficultyLabelSinhala: 'අභියෝගාත්මක (Difficult)',
    targetSkill: 'Continuous Phonation Across Multi-Word Utterances',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'wpp_510_d_1',
        prompt: 'මම කැමතියි උදෑසන පාසල් යන්න.',
        hint: 'Gentle start on "මම", keep the voice box vibrating smoothly',
        items: ['මම කැමතියි', 'මම කැමතියි උදෑසන පාසල් යන්න.'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'picture-description:easy:5-10',
    activityId: 'picture-description',
    difficulty: 'easy',
    ageBand: '5-10',
    titleSinhala: 'පින්තූරයේ තනි වස්තූන් නම් කිරීම (පහසු)',
    titleEnglish: 'Object Naming in Scene (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Single Word / Short Phrase Spontaneous Production',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'pic_510_e_1',
        prompt: 'පින්තූරයේ ඔබට පෙනෙන එක් දෙයක් නම් කරන්න (උදා: නිල් බෝලය).',
        hint: 'Take your time before speaking, speak softly',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'picture-description:moderate:5-10',
    activityId: 'picture-description',
    difficulty: 'moderate',
    ageBand: '5-10',
    titleSinhala: 'පින්තූර ක්‍රියාකාරකම් විස්තරය (මධ්‍යස්ථ)',
    titleEnglish: 'Action Description in Scene (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Descriptive Phrase Fluency & Rate Control',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'pic_510_m_1',
        prompt: 'ළමයින් කරන ක්‍රියාව කෙටි වාක්‍යයකින් විස්තර කරන්න.',
        hint: 'Start with calm breath: "ළමයින් පන්දුව සමඟ සෙල්ලම් කරනවා"',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'picture-description:difficult:5-10',
    activityId: 'picture-description',
    difficulty: 'difficult',
    ageBand: '5-10',
    titleSinhala: 'පින්තූර කතන්දරය (අභියෝගාත්මක)',
    titleEnglish: 'Picture Scene Story Narrative (Challenging)',
    difficultyLabelSinhala: 'අභියෝගාත්මක (Difficult)',
    targetSkill: 'Sequential Narrative Fluency with Natural Pauses',
    suggestedDurationMinutes: 6,
    level2Items: [
      _Level2ContentItem(
        id: 'pic_510_d_1',
        prompt: 'පින්තූරයේ සිදුවන සම්පූර්ණ කතාව වාක්‍ය දෙකකින් කියන්න.',
        hint: 'Use natural pauses between ideas',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'guided-conversation:easy:5-10',
    activityId: 'guided-conversation',
    difficulty: 'easy',
    ageBand: '5-10',
    titleSinhala: 'මඟපෙන්වන කෙටි පිළිතුරු (පහසු)',
    titleEnglish: 'Structured Choice Dialogue (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Turn-Taking with Low Communicative Pressure',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'gc_510_e_1',
        prompt: 'ඔබ වැඩිපුරම කැමති පාට මොකක්ද? (නිල් ද, රතු ද, කහ ද?)',
        hint: 'Simple one-turn answer, no pressure',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'guided-conversation:moderate:5-10',
    activityId: 'guided-conversation',
    difficulty: 'moderate',
    ageBand: '5-10',
    titleSinhala: 'විස්තරාත්මක සංවාදය (මධ්‍යස්ථ)',
    titleEnglish: 'Open Narrative Sharing (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Conversational Turn Initiation & Pausing',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'gc_510_m_1',
        prompt: 'ඔබේ ප්‍රියතම සෙල්ලම් බඩුව ගැන මට කියන්න පුළුවන්ද?',
        hint: 'Start with calm breath, express freely',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'guided-conversation:difficult:5-10',
    activityId: 'guided-conversation',
    difficulty: 'difficult',
    ageBand: '5-10',
    titleSinhala: 'අන්තර්ක්‍රියාකාරී ගැටලු විසඳීම (අභියෝගාත්මක)',
    titleEnglish: 'Interactive Scenario Discussion (Challenging)',
    difficultyLabelSinhala: 'අභියෝගාත්මක (Difficult)',
    targetSkill: 'Higher-Cognitive Speech Planning & Fluency',
    suggestedDurationMinutes: 6,
    level2Items: [
      _Level2ContentItem(
        id: 'gc_510_d_1',
        prompt: 'ඔබේ මිතුරෙක් දුකෙන් ඉන්නවා නම්, ඔබ කරන්නේ මොකක්ද?',
        hint: 'Take time to think, speak with smooth rhythm',
      ),
    ],
  ),

  // --- Age Band 11-14 ---
  const _LinUcbLevel1Arm(
    armId: 'breathing-body-awareness:easy:11-14',
    activityId: 'breathing-body-awareness',
    difficulty: 'easy',
    ageBand: '11-14',
    titleSinhala: 'සන්සුන් හුස්ම පාලනය (පහසු)',
    titleEnglish: 'Controlled Diaphragmatic Reset (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Pre-Speech Diaphragmatic Grounding',
    suggestedDurationMinutes: 3,
    level2Items: [
      _Level2ContentItem(
        id: 'br_1114_e_1',
        prompt: 'සන්සුන්ව හුස්ම පාලනය කරමින් කථනයට සූදානම් වන්න.',
        hint: 'Steady abdominal breathing, release neck tension',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'breathing-body-awareness:moderate:11-14',
    activityId: 'breathing-body-awareness',
    difficulty: 'moderate',
    ageBand: '11-14',
    titleSinhala: 'ප්‍රාශ්වාස පාලන අභ්‍යාසය (මධ්‍යස්ථ)',
    titleEnglish: 'Exhalation Phonation Alignment (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Breath-Speech Coordination Under Stress',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'br_1114_m_1',
        prompt: 'ප්‍රාශ්වාසය සමඟ මෘදු ශබ්දයක් එක් කරන්න (උදා: "ම්ම්ම්...").',
        hint: 'Exhale and gently initiate light phonation',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'syllable-practice:easy:11-14',
    activityId: 'syllable-practice',
    difficulty: 'easy',
    ageBand: '11-14',
    titleSinhala: 'වේග පාලන අක්ෂර පුහුණුව (පහසු)',
    titleEnglish: 'Rhythmic Syllable Pacing (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Controlled Articulatory Rate & Syllable Timing',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'syl_1114_e_1',
        prompt: 'වි-ද්‍යාව, පරි-ග-ණකය, සා-හිත්‍යය',
        hint: 'Keep syllable timing steady and equal duration',
        items: ['වි-ද්‍යාව', 'පරි-ග-ණකය', 'සා-හිත්‍යය'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'syllable-practice:moderate:11-14',
    activityId: 'syllable-practice',
    difficulty: 'moderate',
    ageBand: '11-14',
    titleSinhala: 'සංයුක්ත අක්ෂර රටා (මධ්‍යස්ථ)',
    titleEnglish: 'Compound Syllable Articulation (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Easy Articulatory Transitions Across Complex Clusters',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'syl_1114_m_1',
        prompt: 'ක්‍රී-ඩා-පිටිය, විශ්ව-වි-ද්‍යාලය, තාක්ෂ-ණික',
        hint: 'Continuous airflow through consonant clusters',
        items: ['ක්‍රී-ඩා-පිටිය', 'විශ්ව-වි-ද්‍යාලය', 'තාක්ෂ-ණික'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'syllable-practice:difficult:11-14',
    activityId: 'syllable-practice',
    difficulty: 'difficult',
    ageBand: '11-14',
    titleSinhala: 'උසස් කථන ඒකක (අභියෝගාත්මක)',
    titleEnglish: 'Advanced Multi-Clause Phrasing (Challenging)',
    difficultyLabelSinhala: 'අභියෝගාත්මක (Difficult)',
    targetSkill: 'Mastery of Easy Onset Across Varied Consonants',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'syl_1114_d_1',
        prompt: 'සංවර්ධනාත්මක, ප්‍රතිපත්තිමය, වගකීම්සහගත',
        hint: 'Light contact, elongated vowels, zero throat pressure',
        items: ['සංවර්ධනාත්මක', 'ප්‍රතිපත්තිමය', 'වගකීම්සහගත'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'word-phrase-practice:easy:11-14',
    activityId: 'word-phrase-practice',
    difficulty: 'easy',
    ageBand: '11-14',
    titleSinhala: 'සම්බන්ධක වාක්‍යාංශ (පහසු)',
    titleEnglish: 'Structured Phrasing with Easy Onset (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Smooth Transition Across Phrase Boundaries',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'wpp_1114_e_1',
        prompt: 'පොත කියවීම ➔ මම කැමතිම පොත කියවීම',
        hint: 'Gentle vowel glide, maintain phrasing',
        items: ['පොත කියවීම', 'මම කැමතිම පොත කියවීම'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'word-phrase-practice:moderate:11-14',
    activityId: 'word-phrase-practice',
    difficulty: 'moderate',
    ageBand: '11-14',
    titleSinhala: 'සම්පූර්ණ ප්‍රකාශන වාක්‍ය (මධ්‍යස්ථ)',
    titleEnglish: 'Expressive Sentence Formation (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Breath-Group Pacing Across Long Sentences',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'wpp_1114_m_1',
        prompt: 'අද කාලගුණය ඉතාම ප්‍රසන්නයි, ඒ නිසා මම එළිමහනට යනවා.',
        hint: 'Pause at the comma, breathe smoothly before the second clause',
        items: ['අද කාලගුණය ඉතාම ප්‍රසන්නයි', 'ඒ නිසා මම එළිමහනට යනවා.'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'word-phrase-practice:difficult:11-14',
    activityId: 'word-phrase-practice',
    difficulty: 'difficult',
    ageBand: '11-14',
    titleSinhala: 'සංකීර්ණ වාක්‍ය ඛණ්ඩ ප්‍රකාශනය (අභියෝගාත්මක)',
    titleEnglish: 'Complex Multi-Clause Articulation (Challenging)',
    difficultyLabelSinhala: 'අභියෝගාත්මක (Difficult)',
    targetSkill: 'Fluency Maintenance Across Rapid Idea Formulation',
    suggestedDurationMinutes: 6,
    level2Items: [
      _Level2ContentItem(
        id: 'wpp_1114_d_1',
        prompt: 'අපගේ අනාගත අරමුණු සාක්ෂාත් කර ගැනීමට කැපවීම අවශ්‍යයි.',
        hint: 'Paced slow speech rate, controlled voice initiation',
        items: ['අපගේ අනාගත අරමුණු සාක්ෂාත් කර ගැනීමට', 'නිරන්තර කැපවීම අත්‍යවශ්‍ය වේ.'],
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'picture-description:easy:11-14',
    activityId: 'picture-description',
    difficulty: 'easy',
    ageBand: '11-14',
    titleSinhala: 'දර්ශන විස්තරය (පහසු)',
    titleEnglish: 'Factual Scene Narration (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Factual Description with Controlled Rate',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'pic_1114_e_1',
        prompt: 'පින්තූරයේ පරිසරය සහ ප්‍රධාන වස්තූන් පැහැදිලිව විස්තර කරන්න.',
        hint: 'Focus on natural rate and relaxed speech',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'picture-description:moderate:11-14',
    activityId: 'picture-description',
    difficulty: 'moderate',
    ageBand: '11-14',
    titleSinhala: 'දර්ශන විශ්ලේෂණය (මධ්‍යස්ථ)',
    titleEnglish: 'Thematic Scene Analysis (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Descriptive Elaboration with Easy Onset',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'pic_1114_m_1',
        prompt: 'පින්තූරයේ සිටින පුද්ගලයන්ගේ හැඟීම් සහ ක්‍රියාවන් පැහැදිලි කරන්න.',
        hint: 'Use descriptive phrasing with intentional pauses',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'picture-description:difficult:11-14',
    activityId: 'picture-description',
    difficulty: 'difficult',
    ageBand: '11-14',
    titleSinhala: 'සංකීර්ණ කථන නිර්මාණය (අභියෝගාත්මක)',
    titleEnglish: 'Extended Creative Discourse (Challenging)',
    difficultyLabelSinhala: 'අභියෝගාත්මක (Difficult)',
    targetSkill: 'Extended Continuous Speech Without Blocking',
    suggestedDurationMinutes: 6,
    level2Items: [
      _Level2ContentItem(
        id: 'pic_1114_d_1',
        prompt: 'මෙම දර්ශනයට පසු කුමක් සිදුවේදැයි ඔබේම වචන වලින් නිර්මාණාත්මකව විස්තර කරන්න.',
        hint: 'Maintain slow, steady rhythm throughout the story',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'guided-conversation:easy:11-14',
    activityId: 'guided-conversation',
    difficulty: 'easy',
    ageBand: '11-14',
    titleSinhala: 'විෂය පදනම් සංවාදය (පහසු)',
    titleEnglish: 'Topic-Based Dialogue (Easy)',
    difficultyLabelSinhala: 'පහසු (Easy)',
    targetSkill: 'Turn Formulation with Low Pressure',
    suggestedDurationMinutes: 4,
    level2Items: [
      _Level2ContentItem(
        id: 'gc_1114_e_1',
        prompt: 'ඔබ පාසලේදී වඩාත්ම ප්‍රිය කරන විෂය හෝ විනෝදාංශය කුමක්ද?',
        hint: 'Answer freely in a relaxed manner',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'guided-conversation:moderate:11-14',
    activityId: 'guided-conversation',
    difficulty: 'moderate',
    ageBand: '11-14',
    titleSinhala: 'මත ප්‍රකාශ කිරීමේ සංවාදය (මධ්‍යස්ථ)',
    titleEnglish: 'Opinion & Rationale Sharing (Moderate)',
    difficultyLabelSinhala: 'මධ්‍යස්ථ (Moderate)',
    targetSkill: 'Discourse Pacing and Continuous Phonation',
    suggestedDurationMinutes: 5,
    level2Items: [
      _Level2ContentItem(
        id: 'gc_1114_m_1',
        prompt: 'නව තාක්ෂණයෙන් ළමයින්ගේ අධ්‍යාපනයට ලැබෙන ප්‍රයෝජන ගැන ඔබේ අදහස කියන්න.',
        hint: 'Organize ideas calmly, pause between points',
      ),
    ],
  ),
  const _LinUcbLevel1Arm(
    armId: 'guided-conversation:difficult:11-14',
    activityId: 'guided-conversation',
    difficulty: 'difficult',
    ageBand: '11-14',
    titleSinhala: 'සංකීර්ණ තර්කනය සහ සංවාදය (අභියෝගාත්මක)',
    titleEnglish: 'Complex Argumentation & Discourse (Challenging)',
    difficultyLabelSinhala: 'අභියෝගාත්මක (Difficult)',
    targetSkill: 'Conversational Fluency Under Complex Formulations',
    suggestedDurationMinutes: 6,
    level2Items: [
      _Level2ContentItem(
        id: 'gc_1114_d_1',
        prompt: 'ඔබට කැමතිම ක්ෂේත්‍රයකින් ලෝකය වෙනස් කිරීමට හැකි නම්, ඔබ තෝරාගන්නේ කුමක්ද? හේතු පැහැදිලි කරන්න.',
        hint: 'Take your time, breathe at every full stop',
      ),
    ],
  ),
];

// ============================================================================
// LinUCB Recommendation Result
// ============================================================================
class _LinUcbRecommendation {
  final _TherapyActivityDefinition activity;
  final _LinUcbLevel1Arm arm;
  final _Level2ContentItem level2Item;
  final List<double> context;
  final double predictedReward;
  final double uncertainty;
  final double score;
  final String rationale;
  final bool isBreakRecommended;

  const _LinUcbRecommendation({
    required this.activity,
    required this.arm,
    required this.level2Item,
    required this.context,
    required this.predictedReward,
    required this.uncertainty,
    required this.score,
    required this.rationale,
    this.isBreakRecommended = false,
  });
}

// ============================================================================
// Per-Arm LinUCB State
// ============================================================================
class _LinUcbArmState {
  final List<List<double>> a; // d x d
  final List<List<double>> ba; // d x d (cross-term)
  final List<double> b; // d
  int updates;
  double rewardSum;
  double lastEngagement;

  _LinUcbArmState({
    List<List<double>>? a,
    List<List<double>>? ba,
    List<double>? b,
    this.updates = 0,
    this.rewardSum = 0.0,
    this.lastEngagement = 0.5,
  })  : a = a ??
            List.generate(
              _LinUcbModel.contextSize,
              (row) => List.generate(
                _LinUcbModel.contextSize,
                (col) => row == col ? 1.0 : 0.0,
              ),
            ),
        ba = ba ??
            List.generate(
              _LinUcbModel.contextSize,
              (_) => List.filled(_LinUcbModel.contextSize, 0.0),
            ),
        b = b ?? List.filled(_LinUcbModel.contextSize, 0.0);

  Map<String, dynamic> toJson() => {
        'a': a,
        'ba': ba,
        'b': b,
        'updates': updates,
        'rewardSum': rewardSum,
        'lastEngagement': lastEngagement,
      };

  factory _LinUcbArmState.fromJson(Map<String, dynamic> json) {
    final aRaw = json['a'] as List?;
    final baRaw = json['ba'] as List?;
    final bRaw = json['b'] as List?;

    final a = aRaw != null
        ? aRaw
            .map((r) => (r as List).map((v) => (v as num).toDouble()).toList())
            .toList()
        : null;
    final ba = baRaw != null
        ? baRaw
            .map((r) => (r as List).map((v) => (v as num).toDouble()).toList())
            .toList()
        : null;
    final b = bRaw != null
        ? bRaw.map((v) => (v as num).toDouble()).toList()
        : null;

    return _LinUcbArmState(
      a: a,
      ba: ba,
      b: b,
      updates: (json['updates'] as num?)?.toInt() ?? 0,
      rewardSum: (json['rewardSum'] as num?)?.toDouble() ?? 0.0,
      lastEngagement: (json['lastEngagement'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

// ============================================================================
// Hybrid LinUCB Model (Discounted / Sliding-Window Adaptive Recommender)
// ============================================================================
class _LinUcbModel {
  static const int contextSize = 12;
  static const String _storageKeyPrefix = 'c3_linucb_hybrid_v1_';
  static const double _explorationAlpha = 0.8;
  static const double _discountFactor = 0.95; // Discounted LinUCB

  final String _storageKey;
  final Map<String, _LinUcbArmState> _arms = {};
  final List<List<double>> _a0; // Shared 12x12
  final List<double> _b0; // Shared 12
  final List<String> _recentLevel2Ids = [];

  int _totalUpdates = 0;
  double _totalReward = 0.0;
  int sessionActivitiesCompleted = 0;
  double sessionRewardTotal = 0.0;
  int? sessionStartedAtMilliseconds;

  String? pendingArmId;
  String? pendingActivityId;
  List<double>? _pendingContext;
  double? _lastActivityEngagement;

  _LinUcbModel._(this._storageKey)
      : _a0 = List.generate(
          contextSize,
          (row) => List.generate(
            contextSize,
            (col) => row == col ? 1.0 : 0.0,
          ),
        ),
        _b0 = List.filled(contextSize, 0.0) {
    for (final arm in _allLevel1Arms) {
      _arms[arm.armId] = _LinUcbArmState();
    }
  }

  static Future<_LinUcbModel> load() async {
    final userJson = await StorageService.getString(AppConstants.userKey);
    if (userJson == null) {
      throw StateError('A signed-in user is required for adaptive selection.');
    }
    final user = jsonDecode(userJson);
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Stored user profile is not an object.');
    }
    final userId = user['id']?.toString() ?? user['_id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw StateError('The signed-in user has no valid id.');
    }

    final model = _LinUcbModel._('$_storageKeyPrefix${Uri.encodeComponent(userId)}');
    final stored = await StorageService.getString(model._storageKey);

    if (stored != null) {
      try {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        model._totalUpdates = (decoded['totalUpdates'] as num?)?.toInt() ?? 0;
        model._totalReward = (decoded['totalReward'] as num?)?.toDouble() ?? 0.0;
        model.sessionActivitiesCompleted =
            (decoded['sessionActivitiesCompleted'] as num?)?.toInt() ?? 0;
        model.sessionRewardTotal =
            (decoded['sessionRewardTotal'] as num?)?.toDouble() ?? 0.0;
        model.sessionStartedAtMilliseconds =
            decoded['sessionStartedAtMilliseconds'] as int?;
        model.pendingArmId = decoded['pendingArmId'] as String?;
        model.pendingActivityId = decoded['pendingActivityId'] as String?;
        model._lastActivityEngagement =
            (decoded['lastActivityEngagement'] as num?)?.toDouble();

        if (decoded['pendingContext'] is List) {
          model._pendingContext = (decoded['pendingContext'] as List)
              .map((v) => (v as num).toDouble())
              .toList();
        }

        if (decoded['recentLevel2Ids'] is List) {
          model._recentLevel2Ids.addAll(
            (decoded['recentLevel2Ids'] as List).map((e) => e.toString()),
          );
        }

        // Shared A0, b0
        if (decoded['a0'] is List) {
          final a0List = (decoded['a0'] as List)
              .map((r) => (r as List).map((v) => (v as num).toDouble()).toList())
              .toList();
          if (a0List.length == contextSize) {
            for (var r = 0; r < contextSize; r++) {
              for (var c = 0; c < contextSize; c++) {
                model._a0[r][c] = a0List[r][c];
              }
            }
          }
        }
        if (decoded['b0'] is List) {
          final b0List = (decoded['b0'] as List)
              .map((v) => (v as num).toDouble())
              .toList();
          if (b0List.length == contextSize) {
            for (var i = 0; i < contextSize; i++) {
              model._b0[i] = b0List[i];
            }
          }
        }

        // Arms
        if (decoded['arms'] is Map) {
          final armsMap = decoded['arms'] as Map<String, dynamic>;
          for (final entry in armsMap.entries) {
            if (entry.value is Map) {
              model._arms[entry.key] =
                  _LinUcbArmState.fromJson(entry.value as Map<String, dynamic>);
            }
          }
        }
      } catch (e) {
        debugPrint('Warning: Local LinUCB model restore fallback: $e');
      }
    }

    // Try fetching the global shared parameters from backend to update prior
    try {
      final sharedData = await TherapyApiService.fetchSharedLinUcbState();
      if (sharedData != null) {
        final a0 = sharedData['A0'] as List?;
        final b0 = sharedData['b0'] as List?;
        if (a0 != null && a0.length == contextSize && b0 != null && b0.length == contextSize) {
          for (var r = 0; r < contextSize; r++) {
            final row = (a0[r] as List).map((v) => (v as num).toDouble()).toList();
            for (var c = 0; c < contextSize; c++) {
              // Blend local with global aggregate
              model._a0[r][c] = (model._a0[r][c] + row[c]) / 2.0;
            }
          }
          for (var i = 0; i < contextSize; i++) {
            model._b0[i] = (model._b0[i] + (b0[i] as num).toDouble()) / 2.0;
          }
        }
      }
    } catch (_) {}

    return model;
  }

  // ==========================================================================
  // Clinical Context Vector Construction (12 Dimensions)
  // ==========================================================================
  static List<double> buildContextVector({
    required int childAge,
    required String? c1Severity,
    required bool? c2SecondaryBehaviours,
    required bool cameraOn,
    required double recentEngagementTrend,
    required double recentPerformanceForType,
    required int sessionCount,
    required double parentHelpLevel,
  }) {
    final x = List<double>.filled(contextSize, 0.0);

    // [0] Bias term (1.0)
    x[0] = 1.0;

    // [1,2] Age band
    if (childAge >= 5 && childAge <= 10) {
      x[1] = 1.0;
      x[2] = 0.0;
    } else if (childAge >= 11 && childAge <= 14) {
      x[1] = 0.0;
      x[2] = 1.0;
    } else {
      x[1] = 0.5;
      x[2] = 0.5;
    }

    // [3,4,5] C1 Severity (Mild, Moderate, Severe)
    final sev = c1Severity?.toLowerCase();
    if (sev == 'mild') {
      x[3] = 1.0;
    } else if (sev == 'moderate') {
      x[4] = 1.0;
    } else if (sev == 'severe') {
      x[5] = 1.0;
    } else {
      // Uncertainty uniform encoding
      x[3] = 1.0 / 3.0;
      x[4] = 1.0 / 3.0;
      x[5] = 1.0 / 3.0;
    }

    // [6] C2 Secondary Behaviours
    if (c2SecondaryBehaviours == true) {
      x[6] = 1.0;
    } else if (c2SecondaryBehaviours == false) {
      x[6] = 0.0;
    } else {
      x[6] = 0.5;
    }

    // [7] Camera Mode
    x[7] = cameraOn ? 1.0 : 0.0;

    // [8] Recent Engagement Trend (0-1)
    x[8] = recentEngagementTrend.clamp(0.0, 1.0);

    // [9] Recent Performance for Activity Type (0-1)
    x[9] = recentPerformanceForType.clamp(0.0, 1.0);

    // [10] Normalised Session Count
    x[10] = (sessionCount / 20.0).clamp(0.0, 1.0);

    // [11] Parent Assistance Level (0.0 to 1.0)
    x[11] = parentHelpLevel.clamp(0.0, 1.0);

    return x;
  }

  // ==========================================================================
  // Hybrid LinUCB Recommendation Selection
  // ==========================================================================
  _LinUcbRecommendation recommend({
    required List<double> context,
    int childAge = 7,
    String? excludeArmId,
    String? excludeActivityId,
  }) {
    if (context.length != contextSize) {
      throw ArgumentError('Expected context vector of size $contextSize, got ${context.length}');
    }

    final targetAgeBand = (childAge >= 11 && childAge <= 14) ? '11-14' : '5-10';

    // 1. Within-Session Adaptation Check:
    // If the child's last activity engagement was very low (< 0.40), offer a calming
    // breathing activity or break before continuing demanding tasks.
    if (_lastActivityEngagement != null && _lastActivityEngagement! < 0.40) {
      final calmingArm = _allLevel1Arms.firstWhere(
        (arm) => arm.activityId == 'breathing-body-awareness' && arm.ageBand == targetAgeBand,
        orElse: () => _allLevel1Arms.first,
      );
      final level2 = _sampleLevel2Item(calmingArm);

      return _LinUcbRecommendation(
        activity: calmingArm.baseActivity,
        arm: calmingArm,
        level2Item: level2,
        context: context,
        predictedReward: 0.9,
        uncertainty: 0.1,
        score: 1.0,
        rationale: 'මෑත අභ්‍යාසය අතරතුර අවධානය අඩු වූ බැවින්, සන්සුන් හුස්ම ගැනීමේ විවේකයක් ලබා දෙමු.',
        isBreakRecommended: true,
      );
    }

    // 2. Strict Filter: Filter Level 1 arms by child age band
    var candidates = _allLevel1Arms.where((arm) => arm.ageBand == targetAgeBand).toList();
    if (candidates.isEmpty) candidates = _allLevel1Arms;

    // 3. Recency Filter: Exclude immediately preceding arm if more than 1 choice exists
    final prevExcluded = excludeArmId ?? pendingArmId;
    if (candidates.length > 1 && prevExcluded != null) {
      candidates = candidates.where((arm) => arm.armId != prevExcluded).toList();
    }
    // Also avoid repeating the exact same base activity back-to-back if options permit
    final prevActId = excludeActivityId ?? pendingActivityId;
    if (candidates.length > 2 && prevActId != null) {
      final varied = candidates.where((arm) => arm.activityId != prevActId).toList();
      if (varied.isNotEmpty) candidates = varied;
    }

    // 4. Compute Shared Ridge Coefficients: beta = A0^-1 * b0
    final a0Inv = _inverse(_a0);
    final beta = _matVecMul(a0Inv, _b0);

    _LinUcbLevel1Arm? bestArm;
    var bestScore = double.negativeInfinity;
    var bestPred = 0.5;
    var bestUncertainty = 0.5;

    // 5. Evaluate Upper Confidence Bound for Each Arm
    for (final arm in candidates) {
      final state = _arms[arm.armId] ?? _LinUcbArmState();
      _arms[arm.armId] = state;

      final aInv = _inverse(state.a);
      // theta_a = A_a^-1 * (b_a - B_a * beta)
      final baBeta = _matVecMul(state.ba, beta);
      final diff = List<double>.generate(contextSize, (i) => state.b[i] - baBeta[i]);
      final theta = _matVecMul(aInv, diff);

      // Predicted payoff: z_t^T * beta + x_{t,a}^T * theta_a
      final predReward = _dot(context, beta) + _dot(context, theta);

      // Uncertainty variance:
      // s1 = z_t^T A0^-1 z_t - 2 z_t^T A0^-1 Ba^T Aa^-1 x_t
      // s2 = x_t^T Aa^-1 x_t + x_t^T Aa^-1 Ba A0^-1 Ba^T Aa^-1 x_t
      final a0InvZ = _matVecMul(a0Inv, context);
      final term1 = _dot(context, a0InvZ);

      final aaInvX = _matVecMul(aInv, context);
      final term2 = _dot(context, aaInvX);

      final baTranspose = _transpose(state.ba);
      final baAaInvX = _matVecMul(baTranspose, aaInvX);
      final crossTerm = 2.0 * _dot(a0InvZ, baAaInvX);

      final a0InvBaAaInvX = _matVecMul(a0Inv, baAaInvX);
      final term3 = _dot(baAaInvX, a0InvBaAaInvX);

      final variance = math.max(0.0, term1 - crossTerm + term2 + term3);
      final uncertainty = math.sqrt(variance);

      final ucbScore = predReward + _explorationAlpha * uncertainty;

      if (bestArm == null || ucbScore > bestScore) {
        bestArm = arm;
        bestScore = ucbScore;
        bestPred = predReward;
        bestUncertainty = uncertainty;
      }
    }

    final chosenArm = bestArm ?? candidates.first;
    final level2 = _sampleLevel2Item(chosenArm);

    return _LinUcbRecommendation(
      activity: chosenArm.baseActivity,
      arm: chosenArm,
      level2Item: level2,
      context: context,
      predictedReward: bestPred,
      uncertainty: bestUncertainty,
      score: bestScore,
      rationale: 'ඔබේ මෑත කථන සාර්ථකත්වය සහ අවධානය අනුව තෝරාගත් අභ්‍යාසයකි.',
      isBreakRecommended: false,
    );
  }

  // ==========================================================================
  // Level 2 Content Sampling (avoiding recent repetition)
  // ==========================================================================
  _Level2ContentItem _sampleLevel2Item(_LinUcbLevel1Arm arm) {
    if (arm.level2Items.isEmpty) {
      return _Level2ContentItem(
        id: '${arm.armId}_default',
        prompt: arm.baseActivity.instruction,
        hint: arm.targetSkill,
      );
    }

    final fresh = arm.level2Items
        .where((item) => !_recentLevel2Ids.contains(item.id))
        .toList();

    final chosen = fresh.isNotEmpty
        ? fresh[math.Random().nextInt(fresh.length)]
        : arm.level2Items[math.Random().nextInt(arm.level2Items.length)];

    _recentLevel2Ids.add(chosen.id);
    if (_recentLevel2Ids.length > 5) {
      _recentLevel2Ids.removeAt(0);
    }

    return chosen;
  }

  // ==========================================================================
  // Pending Recommendation Management
  // ==========================================================================
  Future<void> setPendingRecommendation(_LinUcbRecommendation rec) async {
    pendingArmId = rec.arm.armId;
    pendingActivityId = rec.activity.id;
    _pendingContext = List.of(rec.context);
    await _save();
  }

  // ==========================================================================
  // Record Real Learning Signal (Performance P + Logs-Only Engagement E)
  // Reward: r = 0.6 * P + 0.4 * E
  // ==========================================================================
  Future<void> recordPendingReward({
    required double performance,
    required double engagement,
    int? parentHelpRating,
  }) async {
    final armId = pendingArmId;
    final context = _pendingContext;
    if (armId == null || context == null) return;

    final pClamped = performance.clamp(0.0, 1.0);
    final eClamped = engagement.clamp(0.0, 1.0);
    final reward = (0.6 * pClamped + 0.4 * eClamped).clamp(0.0, 1.0);

    _lastActivityEngagement = eClamped;

    // Apply Discounted LinUCB Updates
    _applyDiscountedReward(armId, context, reward);

    await _save();

    // Asynchronously sync update to server LinUCBState collection
    try {
      final armState = _arms[armId];
      if (armState != null) {
        TherapyApiService.syncLinUcbState(
          armUpdates: [
            {
              'armId': armId,
              'A': armState.a,
              'B': armState.ba,
              'b': armState.b,
              'reward': reward,
            }
          ],
        );
      }
    } catch (_) {}
  }

  void _applyDiscountedReward(String armId, List<double> context, double reward) {
    final state = _arms[armId] ?? _LinUcbArmState();
    _arms[armId] = state;

    // 1. Discount existing per-arm parameters by gamma = 0.95
    for (var r = 0; r < contextSize; r++) {
      state.b[r] = _discountFactor * state.b[r];
      for (var c = 0; c < contextSize; c++) {
        state.a[r][c] = _discountFactor * state.a[r][c] +
            (r == c ? (1.0 - _discountFactor) : 0.0);
        state.ba[r][c] = _discountFactor * state.ba[r][c];
      }
    }

    // 2. Discount shared parameters by gamma = 0.95
    for (var r = 0; r < contextSize; r++) {
      _b0[r] = _discountFactor * _b0[r];
      for (var c = 0; c < contextSize; c++) {
        _a0[r][c] = _discountFactor * _a0[r][c] +
            (r == c ? (1.0 - _discountFactor) : 0.0);
      }
    }

    // 3. Accumulate new outer products
    for (var r = 0; r < contextSize; r++) {
      state.b[r] += reward * context[r];
      _b0[r] += reward * context[r];
      for (var c = 0; c < contextSize; c++) {
        final outer = context[r] * context[c];
        state.a[r][c] += outer;
        state.ba[r][c] += outer;
        _a0[r][c] += outer;
      }
    }

    state.updates++;
    state.rewardSum += reward;
    state.lastEngagement = _lastActivityEngagement ?? 0.5;

    _totalUpdates++;
    _totalReward += reward;
    sessionActivitiesCompleted++;
    sessionRewardTotal += reward;

    pendingArmId = null;
    pendingActivityId = null;
    _pendingContext = null;
  }

  Future<void> clearPendingWithoutReward() async {
    pendingArmId = null;
    pendingActivityId = null;
    _pendingContext = null;
    await _save();
  }

  static Future<void> clearPendingForCurrentUser() async {
    final model = await load();
    model
      ..pendingArmId = null
      ..pendingActivityId = null
      .._pendingContext = null
      ..sessionActivitiesCompleted = 0
      ..sessionRewardTotal = 0
      ..sessionStartedAtMilliseconds = DateTime.now().millisecondsSinceEpoch;
    await model._save();
  }

  double get sessionScoreOutOfTen => sessionActivitiesCompleted == 0
      ? 0.0
      : (sessionRewardTotal / sessionActivitiesCompleted * 10).clamp(0.0, 10.0);

  int get sessionDurationMinutes {
    final startedAt = sessionStartedAtMilliseconds;
    if (startedAt == null) return 0;
    return math.max(
      0,
      DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(startedAt))
          .inMinutes,
    );
  }

  Future<void> _save() => StorageService.saveString(
        _storageKey,
        jsonEncode({
          'version': 3,
          'totalUpdates': _totalUpdates,
          'totalReward': _totalReward,
          'sessionActivitiesCompleted': sessionActivitiesCompleted,
          'sessionRewardTotal': sessionRewardTotal,
          'sessionStartedAtMilliseconds': sessionStartedAtMilliseconds,
          'pendingArmId': pendingArmId,
          'pendingActivityId': pendingActivityId,
          'pendingContext': _pendingContext,
          'lastActivityEngagement': _lastActivityEngagement,
          'recentLevel2Ids': _recentLevel2Ids,
          'a0': _a0,
          'b0': _b0,
          'arms': _arms.map((k, v) => MapEntry(k, v.toJson())),
        }),
      );

  // ==========================================================================
  // Logs-Only Engagement and Performance Calculation Helpers
  // ==========================================================================
  static double estimateLogsOnlyEngagement({
    required double completionFraction,
    required int targetOpportunities,
    required int attempts,
    required int durationSeconds,
    bool skipped = false,
  }) {
    if (skipped && completionFraction <= 0.1) return 0.20;

    // 1. Completion fraction (weight 0.40)
    final comp = completionFraction.clamp(0.0, 1.0);

    // 2. Attempt rate (weight 0.25)
    final attRate = targetOpportunities > 0
        ? (attempts / targetOpportunities).clamp(0.0, 1.0)
        : 1.0;

    // 3. Skip penalty (weight 0.20)
    final skipSignal = skipped ? 0.0 : 1.0;

    // 4. Response duration pacing (weight 0.15)
    final secsPerTarget =
        targetOpportunities > 0 ? durationSeconds / targetOpportunities : 15.0;
    final pacing = (secsPerTarget >= 4.0 && secsPerTarget <= 60.0)
        ? 1.0
        : (secsPerTarget < 4.0 ? 0.65 : 0.70);

    final score =
        0.40 * comp + 0.25 * attRate + 0.20 * skipSignal + 0.15 * pacing;
    return score.clamp(0.10, 1.0);
  }

  static double calculatePerformanceScore({
    required int successes,
    required int targets,
    required double completionFraction,
  }) {
    if (targets <= 0) return completionFraction.clamp(0.0, 1.0);
    final ratio = (successes / targets).clamp(0.0, 1.0);
    return (ratio * completionFraction).clamp(0.0, 1.0);
  }

  // ==========================================================================
  // Matrix Math Utilities
  // ==========================================================================
  static double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  static List<double> _matVecMul(List<List<double>> m, List<double> v) {
    return List.generate(m.length, (r) => _dot(m[r], v));
  }

  static List<List<double>> _transpose(List<List<double>> m) {
    final rows = m.length;
    final cols = m[0].length;
    return List.generate(
      cols,
      (c) => List.generate(rows, (r) => m[r][c]),
    );
  }

  static List<List<double>> _inverse(List<List<double>> matrix) {
    final size = matrix.length;
    // Add ridge regularisation (1e-4) along diagonal for numerical stability
    const ridge = 1e-4;
    final aug = List.generate(
      size,
      (r) => [
        ...List.generate(size, (c) => matrix[r][c] + (r == c ? ridge : 0.0)),
        ...List.generate(size, (c) => r == c ? 1.0 : 0.0),
      ],
    );

    for (var col = 0; col < size; col++) {
      var pivotRow = col;
      for (var r = col + 1; r < size; r++) {
        if (aug[r][col].abs() > aug[pivotRow][col].abs()) {
          pivotRow = r;
        }
      }

      final pivotVal = aug[pivotRow][col];
      if (pivotVal.abs() < 1e-12) {
        // Fallback: return identity if matrix is completely degenerate
        return List.generate(
          size,
          (r) => List.generate(size, (c) => r == c ? 1.0 : 0.0),
        );
      }

      final temp = aug[pivotRow];
      aug[pivotRow] = aug[col];
      aug[col] = temp;

      for (var i = 0; i < size * 2; i++) {
        aug[col][i] /= pivotVal;
      }

      for (var r = 0; r < size; r++) {
        if (r == col) continue;
        final factor = aug[r][col];
        for (var i = 0; i < size * 2; i++) {
          aug[r][i] -= factor * aug[col][i];
        }
      }
    }

    return List.generate(size, (r) => aug[r].sublist(size));
  }
}
