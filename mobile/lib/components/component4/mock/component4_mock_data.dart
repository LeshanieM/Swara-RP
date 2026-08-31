import '../models/communication_assessment.dart';
import '../models/communication_topic.dart';
import '../models/communication_result.dart';

class Component4MockData {
  static final mockAssessment = CommunicationAssessment(
    age: 10,
    severity: "Moderate",
    stutteringType: "Repetition",
    physicalBehaviorScore: 61,
    therapistScore: 70,
  );

  static final mockTopics = [
    CommunicationTopic(
      id: "t_animal",
      title: "My Favorite Animal",
      sinhalaTitle: "මම කැමතිම සතා",
      description: "Tell me about your favorite animal.",
      sinhalaDescription: "ඔයා කැමතිම සතා ගැන කියන්න.",
      difficulty: 1,
      minimumAge: 4,
      maximumAge: 7,
      image: "🐘",
      prompts: [
        "What animal do you like?",
        "What does it look like?",
        "What does it do?",
        "Why do you like it?",
      ],
      sinhalaPrompts: [
        "ඔයා මොන සතාටද කැමති?",
        "ඒ සතා පෙනුමෙන් කොහොමද?",
        "ඒ සතා මොනවද කරන්නේ?",
        "ඇයි ඔයා ඒ සතාට කැමති?",
      ],
    ),
    CommunicationTopic(
      id: "t_zoo",
      title: "A Day at the Zoo",
      sinhalaTitle: "සත්තු වත්තේ දවසක්",
      description: "Imagine you went to the zoo.",
      sinhalaDescription: "අද ඔයා සත්තු වත්තකට ගියා කියලා හිතන්න.",
      difficulty: 2,
      minimumAge: 7,
      maximumAge: 10,
      image: "🦒",
      prompts: [
        "What did you see?",
        "What happened?",
        "What was your favorite part?",
      ],
      sinhalaPrompts: [
        "ඔයා මොනවා දැක්කද?",
        "මොකද වුණේ?",
        "ඔයා වැඩිපුරම කැමති වුණේ මොකටද?",
      ],
    ),
    CommunicationTopic(
      id: "t_adventure",
      title: "The Unexpected Adventure",
      sinhalaTitle: "අපේක්ෂා නොකළ චාරිකාව",
      description: "Imagine you were cycling home from school when something unexpected happened.",
      sinhalaDescription: "පාසලේ ඉඳන් ගෙදර එනකොට හිතපු නැති දෙයක් වුණා කියලා හිතන්න.",
      difficulty: 3,
      minimumAge: 11,
      maximumAge: 15,
      image: "🚲",
      prompts: [
        "Tell me the whole story.",
      ],
      sinhalaPrompts: [
        "සම්පූර්ණ කතාවම මට කියන්න.",
      ],
    ),
  ];

  static final mockResult = CommunicationAnalysisResult(
    speechDuration: const Duration(minutes: 1, seconds: 12),
    speechRate: 2.8,
    pauseFrequency: 7,
    meanPauseDuration: 1.1,
    responseLatency: 2.4,
    stutteringEvents: 8,
    mlu: 4.2,
    lexicalDiversity: 0.61,
    utteranceCount: 18,
    averageUtteranceLength: 4.2,
    topicRelevance: 88.0,
    informationContent: 82.0,
    responseCompleteness: 90.0,
    storyOrganization: 78.0,
    communicationPerformanceScore: 84,
    speakingParticipationScore: 86,
    languageExpressionScore: 80,
    topicCompletionScore: 90,
    storyOrganizationScore: 78,
  );
}
