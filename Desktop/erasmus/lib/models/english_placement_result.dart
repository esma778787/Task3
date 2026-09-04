class EnglishPlacementResult {
  final String estimatedLevel;
  final double percentage;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final Map<String, int> skillScores;
  final List<String> strengths;
  final List<String> weaknesses;
  final double earnedWeightedScore;
  final double maximumWeightedScore;
  final String aiFeedback;

  EnglishPlacementResult({
    required this.estimatedLevel,
    required this.percentage,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skillScores,
    required this.strengths,
    required this.weaknesses,
    required this.earnedWeightedScore,
    required this.maximumWeightedScore,
    required this.aiFeedback,
  });
}
