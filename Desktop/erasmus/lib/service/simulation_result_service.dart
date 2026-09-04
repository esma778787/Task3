import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:erasmus_simulasyon/models/simulation_data.dart';
import 'api_config.dart';

class SimulationResultService {
  static String get _endpoint => ApiConfig.simulationResultEndpoint;

  static Future<void> saveSimulationResult({
    required SimulationData simulationData,
    required int score,
    required String feedback,
  }) async {
    final uri = await ApiConfig.uri(_endpoint);
    final body = jsonEncode({
      'Name': simulationData.userName,
      'Gender': simulationData.userGender,
      'Interests': simulationData.userInterests,
      'MotivationLetter': simulationData.generatedMotivationLetter,
      'EuropassCV': simulationData.generatedCV,
      'SelectedProjectTitle': simulationData.selectedProjectTitle.isNotEmpty
          ? simulationData.selectedProjectTitle
          : simulationData.selectedCategory,
      'SelectedProjectDescription': simulationData.projectDescription,
      'SelectedProjectLink': simulationData.selectedProjectLink,
      'Score': score,
      'Feedback': feedback,
      'Category': simulationData.selectedProjectCategory.isNotEmpty
          ? simulationData.selectedProjectCategory
          : simulationData.selectedCategory,
      'LanguageLevel': simulationData.userLanguageLevel,
      'CVLanguage': simulationData.userCVLanguage,
      'AIFeedback': simulationData.aiFeedback,
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final safeBody = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
      throw Exception('Sunucu hatası: ${response.statusCode} ${uri.toString()} - $safeBody');
    }
  }
}
