import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:erasmus_simulasyon/service/challenge_generator_service.dart';
import 'package:erasmus_simulasyon/models/game_scenarios.dart' as default_scenarios;

final Logger logger = Logger();

class OpenRouterService {
  static const _url = 'https://openrouter.ai/api/v1/chat/completions';
  static const _headersBase = {
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://yourapp.com',
    'X-Title': 'Erasmus Simulation',
  };

  static Future<String> generateCV({
    required String name,
    required String category,
    required String gender,
    required String skills,
    required String language,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    logger.i("🔐 DEBUG: OpenRouter API KEY loaded");
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('OpenRouter API key is not configured. Set OPENROUTER_API_KEY in your .env');
    }

    final prompt = '''
Ad: $name
Cinsiyet: $gender
Kategori: $category
Yetenekler: $skills
Dil: $language

Yukarıdaki bilgilere dayanarak, Europass formatına uygun kısa ama etkili bir özgeçmiş (CV) metni hazırla.
- Dil tercihi "$language" olarak kullanılmalı.
- Cinsiyete uygun hitap kullanılmalı.
- "$category" konusuna ve "$skills" yeteneklerine uygun bir profil yazısı öner.
- Erasmus+ başvurusuna uygun, samimi ama profesyonel bir dille yazılmış olmalı.
''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        ..._headersBase,
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content": "Sen bir Erasmus uzmanısın. Başvuru yapan kişiye uygun dilde, etkileyici ve projeye özgü Europass formatında CV oluşturuyorsun."
          },
          {
            "role": "user",
            "content": prompt
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      logger.e("API Hatası: ${response.statusCode} - ${response.body}");
      throw Exception("OpenRouter API hatası: ${response.body}");
    }
  }

  static String cleanJsonContent(String content) {
    return content
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
  }

  static bool containsTurkishCharacters(String value) {
    return RegExp(r'[çğıöşüÇĞİÖŞÜ]').hasMatch(value);
  }

  static bool _parsedScenariosContainTurkish(List<Map<String, dynamic>> parsed) {
    for (final s in parsed) {
      final title = s['title']?.toString() ?? '';
      final question = s['question']?.toString() ?? '';
      if (containsTurkishCharacters(title) || containsTurkishCharacters(question)) return true;
      final options = s['options'] as List?;
      if (options != null) {
        for (final o in options) {
          final text = o['text']?.toString() ?? '';
          if (containsTurkishCharacters(text)) return true;
        }
      }
    }
    return false;
  }

  static List<Map<String, dynamic>> parseChallengeScenarios(String rawContent) {
    final cleaned = cleanJsonContent(rawContent);
    final dynamic decoded = jsonDecode(cleaned);
    dynamic scenarios = decoded;
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('scenarios')) {
        scenarios = decoded['scenarios'];
      } else if (decoded.containsKey('data')) {
        scenarios = decoded['data'];
      }
    }
    if (scenarios is! List || scenarios.isEmpty) {
      throw Exception('AI response did not contain a valid scenarios list.');
    }

    final List<Map<String, dynamic>> parsed = [];
    for (final item in scenarios) {
      if (item is! Map<String, dynamic>) {
        throw Exception('Each scenario must be an object.');
      }
      final title = item['title'];
      final question = item['question'];
      final options = item['options'];
      if (title is! String || question is! String || options is! List) {
        throw Exception('Each scenario must include title, question, and options.');
      }
      final List<Map<String, dynamic>> normalizedOptions = [];
      for (final option in options) {
        if (option is! Map<String, dynamic>) {
          throw Exception('Each option must be an object.');
        }
        final text = option['text'];
        final contrib = option['contrib'];
        if (text is! String || contrib is! Map<String, dynamic>) {
          throw Exception('Each option must include text and contrib map.');
        }
        final Map<String, int> normalizedContrib = {};
        contrib.forEach((key, value) {
          if (value is int) {
            normalizedContrib[key] = value;
          } else if (value is num) {
            normalizedContrib[key] = value.toInt();
          } else if (value is String) {
            final parsedValue = int.tryParse(value);
            if (parsedValue == null) {
              throw Exception('Contrib values must be numeric.');
            }
            normalizedContrib[key] = parsedValue;
          } else {
            throw Exception('Contrib values must be numeric.');
          }
        });
        normalizedOptions.add({
          'text': text,
          'contrib': normalizedContrib,
        });
      }
      parsed.add({
        'title': title,
        'question': question,
        'options': normalizedOptions,
      });
    }
    return parsed;
  }

  static Future<List<Map<String, dynamic>>> generateProjectChallenges({
    required String projectTitle,
    required String projectDescription,
    required String category,
    required String projectLink,
    required String userInterests,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('OpenRouter API key is not configured.');
    }
    if (projectDescription.trim().isEmpty) {
      throw Exception(
        'Project description is empty. Project-specific challenges cannot be generated.',
      );
    }
    // Avoid calling paid API when description is too short
    if (projectDescription.trim().length < 150) {
      throw Exception('Project description too short for AI generation. Using fallback.');
    }

    final prompt = '''
PROJECT TITLE:
$projectTitle

PROJECT CATEGORY:
$category

PROJECT LINK:
$projectLink

PROJECT DESCRIPTION:
$projectDescription

APPLICANT INTERESTS:
$userInterests

Return a valid JSON array of challenge scenarios only. Do not send markdown or extra text.
Each scenario must include:
- title
- question
- options (array)
Each option must include:
- text
- contrib (map of competency scores with integer values).''';

    // Ensure AI outputs are entirely English
    const systemContent = 'You are an Erasmus+ project evaluator and scenario designer. Generate realistic multiple-choice decision scenarios specifically for the selected Erasmus+ project. Use the full project description as the primary source. Do not generate generic Erasmus questions. Do not generate the same standard questions for unrelated projects. Only return valid JSON. All titles, questions, options and explanations must be entirely in English. Do not output Turkish.';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        ..._headersBase,
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'openai/gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': systemContent,
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawContent = data['choices'][0]['message']['content'] as String?;
      if (rawContent == null || rawContent.trim().isEmpty) {
        throw Exception('OpenRouter response content was empty.');
      }

      // First parse
      List<Map<String, dynamic>> parsed;
      try {
        parsed = parseChallengeScenarios(rawContent);
      } catch (e) {
        throw Exception('Failed to parse AI response: $e');
      }

      // Validate English-only; if Turkish detected, retry once with regeneration instruction
      if (_parsedScenariosContainTurkish(parsed)) {
        logger.w('AI response contained non-English text; retrying once for English-only output.');
        final regenResponse = await http.post(
          Uri.parse(_url),
          headers: {
            ..._headersBase,
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'openai/gpt-3.5-turbo',
            'messages': [
              {
                'role': 'system',
                'content': systemContent,
              },
              {
                'role': 'user',
                'content': '$prompt\n\nYour previous response contained non-English text. Regenerate the complete JSON response entirely in English. Return only valid JSON.'
              }
            ],
          }),
        );

        if (regenResponse.statusCode == 200) {
          final regenData = jsonDecode(regenResponse.body);
          final regenRaw = regenData['choices'][0]['message']['content'] as String?;
          if (regenRaw != null && regenRaw.trim().isNotEmpty) {
            try {
              final regenParsed = parseChallengeScenarios(regenRaw);
              if (!_parsedScenariosContainTurkish(regenParsed)) {
                return regenParsed;
              }
            } catch (_) {}
          }
        }

        // If still failing, fallback to static scenarios
        logger.w('AI regeneration failed or still non-English; using static fallback scenarios.');
        return ChallengeGeneratorService.getScenariosForProject(
          title: projectTitle,
          description: projectDescription,
          link: projectLink,
          category: category,
        );
      }

      return parsed;
    } else {
      logger.e('API Hatası: ${response.statusCode} - ${response.body}');
      throw Exception('OpenRouter API hatası: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> generateEnglishSkillsChallenges({
    required String userInterests,
    required String name,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('OpenRouter API key is not configured.');
    }

    const prompt = '''
Create exactly 7 English language assessment questions.

All content must be entirely in English.

The questions should assess CEFR B1–B2 grammar, vocabulary, reading comprehension and practical communication.

Do not assess whether the applicant is suitable for the selected project.

Each question must contain exactly 3 answer options.

Exactly one option must be correct.

Return valid JSON only. The JSON must be an array of scenarios. Each scenario must include:
- title
- question
- options (array of objects with: text, contrib)
- correctOptionIndex (integer 0..2)
- explanation
- skillType (one of: grammar, vocabulary, reading, communication)

For contrib, include a map with at least the key 'language' and integer values where the correct option has a higher language score (e.g., 3) and incorrect options have 0.
''';

    const systemContent = 'You are an English language test designer. Create CEFR B1-B2 level multiple-choice questions in English only. Return valid JSON only.';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        ..._headersBase,
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'openai/gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': systemContent,
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawContent = data['choices'][0]['message']['content'] as String?;
      if (rawContent == null || rawContent.trim().isEmpty) {
        throw Exception('OpenRouter response content was empty.');
      }

      // Try parse
      List<Map<String, dynamic>> parsed;
      try {
        parsed = parseChallengeScenarios(rawContent);
      } catch (e) {
        parsed = [];
      }

      if (parsed.isEmpty || _parsedScenariosContainTurkish(parsed)) {
        // Retry once
        logger.w('English skills response invalid or non-English; retrying once.');
        final regenResponse = await http.post(
          Uri.parse(_url),
          headers: {
            ..._headersBase,
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'openai/gpt-3.5-turbo',
            'messages': [
              {
                'role': 'system',
                'content': systemContent,
              },
              {
                'role': 'user',
                'content': '$prompt\n\nYour previous response contained non-English text or invalid JSON. Regenerate the complete JSON response entirely in English and return only valid JSON.'
              }
            ],
          }),
        );

        if (regenResponse.statusCode == 200) {
          final regenData = jsonDecode(regenResponse.body);
          final regenRaw = regenData['choices'][0]['message']['content'] as String?;
          if (regenRaw != null && regenRaw.trim().isNotEmpty) {
            try {
              final regenParsed = parseChallengeScenarios(regenRaw);
              if (!_parsedScenariosContainTurkish(regenParsed) && regenParsed.length == 7) {
                return regenParsed;
              }
            } catch (_) {}
          }
        }

        // fallback: use default English static scenarios (map to ensure 7 items)
        logger.w('Using static English fallback for English Skills test.');
        final fallback = <Map<String, dynamic>>[];
        for (int i = 0; i < 7; i++) {
          final base = default_scenarios.gameScenarios[i % default_scenarios.gameScenarios.length];
          // Map options to include 'contrib' with language scoring heuristic
          final options = (base['options'] as List).map((o) {
            final text = o['text'] as String;
            return {
              'text': text,
              'contrib': {'language': 0},
            };
          }).toList();
          // mark first option as 'correct' in contrib
          if (options.isNotEmpty) {
            options[0]['contrib'] = {'language': 3};
          }
          fallback.add({
            'title': base['title'],
            'question': base['question'],
            'options': options,
          });
        }
        return fallback;
      }

      return parsed;
    } else {
      logger.e('API Hatası: ${response.statusCode} - ${response.body}');
      throw Exception('OpenRouter API hatası: ${response.body}');
    }
  }

  static Future<String> generateMotivationLetter({
    required String name,
    required String category,
    required String projectDescription,
    required String interests,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    logger.i("🔐 DEBUG: OpenRouter API KEY loaded");
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('OpenRouter API key is not configured. Set OPENROUTER_API_KEY in your .env');
    }

    final prompt = '''
Ad: $name
Kategori: $category
Proje Açıklaması: $projectDescription
Kendi Tanıtımı: $interests

Lütfen bu bilgilerle Erasmus+ için etkileyici, özgün ve profesyonel bir motivasyon mektubu yaz.
Dil: İngilizce
Format: Paragraflı, kişisel ama samimi
Amacı: Projeye kabul edilme isteğini etkili şekilde ifade etsin.
''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        ..._headersBase,
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content": "Sen bir Erasmus başvuru danışmanısın. Kullanıcının tanıtımına ve proje içeriğine göre İngilizce motivasyon mektubu hazırlıyorsun."
          },
          {
            "role": "user",
            "content": prompt
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      logger.e("API Hatası: ${response.statusCode} - ${response.body}");
      throw Exception("OpenRouter API hatası: ${response.body}");
    }
  }

  static Future<String> generateEnglishPlacementFeedback({
    required String estimatedLevel,
    required double percentage,
    required int correctAnswers,
    required int totalQuestions,
    required Map<String, int> skillScores,
    required List<String> weakTopics,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('OpenRouter API key is not configured.');
    }

    const systemContent = '''
You are an English learning advisor.

Explain the learner's English placement result clearly and constructively.

The estimated CEFR level has already been calculated by the application.
Do not change, override or contradict the calculated level.

Write all feedback in English.
Do not claim that this is an official CEFR certificate.
''';

    final weakTopicsText = weakTopics.isEmpty ? 'None' : weakTopics.join(', ');
    final skillLines = skillScores.entries.map((entry) {
      return '${_normalizeSkillLabel(entry.key)} score: ${entry.value}%';
    }).join('\n');

    final userPrompt = '''
Estimated level: $estimatedLevel
Percentage: ${percentage.toStringAsFixed(1)}%
Correct answers: $correctAnswers
Total questions: $totalQuestions
$skillLines
Weak topics: $weakTopicsText

Write feedback using these sections:
Overall Assessment
Strengths
Areas to Improve
Recommended Study Plan
''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        ..._headersBase,
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'openai/gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': systemContent,
          },
          {
            'role': 'user',
            'content': userPrompt,
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw Exception('OpenRouter returned empty feedback.');
      }
      return content.trim();
    }

    logger.e('OpenRouter API error: ${response.statusCode} - ${response.body}');
    throw Exception('OpenRouter API error: ${response.body}');
  }

  static String _normalizeSkillLabel(String skillKey) {
    switch (skillKey) {
      case 'grammar':
        return 'Grammar';
      case 'vocabulary':
        return 'Vocabulary';
      case 'reading':
        return 'Reading';
      case 'communication':
        return 'Communication';
      case 'use_of_english':
        return 'Use of English';
      default:
        return skillKey;
    }
  }

  static Future<String> evaluateApplication({
    required String cv,
    required String motivationLetter,
    required String languageLevel,
    required String note,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    logger.i("🔐 DEBUG: OpenRouter API KEY loaded");
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('OpenRouter API key is not configured. Set OPENROUTER_API_KEY in your .env');
    }

    final prompt = '''
Aşağıdaki başvuru bilgilerini değerlendir:

CV: 
$cv

Motivasyon Mektubu: 
$motivationLetter

Dil Seviyesi: $languageLevel
Açıklama: $note

Lütfen bu başvuru için şu başlıklarda kısa bir değerlendirme yap:
- Güçlü yönler
- Eksikler
- Bu projeye uygunluk
- Genel öneriler

Yanıt Erasmus ruhuna uygun, sade ve samimi olsun.
''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        ..._headersBase,
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content": "Sen bir Erasmus uzmanısın. Başvuru dosyalarını analiz edip değerlendirme yapıyorsun."
          },
          {
            "role": "user",
            "content": prompt
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      logger.e("API Hatası: ${response.statusCode} - ${response.body}");
      throw Exception("OpenRouter API hatası: ${response.body}");
    }
  }
}
