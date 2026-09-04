import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:erasmus_simulasyon/models/english_question.dart';
import 'package:erasmus_simulasyon/models/english_placement_result.dart';

class EnglishPlacementAnswer {
  final EnglishPlacementQuestion question;
  final bool isCorrect;
  final String selectedAnswer;
  final int? selectedOptionIndex;
  final String? textAnswer;

  EnglishPlacementAnswer({
    required this.question,
    required this.isCorrect,
    required this.selectedAnswer,
    this.selectedOptionIndex,
    this.textAnswer,
  });
}

class EnglishPlacementService {
  static const int defaultTestLength = 30;
  static const Map<String, int> _levelWeights = {
    'A2': 1,
    'B1': 2,
    'B2': 3,
  };

  static int levelWeight(String level) {
    return _levelWeights[level] ?? 1;
  }

  static const Map<String, String> _skillNames = {
    'grammar': 'Grammar',
    'vocabulary': 'Vocabulary',
    'reading': 'Reading',
    'communication': 'Communication',
    'use_of_english': 'Use of English',
  };

  static Future<List<EnglishPlacementQuestion>> loadQuestions() async {
    final jsonString = await rootBundle.loadString('assets/data/english_placement_question_bank.json');
    final data = jsonDecode(jsonString) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(EnglishPlacementQuestion.fromJson)
        .toList();
  }

  static List<EnglishPlacementQuestion> preparePlacementTest(
    List<EnglishPlacementQuestion> bank, {
    int totalQuestions = defaultTestLength,
  }) {
    final random = Random(12345);
    final a2 = bank.where((q) => q.level == 'A2').toList()..shuffle(random);
    final b1 = bank.where((q) => q.level == 'B1').toList()..shuffle(random);
    final b2 = bank.where((q) => q.level == 'B2').toList()..shuffle(random);

    const int a2Count = 10;
    const int b1Count = 10;
    const int b2Count = 10;

    final selected = <EnglishPlacementQuestion>[];
    selected.addAll(a2.take(a2Count));
    selected.addAll(b1.take(b1Count));
    selected.addAll(b2.take(b2Count));
    selected.shuffle(random);

    if (selected.length > totalQuestions) {
      return selected.take(totalQuestions).toList();
    }
    return selected;
  }

  static EnglishPlacementResult calculateResult(List<EnglishPlacementAnswer> answers) {
    final totalQuestions = answers.length;
    final correctAnswers = answers.where((a) => a.isCorrect).length;
    final incorrectAnswers = totalQuestions - correctAnswers;

    double earnedWeightedScore = 0;
    double maximumWeightedScore = 0;
    final Map<String, double> earnedBySkill = {};
    final Map<String, double> maxBySkill = {};

    for (final answer in answers) {
      final question = answer.question;
      final levelWeight = _levelWeights[question.level] ?? 1;
      final questionWeight = question.weight > 0 ? question.weight : 1;
      final weightedValue = questionWeight * levelWeight;

      maximumWeightedScore += weightedValue;
      maxBySkill[question.skill] = (maxBySkill[question.skill] ?? 0) + weightedValue;
      if (answer.isCorrect) {
        earnedWeightedScore += weightedValue;
        earnedBySkill[question.skill] = (earnedBySkill[question.skill] ?? 0) + weightedValue;
      }
    }

    final percentage = maximumWeightedScore == 0
        ? 0.0
        : (earnedWeightedScore / maximumWeightedScore) * 100;

    final estimatedLevel = _determineEstimatedLevel(percentage);

    final skillScores = <String, int>{
      'grammar': 0,
      'vocabulary': 0,
      'reading': 0,
      'communication': 0,
      'useOfEnglish': 0,
    };
    final strengths = <String>[];
    final weaknesses = <String>[];

    for (final entry in _skillNames.entries) {
      final skillKey = entry.key;
      final mappedKey = skillKey == 'use_of_english' ? 'useOfEnglish' : skillKey;
      final earned = earnedBySkill[skillKey] ?? 0;
      final maximum = maxBySkill[skillKey] ?? 0;
      final score = maximum == 0 ? 0 : ((earned / maximum) * 100).round();
      skillScores[mappedKey] = score;

      if (score >= 70) {
        strengths.add(entry.value);
      } else if (score < 50) {
        weaknesses.add(entry.value);
      }
    }

    return EnglishPlacementResult(
      estimatedLevel: estimatedLevel,
      percentage: double.parse(percentage.toStringAsFixed(1)),
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      skillScores: skillScores,
      strengths: strengths,
      weaknesses: weaknesses,
      earnedWeightedScore: earnedWeightedScore,
      maximumWeightedScore: maximumWeightedScore,
      aiFeedback: '',
    );
  }

  static String _determineEstimatedLevel(double percentage) {
    if (percentage < 35) {
      return 'Pre-A2 / A1';
    } else if (percentage < 55) {
      return 'A2';
    } else if (percentage < 75) {
      return 'B1';
    }
    return 'B2';
  }
}
