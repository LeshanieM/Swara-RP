class CommunicationTopic {
  final String id;
  final String title;
  final String sinhalaTitle;
  final String description;
  final String sinhalaDescription;
  final int difficulty;
  final int minimumAge;
  final int maximumAge;
  final String image;
  final List<String> prompts;
  final List<String> sinhalaPrompts;

  CommunicationTopic({
    required this.id,
    required this.title,
    required this.sinhalaTitle,
    required this.description,
    required this.sinhalaDescription,
    required this.difficulty,
    required this.minimumAge,
    required this.maximumAge,
    required this.image,
    required this.prompts,
    required this.sinhalaPrompts,
  });
}
