import '../models/child_model.dart';

/// Demo/Sample data for the SWARA Research Prototype
/// These are synthetic profiles — no real children's data is used.
class DemoData {
  // Demo Children
  static final List<ChildModel> children = [
    ChildModel(
      id: 'demo_ch_001',
      childId: 'CH-001',
      firstName: 'Amal',
      age: 7,
      gender: 'Male',
      interests: ['Animals', 'Forest'],
      severity: 'Moderate',
      stutterType: 'Repetition',
      parentId: 'demo_parent_1',
      supportIndicator: 55.0,
      communicationScore: 7.5,
      assignedTheme: 'Animal Adventure',
    ),
    ChildModel(
      id: 'demo_ch_002',
      childId: 'CH-002',
      firstName: 'Nimal',
      age: 9,
      gender: 'Male',
      interests: ['Space', 'Science'],
      severity: 'Mild',
      stutterType: 'Prolongation',
      parentId: 'demo_parent_1',
      supportIndicator: 80.0,
      communicationScore: 8.2,
      assignedTheme: 'Space Explorer',
    ),
    ChildModel(
      id: 'demo_ch_003',
      childId: 'CH-003',
      firstName: 'Savi',
      age: 6,
      gender: 'Female',
      interests: ['Forest', 'Nature'],
      severity: 'Severe',
      stutterType: 'Block',
      parentId: 'demo_parent_1',
      supportIndicator: 42.0,
      communicationScore: 5.4,
      assignedTheme: 'Forest Friends',
    ),
    ChildModel(
      id: 'demo_ch_004',
      childId: 'CH-004',
      firstName: 'Kasun',
      age: 8,
      gender: 'Male',
      interests: ['Ocean', 'Fishing'],
      severity: 'Moderate',
      stutterType: 'Mixed',
      parentId: 'demo_parent_1',
      supportIndicator: 68.0,
      communicationScore: 6.8,
      assignedTheme: 'Ocean Adventure',
    ),
    ChildModel(
      id: 'demo_ch_005',
      childId: 'CH-005',
      firstName: 'Dilani',
      age: 10,
      gender: 'Female',
      interests: ['Music', 'Art'],
      severity: 'Mild',
      stutterType: 'Repetition',
      parentId: 'demo_parent_1',
      supportIndicator: 72.0,
      communicationScore: 7.9,
      assignedTheme: 'Music World',
    ),
  ];

  // Demo Speech Assessment Results
  static Map<String, dynamic> speechResult(String childId) {
    final data = {
      'CH-001': {
        'stutterDetected': true,
        'stutterType': 'Repetition',
        'severity': 'Moderate',
        'confidence': 0.82,
        'features': {
          'duration': 32,
          'pauseCount': 14,
          'averagePauseDuration': 0.82,
          'speechRate': 2.1,
          'estimatedWordCount': 67,
        },
        'childId': childId,
        'childName': 'Amal',
        'isPrototype': true,
      },
      'CH-002': {
        'stutterDetected': true,
        'stutterType': 'Prolongation',
        'severity': 'Mild',
        'confidence': 0.74,
        'features': {
          'duration': 28,
          'pauseCount': 8,
          'averagePauseDuration': 0.55,
          'speechRate': 2.8,
          'estimatedWordCount': 78,
        },
        'childId': childId,
        'childName': 'Nimal',
        'isPrototype': true,
      },
      'CH-003': {
        'stutterDetected': true,
        'stutterType': 'Block',
        'severity': 'Severe',
        'confidence': 0.91,
        'features': {
          'duration': 45,
          'pauseCount': 22,
          'averagePauseDuration': 1.2,
          'speechRate': 1.4,
          'estimatedWordCount': 63,
        },
        'childId': childId,
        'childName': 'Savi',
        'isPrototype': true,
      },
    };
    return data[childId] ??
        {
          'stutterDetected': true,
          'stutterType': 'Repetition',
          'severity': 'Moderate',
          'confidence': 0.78,
          'features': {
            'duration': 30,
            'pauseCount': 12,
            'averagePauseDuration': 0.75,
            'speechRate': 2.2,
            'estimatedWordCount': 65,
          },
          'childId': childId,
          'isPrototype': true,
        };
  }

  // Demo Psychology Result
  static Map<String, dynamic> psychologyResult(String childId) {
    return {
      'score': 55.0,
      'level': 'Medium',
      'childId': childId,
      'supportAreas': [
        {
          'area': 'Speaking Confidence',
          'score': 45,
          'suggestions': [
            'Positive reinforcement during conversations',
            'Family speaking activities',
            'Encouraging daily speech activities',
          ],
        },
        {
          'area': 'Emotion Expression',
          'score': 60,
          'suggestions': [
            'Emotion expression through drawing',
            'Choosing emotions from picture cards',
            'Talking with a parent about the child\'s day',
          ],
        },
        {
          'area': 'Social Participation',
          'score': 50,
          'suggestions': [
            'Group storytelling activities',
            'Sharing time at school',
            'Supervised peer interaction',
          ],
        },
      ],
      'caregiverGuidance':
          'Encourage the child to communicate without interrupting or showing negative reactions to stuttering. Create a calm and supportive environment for speech practice.',
      'isPrototype': true,
    };
  }

  // Demo Therapy Recommendations
  static Map<String, dynamic> therapyRecommendations(String childId) {
    final child = children.firstWhere(
      (c) => c.childId == childId || c.id == childId,
      orElse: () => children.first,
    );
    return {
      'childId': childId,
      'theme': child.assignedTheme ?? 'Animal Adventure',
      'activities': [
        {
          'id': 'act_001',
          'name': 'Slow Speech Practice',
          'description': 'Practice speaking slowly and clearly using animal-themed sentences.',
          'duration': 10,
          'difficulty': 'Beginner',
          'type': 'speech',
        },
        {
          'id': 'act_002',
          'name': 'Easy Onset Practice',
          'description': 'Start sentences gently without forcing air through blocked sounds.',
          'duration': 8,
          'difficulty': 'Beginner',
          'type': 'breathing',
        },
        {
          'id': 'act_003',
          'name': 'Picture Description',
          'description': 'Describe a picture of an animal using 3-5 sentences.',
          'duration': 7,
          'difficulty': 'Intermediate',
          'type': 'speech',
        },
        {
          'id': 'act_004',
          'name': 'Guided Conversation',
          'description': 'Have a calm conversation about the story with a parent.',
          'duration': 10,
          'difficulty': 'Intermediate',
          'type': 'conversation',
        },
      ],
      'sessionId': 'demo_session_001',
      'isPrototype': true,
    };
  }

  // Demo Storybook Pages
  static List<Map<String, dynamic>> storybookPages(String theme) {
    final stories = {
      'Animal Adventure': [
        {
          'page': 1,
          'text': 'Today, we are going to visit the forest! 🌿',
          'instruction': 'Read this sentence slowly.',
          'illustration': '🌳',
        },
        {
          'page': 2,
          'text': 'The elephant sees a beautiful bird in the tree.',
          'instruction': 'Describe what the bird is doing.',
          'illustration': '🐘',
        },
        {
          'page': 3,
          'text': 'A little rabbit hops along the path.',
          'instruction': 'What sound does a rabbit make? Try saying it slowly.',
          'illustration': '🐰',
        },
        {
          'page': 4,
          'text': 'The animals gather by the river to drink water.',
          'instruction': 'Name three animals you see by the river.',
          'illustration': '🦁',
        },
        {
          'page': 5,
          'text': 'Everyone had a wonderful day in the forest!',
          'instruction': 'What was your favorite part of the story?',
          'illustration': '🌟',
        },
      ],
      'Space Explorer': [
        {
          'page': 1,
          'text': 'Captain Nimal boards the rocket ship! 🚀',
          'instruction': 'Count to 5 for the rocket launch!',
          'illustration': '🚀',
        },
        {
          'page': 2,
          'text': 'He flies past the moon and the stars.',
          'instruction': 'Describe what you see in space.',
          'illustration': '🌙',
        },
        {
          'page': 3,
          'text': 'A friendly alien waves from a purple planet.',
          'instruction': 'What would you say to the alien?',
          'illustration': '👽',
        },
        {
          'page': 4,
          'text': 'The alien shows him amazing space crystals.',
          'instruction': 'What color are the crystals?',
          'illustration': '💎',
        },
        {
          'page': 5,
          'text': 'Nimal flies home with a heart full of adventure!',
          'instruction': 'What was the best part of the space journey?',
          'illustration': '🌟',
        },
      ],
    };
    return stories[theme] ?? stories['Animal Adventure']!;
  }

  // Demo Communication Tasks
  static List<Map<String, dynamic>> get communicationTasks => [
        {
          'id': 'task_001',
          'scenario':
              'Your friend is crying at school. What would you do and say to help them feel better?',
          'ageGroup': '5-12',
          'difficulty': 'Easy',
          'keywords': ['help', 'friend', 'comfort', 'feel', 'better', 'sad', 'cry', 'care'],
        },
        {
          'id': 'task_002',
          'scenario': 'You lost your pencil at school. How would you ask your teacher for help?',
          'ageGroup': '5-12',
          'difficulty': 'Easy',
          'keywords': ['pencil', 'lost', 'teacher', 'help', 'please', 'find', 'sorry'],
        },
        {
          'id': 'task_003',
          'scenario': 'Your teacher asks you to explain your favorite game to the class.',
          'ageGroup': '6-12',
          'difficulty': 'Medium',
          'keywords': ['game', 'play', 'rules', 'fun', 'players', 'win', 'how', 'like'],
        },
        {
          'id': 'task_004',
          'scenario': 'Your friend gives you a gift for your birthday. What would you say?',
          'ageGroup': '5-12',
          'difficulty': 'Easy',
          'keywords': ['thank', 'gift', 'birthday', 'happy', 'love', 'appreciate', 'kind'],
        },
      ];

  // Demo Communication Result
  static Map<String, dynamic> communicationResult(String childId) => {
        'childId': childId,
        'scores': {
          'keywordRelevance': 8.0,
          'responseLength': 7.0,
          'speechFluency': 6.0,
          'responseOrganization': 8.0,
        },
        'overallScore': 7.25,
        'status': 'Improving',
        'isPrototype': true,
      };

  // Demo Progress History
  static List<Map<String, dynamic>> progressHistory(String childId) => [
        {'session': 1, 'date': '2025-11-01', 'speechScore': 0.0, 'commScore': 5.4, 'therapyScore': 0.0},
        {'session': 2, 'date': '2025-11-08', 'speechScore': 0.0, 'commScore': 5.8, 'therapyScore': 72.0},
        {'session': 3, 'date': '2025-11-15', 'speechScore': 0.0, 'commScore': 6.2, 'therapyScore': 75.0},
        {'session': 4, 'date': '2025-11-22', 'speechScore': 0.0, 'commScore': 6.9, 'therapyScore': 80.0},
        {'session': 5, 'date': '2025-11-29', 'speechScore': 0.0, 'commScore': 7.5, 'therapyScore': 85.0},
      ];

  // Therapy Activities (Knowledge Base)
  static List<Map<String, dynamic>> get therapyActivities => [
        {
          'id': 'ka_001',
          'name': 'Slow Speech Practice',
          'description': 'Practise speaking slowly and clearly to reduce stuttering episodes.',
          'ageRange': [5, 12],
          'severity': ['Mild', 'Moderate'],
          'stutterTypes': ['Repetition', 'Block'],
          'difficulty': 'Beginner',
          'duration': 10,
          'theme': 'General',
          'therapistNotes': 'Reduce speech rate to approximately 120 words per minute.',
        },
        {
          'id': 'ka_002',
          'name': 'Easy Onset Practice',
          'description': 'Begin sounds gently without forcing airflow.',
          'ageRange': [6, 14],
          'severity': ['Moderate', 'Severe'],
          'stutterTypes': ['Block', 'Prolongation'],
          'difficulty': 'Beginner',
          'duration': 8,
          'theme': 'General',
          'therapistNotes': 'Focus on smooth airflow initiation at sentence start.',
        },
        {
          'id': 'ka_003',
          'name': 'Picture Description',
          'description': 'Describe a scene picture using 3-5 sentences.',
          'ageRange': [5, 10],
          'severity': ['Mild', 'Moderate'],
          'stutterTypes': ['Repetition', 'Prolongation', 'Block'],
          'difficulty': 'Intermediate',
          'duration': 7,
          'theme': 'Storytelling',
          'therapistNotes': 'Use colourful scene pictures relevant to child interests.',
        },
        {
          'id': 'ka_004',
          'name': 'Breathing Exercises',
          'description': 'Deep breathing techniques to reduce tension before speaking.',
          'ageRange': [5, 14],
          'severity': ['Moderate', 'Severe'],
          'stutterTypes': ['Block', 'Mixed'],
          'difficulty': 'Beginner',
          'duration': 5,
          'theme': 'Wellness',
          'therapistNotes': 'Diaphragmatic breathing — inhale 4 counts, exhale 6 counts.',
        },
        {
          'id': 'ka_005',
          'name': 'Guided Conversation',
          'description': 'A structured conversation with a parent or therapist on a chosen topic.',
          'ageRange': [6, 14],
          'severity': ['Mild', 'Moderate', 'Severe'],
          'stutterTypes': ['Repetition', 'Prolongation', 'Block', 'Mixed'],
          'difficulty': 'Intermediate',
          'duration': 10,
          'theme': 'Communication',
          'therapistNotes': 'Choose topic of child interest to reduce anxiety.',
        },
        {
          'id': 'ka_006',
          'name': 'Reading Aloud',
          'description': 'Read short passages aloud at a controlled pace.',
          'ageRange': [7, 14],
          'severity': ['Mild', 'Moderate'],
          'stutterTypes': ['Repetition', 'Prolongation'],
          'difficulty': 'Intermediate',
          'duration': 12,
          'theme': 'Literacy',
          'therapistNotes': 'Use decodable reader books appropriate for age.',
        },
      ];

  // Questionnaire Questions
  static List<Map<String, dynamic>> get questionnaireQuestions => [
        {
          'id': 'q1',
          'text': 'Does the child avoid speaking in groups?',
          'area': 'Social Participation',
        },
        {
          'id': 'q2',
          'text': 'Does the child appear uncomfortable when speaking?',
          'area': 'Speaking Confidence',
        },
        {
          'id': 'q3',
          'text': 'Does the child avoid answering questions at school?',
          'area': 'Social Participation',
        },
        {
          'id': 'q4',
          'text': 'Does the child become frustrated when speaking?',
          'area': 'Emotion Expression',
        },
        {
          'id': 'q5',
          'text': 'Does the child hesitate to participate in social activities?',
          'area': 'Social Participation',
        },
        {
          'id': 'q6',
          'text': 'Does the child show reduced confidence when speaking?',
          'area': 'Speaking Confidence',
        },
        {
          'id': 'q7',
          'text': 'Does the child discuss negative feelings about speaking?',
          'area': 'Emotion Expression',
        },
        {
          'id': 'q8',
          'text': 'Does the child avoid talking on the phone or video calls?',
          'area': 'Communication',
        },
        {
          'id': 'q9',
          'text': 'Does the child prefer written over spoken communication?',
          'area': 'Communication',
        },
        {
          'id': 'q10',
          'text': 'Does the child respond positively to supportive speaking environments?',
          'area': 'Speaking Confidence',
          'reversed': true,
        },
      ];
}
