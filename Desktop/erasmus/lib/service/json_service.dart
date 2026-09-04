import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'api_config.dart';

class JsonService {
  static Future<List<dynamic>> loadProjectsFromAsset(String fileName) async {
    try {
      final String response = await rootBundle.loadString('assets/$fileName');
      return jsonDecode(response);
    } catch (e) {
      throw Exception("Yerel JSON dosyası okunamadı: $e");
    }
  }

  static Future<List<dynamic>> fetchProjectsFromAPI({String endpoint = 'projects'}) async {
    final uri = await ApiConfig.uri(endpoint);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        final safeBody = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
        throw Exception('API request failed: ${response.statusCode} ${uri.toString()} - $safeBody');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) {
        throw Exception('API response invalid: expected JSON array from ${uri.toString()}');
      }
      return decoded;
    } catch (e) {
      throw Exception('API request error: ${uri.toString()} - $e');
    }
  }
}
