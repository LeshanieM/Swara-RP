import '../models/activity_model.dart';
import '../models/assessment_model.dart';

class ActivityRecommendationEngine {
  static List<ActivityModel> allActivities = [
    ActivityModel(
      id: 'breathing', 
      nameEn: 'Calm Breathing', 
      nameSi: 'සන්සුන් හුස්මක් ගමු 🫁', 
      purposeEn: 'Breathing practice.', 
      instructionEn: 'Breathe in slowly and breathe out slowly.', 
      instructionSi: 'සෙමින් හුස්ම ගන්න, සෙමින් හුස්ම පිට කරන්න.'
    ),
    ActivityModel(
      id: 'relaxation', 
      nameEn: 'Relaxation', 
      nameSi: 'සන්සුන් වෙමු 🧘', 
      purposeEn: 'Reduce physical tension.', 
      instructionEn: 'Relax your shoulders. Take a slow breath. Relax your face.', 
      instructionSi: 'උරහිස් ලිහිල් කරන්න. සෙමින් හුස්මක් ගන්න. මුහුණේ මාංශ පේශී ලිහිල් කරන්න.'
    ),
    ActivityModel(
      id: 'easy_speaking', 
      nameEn: 'Easy Speaking', 
      nameSi: 'පහසුවෙන් කතා කරමු 💬', 
      purposeEn: 'Simple questions.', 
      instructionEn: 'What is your favourite food?', 
      instructionSi: 'ඔයා කැමතිම කෑම මොකක්ද?'
    ),
    ActivityModel(
      id: 'picture_speaking', 
      nameEn: 'Picture Speaking', 
      nameSi: 'පින්තූර කතා 🖼️', 
      purposeEn: 'Describe picture.', 
      instructionEn: 'Tell me what is happening in this picture. (🎨 🏫 ⚽)', 
      instructionSi: 'මේ පින්තූරයේ සිදුවෙන්නේ මොකක්ද කියලා කියන්න. (🎨 🏫 ⚽)'
    ),
  ];

  static List<ActivityModel> generateActivityPlan(AssessmentData data) {
    // Return exactly the 4 activities requested by the user
    return List.from(allActivities);
  }
}
