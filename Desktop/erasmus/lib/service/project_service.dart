import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ProjectService {
  static Future<List<dynamic>> loadProjectsFromAsset(String fileName) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/$fileName');
      return jsonDecode(jsonString);
    } catch (e) {
      throw Exception("Yerel JSON dosyası okunamadı: $e");
    }
  }

  static Future<List<dynamic>> fetchProjectsFromAPI({String endpoint = ApiConfig.projectsEndpoint}) async {
    final uri = await ApiConfig.uri(endpoint);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        final safeBody = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
        throw Exception('API request failed: ${response.statusCode} ${uri.toString()} - $safeBody');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List<dynamic>) {
        throw Exception('API response invalid: expected JSON array from ${uri.toString()}');
      }
      return decoded;
    } catch (e) {
      throw Exception('API request error: ${uri.toString()} - $e');
    }
  }
}
