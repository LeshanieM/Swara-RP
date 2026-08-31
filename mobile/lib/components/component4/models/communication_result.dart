class CommunicationAnalysisResult {
  final String analysisStatus;

  // Speech
  final Duration speechDuration;
  final double speechRate;
  final int pauseFrequency;
  final double meanPauseDuration;
  final double responseLatency;
  final int stutteringEvents;

  // Language
  final double mlu;
  final double lexicalDiversity;
  final int utteranceCount;
  final double averageUtteranceLength;
  
  // Communication
  final double topicRelevance;
  final double informationContent;
  final double responseCompleteness;
  final double storyOrganization;
  final int communicationPerformanceScore;
  
  // Scores Breakdown
  final int speakingParticipationScore;
  final int languageExpressionScore;
  final int topicCompletionScore;
  final int storyOrganizationScore;

  CommunicationAnalysisResult({
    this.analysisStatus = 'completed',
    required this.speechDuration,
    required this.speechRate,
    required this.pauseFrequency,
    required this.meanPauseDuration,
    required this.responseLatency,
    required this.stutteringEvents,
    required this.mlu,
    required this.lexicalDiversity,
    required this.utteranceCount,
    required this.averageUtteranceLength,
    required this.topicRelevance,
    required this.informationContent,
    required this.responseCompleteness,
    required this.storyOrganization,
    required this.communicationPerformanceScore,
    required this.speakingParticipationScore,
    required this.languageExpressionScore,
    required this.topicCompletionScore,
    required this.storyOrganizationScore,
  });
}
