import '../models/communication_result.dart';
import '../models/communication_topic.dart';

/// Local sample data used while Component 4 is not connected to the API.
class Component4MockData {
  static final CommunicationAnalysisResult mockResult =
      CommunicationAnalysisResult(
    speechDuration: const Duration(minutes: 1),
    speechRate: 92,
    pauseFrequency: 4,
    meanPauseDuration: 0.8,
    responseLatency: 1.2,
    stutteringEvents: 2,
    mlu: 5.2,
    lexicalDiversity: 0.68,
    utteranceCount: 12,
    averageUtteranceLength: 5.2,
    topicRelevance: 0.82,
    informationContent: 0.75,
    responseCompleteness: 0.8,
    storyOrganization: 0.72,
    communicationPerformanceScore: 78,
    speakingParticipationScore: 80,
    languageExpressionScore: 76,
    topicCompletionScore: 78,
    storyOrganizationScore: 74,
  );

  static final List<CommunicationTopic> mockTopics = [
    CommunicationTopic(
      id: 't_animal',
      title: 'My Favorite Animal',
      sinhalaTitle: 'මගේ ප්‍රියතම සත්වයා',
      description: 'Talk about an animal you like.',
      sinhalaDescription: 'ඔබ කැමති සතෙකු ගැන කතා කරන්න.',
      difficulty: 1,
      minimumAge: 5,
      maximumAge: 7,
      image: 'assets/images/component3/lion_mascot.jpg',
      prompts: ['What does it look like?', 'Where does it live?'],
      sinhalaPrompts: ['එය මොන වගේද?', 'එය ජීවත් වන්නේ කොහේද?'],
    ),
    CommunicationTopic(
      id: 't_zoo',
      title: 'A Day at the Zoo',
      sinhalaTitle: 'සත්වෝද්‍යානයේ දවසක්',
      description: 'Describe a visit to the zoo.',
      sinhalaDescription: 'සත්වෝද්‍යානයේ සංචාරයක් විස්තර කරන්න.',
      difficulty: 2,
      minimumAge: 8,
      maximumAge: 10,
      image: 'assets/images/component4/c4_picture_story.png',
      prompts: ['Which animals did you see?', 'What was your favorite part?'],
      sinhalaPrompts: ['ඔබ දුටු සතුන් මොනවාද?', 'ඔබ වඩාත්ම කැමති වූයේ කුමකටද?'],
    ),
    CommunicationTopic(
      id: 't_adventure',
      title: 'A Great Adventure',
      sinhalaTitle: 'අගනා වික්‍රමයක්',
      description: 'Tell a story about an exciting adventure.',
      sinhalaDescription: 'රසවත් වික්‍රමයක් ගැන කතාවක් කියන්න.',
      difficulty: 3,
      minimumAge: 11,
      maximumAge: 14,
      image: 'assets/images/component4/c4_picture_story.png',
      prompts: ['Where did it begin?', 'How did the story end?'],
      sinhalaPrompts: ['එය ආරම්භ වූයේ කොහේද?', 'කතාව අවසන් වූයේ කෙසේද?'],
    ),
  ];
}
