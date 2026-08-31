import '../models/communication_result.dart';
import '../mock/component4_mock_data.dart';

class CommunicationScoreService {
  Future<CommunicationAnalysisResult> analyzeRecording(String recordingPath) async {
    await Future.delayed(const Duration(seconds: 4)); // Simulate analysis delay
    return Component4MockData.mockResult;
  }
}
