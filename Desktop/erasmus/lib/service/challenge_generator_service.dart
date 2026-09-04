import 'package:erasmus_simulasyon/models/game_scenarios.dart' as default_scenarios;

class ChallengeGeneratorService {
  static const Map<String, List<String>> _themeKeywords = {
    'environment': ['environment', 'çevre', 'sustain', 'waste', 'recycle', 'eco', 'sustainable'],
    'children': ['children', 'child', 'kids', 'childcare', 'school', 'çocuk'],
    'education': ['education', 'training', 'kurs', 'learning', 'teach', 'öğrenme'],
    'media': ['media', 'social', 'content', 'video', 'blog', 'social media', 'medya'],
    'volunteering': ['volunteer', 'gönüllü', 'volunteering', 'community', 'youth'],
  };

  // Simple themed scenarios. If you need richer sets, swap with more items or source from default_scenarios.
  static final Map<String, List<Map<String, dynamic>>> _themedScenarios = {
    'environment': [
      {
        'title': 'Environmental Awareness',
        'question': 'The project aims to reduce environmental waste. Which steps would you propose?',
        'options': [
          {'text': 'Set up recycling stations and start a waste tracking system.', 'contrib': {'teamwork':2,'communication':1,'problemSolving':2,'motivation':1}},
          {'text': 'Organize a local awareness campaign for the community.', 'contrib': {'communication':3,'leadership':1,'motivation':2}},
          {'text': 'Follow the existing plan without changes.', 'contrib': {'teamwork':0,'communication':0}},
        ]
      },
      {
        'title': 'Nature Conservation Activity',
        'question': 'A nature walk and cleanup is planned. What would be your responsibility?',
        'options': [
          {'text': 'Plan safety and route, coordinate volunteers.', 'contrib': {'responsibility':3,'leadership':2,'teamwork':2}},
          {'text': 'Participate only and not take a leadership role.', 'contrib': {'teamwork':1}},
          {'text': 'I would not participate; I have other priorities.', 'contrib': {'teamwork':0}},
        ]
      }
    ],
    'children': [
      {
        'title': 'Working with Children',
        'question': 'You are organizing activities for young children; which approaches are appropriate?',
        'options': [
          {'text': 'Use play-based learning and group activities.', 'contrib': {'communication':3,'teamwork':2,'motivation':2}},
          {'text': 'Proceed mainly with theoretical lectures.', 'contrib': {'communication':1}},
          {'text': 'Be a passive observer.', 'contrib': {'teamwork':0}},
        ]
      }
    ],
    'education': [
      {
        'title': 'Training Module Design',
        'question': 'How would you plan content for a new training course?',
        'options': [
          {'text': 'Define learning objectives and break materials into modules.', 'contrib': {'responsibility':3,'leadership':2,'problemSolving':1}},
          {'text': 'Use ready-made content as-is.', 'contrib': {'responsibility':1}},
          {'text': 'Teach everything through hands-on practice.', 'contrib': {'motivation':2,'adaptability':1}},
        ]
      }
    ],
    'media': [
      {
        'title': 'Social Media Strategy',
        'question': 'How would you increase the project visibility on social media?',
        'options': [
          {'text': 'Prepare a content calendar and form small volunteer teams.', 'contrib': {'leadership':2,'communication':3}},
          {'text': 'Propose an advertising budget.', 'contrib': {'problemSolving':2}},
          {'text': 'Only share existing content.', 'contrib': {'teamwork':0}},
        ]
      }
    ],
    'volunteering': default_scenarios.gameScenarios,
  };

  static List<Map<String, dynamic>> getScenariosForProject({
    required String title,
    required String description,
    required String link,
    required String category,
  }){

    // 1. Try matching description keywords
    for (final entry in _themeKeywords.entries) {
      for (final kw in entry.value) {
        if (description.toLowerCase().contains(kw)) return _themedScenarios[entry.key] ?? _themedScenarios['volunteering']!;
      }
    }

    // 2. Title
    for (final entry in _themeKeywords.entries) {
      for (final kw in entry.value) {
        if (title.toLowerCase().contains(kw)) return _themedScenarios[entry.key] ?? _themedScenarios['volunteering']!;
      }
    }

    // 3. Link slug
    try {
      final slug = Uri.parse(link).path.toLowerCase();
      for (final entry in _themeKeywords.entries) {
        for (final kw in entry.value) {
          if (slug.contains(kw)) return _themedScenarios[entry.key] ?? _themedScenarios['volunteering']!;
        }
      }
    } catch (_) {}

    // 4. Category fallback
    final cat = category.toLowerCase();
    if (cat.contains('çevre') || cat.contains('environment')) return _themedScenarios['environment']!;
    if (cat.contains('çocuk') || cat.contains('child')) return _themedScenarios['children']!;
    if (cat.contains('eğitim') || cat.contains('education')) return _themedScenarios['education']!;
    if (cat.contains('medya') || cat.contains('media')) return _themedScenarios['media']!;

    // Default
    return _themedScenarios['volunteering']!;
  }
}
