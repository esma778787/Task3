class EnglishPlacementOption {
  final String text;

  EnglishPlacementOption({required this.text});

  factory EnglishPlacementOption.fromJson(Map<String, dynamic> json) {
    return EnglishPlacementOption(text: json['text']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {
        'text': text,
      };
}

class EnglishPlacementQuestion {
  final String id;
  final String type;
  final String level;
  final String skill;
  final String title;
  final String instruction;
  final String? passageId;
  final String passage;
  final String question;
  final List<EnglishPlacementOption> options;
  final List<String> acceptedAnswers;
  final int? correctOptionIndex;
  final String explanation;
  final int weight;
  final String? sentence;
  final String? keyword;
  final String? audioAsset;
  final String? audioTranscript;

  EnglishPlacementQuestion({
    required this.id,
    required this.type,
    required this.level,
    required this.skill,
    required this.title,
    required this.instruction,
    this.passageId,
    required this.passage,
    required this.question,
    required this.options,
    required this.acceptedAnswers,
    this.correctOptionIndex,
    required this.explanation,
    required this.weight,
    this.sentence,
    this.keyword,
    this.audioAsset,
    this.audioTranscript,
  });

  static const allowedLevels = {'A2', 'B1', 'B2'};
  static const allowedTypes = {
    'notice_meaning',
    'multiple_choice_cloze',
    'vocabulary',
    'open_cloze',
    'word_formation',
    'sentence_transformation',
    'reading_comprehension',
    'gapped_text',
    'multiple_matching',
    'situational_communication',
  };
  static const allowedSkills = {
    'grammar',
    'vocabulary',
    'reading',
    'communication',
    'use_of_english',
  };

  bool get isMultipleChoice {
    return [
      'notice_meaning',
      'multiple_choice_cloze',
      'vocabulary',
      'reading_comprehension',
      'gapped_text',
      'situational_communication',
      'multiple_matching',
    ].contains(type);
  }

  bool get isShortAnswer {
    return ['open_cloze', 'word_formation', 'sentence_transformation'].contains(type);
  }

  bool get hasPassage => passageId != null && passageId!.isNotEmpty;

  factory EnglishPlacementQuestion.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List?;
    return EnglishPlacementQuestion(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      skill: json['skill']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      instruction: json['instruction']?.toString() ?? '',
      passageId: json['passageId']?.toString(),
      passage: json['passage']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: optionsJson != null
          ? optionsJson
              .whereType<Map<String, dynamic>>()
              .map(EnglishPlacementOption.fromJson)
              .toList()
          : [],
      acceptedAnswers: (json['acceptedAnswers'] as List?)
              ?.map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toList() ??
          [],
      correctOptionIndex: json['correctOptionIndex'] is int
          ? json['correctOptionIndex'] as int
          : (json['correctOptionIndex'] is String
              ? int.tryParse(json['correctOptionIndex'] as String)
              : null),
      explanation: json['explanation']?.toString() ?? '',
      weight: json['weight'] is int
          ? json['weight'] as int
          : int.tryParse(json['weight']?.toString() ?? '') ?? 1,
      sentence: json['sentence']?.toString(),
      keyword: json['keyword']?.toString(),
      audioAsset: json['audioAsset']?.toString(),
      audioTranscript: json['audioTranscript']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'level': level,
        'skill': skill,
        'title': title,
        'instruction': instruction,
        'passageId': passageId,
        'passage': passage,
        'question': question,
        'options': options.map((e) => e.toJson()).toList(),
        'acceptedAnswers': acceptedAnswers,
        'correctOptionIndex': correctOptionIndex,
        'explanation': explanation,
        'weight': weight,
        'sentence': sentence,
        'keyword': keyword,
        'audioAsset': audioAsset,
        'audioTranscript': audioTranscript,
      };

  static String normalizeAnswer(String answer) {
    return answer.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool matchesShortAnswer(String answer) {
    final normalized = normalizeAnswer(answer);
    return acceptedAnswers.any((option) => normalizeAnswer(option) == normalized);
  }

  List<String> validate({required Set<String> existingIds, required Set<String> existingQuestions, required Map<String, String> passageMap}) {
    final errors = <String>[];
    if (id.trim().isEmpty) {
      errors.add('ID is empty.');
    } else if (existingIds.contains(id)) {
      errors.add('Duplicate ID "$id".');
    }

    if (question.trim().isEmpty) {
      errors.add('Question text is empty.');
    } else if (existingQuestions.contains(question.trim())) {
      errors.add('Duplicate question text.');
    }

    if (!allowedLevels.contains(level)) {
      errors.add('Invalid level "$level".');
    }
    if (!allowedTypes.contains(type)) {
      errors.add('Invalid type "$type".');
    }
    if (!allowedSkills.contains(skill)) {
      errors.add('Invalid skill "$skill".');
    }
    if (title.trim().isEmpty) {
      errors.add('Title is empty.');
    }
    if (instruction.trim().isEmpty) {
      errors.add('Instruction is empty.');
    }
    if (hasPassage && passage.trim().isEmpty) {
      errors.add('passageId is set but passage text is empty.');
    }
    if (hasPassage) {
      final existingPassage = passageMap[passageId!];
      if (existingPassage == null) {
        passageMap[passageId!] = passage;
      } else if (existingPassage != passage) {
        errors.add('passage text mismatch for passageId "$passageId".');
      }
    }

    if (isMultipleChoice) {
      if (options.length != 4) {
        errors.add('Multiple choice questions must have exactly 4 options.');
      }
      if (correctOptionIndex == null || correctOptionIndex! < 0 || correctOptionIndex! >= 4) {
        errors.add('correctOptionIndex must be 0..3 for multiple choice questions.');
      }
    }

    if (isShortAnswer) {
      if (acceptedAnswers.isEmpty) {
        errors.add('Short answer questions must include acceptedAnswers.');
      }
    }

    if (weight <= 0) {
      errors.add('Weight must be positive.');
    }

    existingIds.add(id);
    existingQuestions.add(question.trim());
    return errors;
  }
}
