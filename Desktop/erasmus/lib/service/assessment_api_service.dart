import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:erasmus_simulasyon/models/english_placement_result.dart';
import 'package:erasmus_simulasyon/service/api_config.dart';

class AssessmentApiService {
  static Future<int> startEnglishPlacementSession({
    required String userEmail,
    required String userName,
    required String userGender,
    required Map<String, dynamic>? selectedProject,
  }) async {
    final uri = await ApiConfig.uri(ApiConfig.assessmentSessionsEndpoint);

    final project = selectedProject != null && selectedProject.isNotEmpty
        ? {
            'projectId': selectedProject['projectId']?.toString().trim() ?? '',
            'title': selectedProject['title']?.toString().trim() ?? '',
            'sourceName': selectedProject['sourceName']?.toString().trim() ?? '',
            'sourceUrl': selectedProject['sourceUrl']?.toString().trim() ?? '',
          }
        : null;

    final body = jsonEncode({
      'user': {
        'email': userEmail.trim(),
        'name': userName.trim(),
        'gender': userGender.trim(),
      },
      'challengeType': 'english_placement',
      'project': project,
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final safeBody = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
      throw Exception('API error: ${response.statusCode} ${uri.toString()} - $safeBody');
    }
    if (decoded is Map<String, dynamic>) {
      final success = decoded['success'];
      final status = decoded['status']?.toString().trim();
      final sessionIdRaw = decoded['sessionId'];
      if (success == true && status == 'started' && sessionIdRaw != null) {
        if (sessionIdRaw is int && sessionIdRaw > 0) {
          return sessionIdRaw;
        }
        if (sessionIdRaw is String) {
          final parsed = int.tryParse(sessionIdRaw);
          if (parsed != null && parsed > 0) {
            return parsed;
          }
        }
      }
    }
    throw Exception('Unexpected API response: $decoded');
  }

  static Future<Map<String, dynamic>> completeEnglishPlacementSession({
    required int sessionId,
    required EnglishPlacementResult result,
    required List<Map<String, dynamic>> answers,
    required String aiFeedback,
    required String feedbackSource,
  }) async {
    final uri = await ApiConfig.uri(ApiConfig.assessmentSessionResultEndpoint(sessionId));

    final body = jsonEncode({
      'result': {
        'estimatedLevel': result.estimatedLevel,
        'percentage': result.percentage,
        'correctAnswers': result.correctAnswers,
        'incorrectAnswers': result.incorrectAnswers,
        'earnedWeightedScore': result.earnedWeightedScore,
        'maximumWeightedScore': result.maximumWeightedScore,
        'skillScores': result.skillScores,
        'strengths': result.strengths,
        'weaknesses': result.weaknesses,
        'aiFeedback': aiFeedback,
        'feedbackSource': feedbackSource,
        'aiModel': null,
      },
      'answers': answers,
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      final safeBody = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
      throw Exception('API error: ${response.statusCode} ${uri.toString()} - $safeBody');
    }
    return decoded as Map<String, dynamic>;
  }
}
