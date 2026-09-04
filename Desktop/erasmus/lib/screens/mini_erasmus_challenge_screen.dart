import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:erasmus_simulasyon/models/simulation_data.dart';
import 'package:erasmus_simulasyon/models/game_scenarios.dart';
import 'package:erasmus_simulasyon/models/english_question.dart';
import 'package:erasmus_simulasyon/service/challenge_generator_service.dart';
import 'package:erasmus_simulasyon/service/english_placement_service.dart';
import 'package:erasmus_simulasyon/service/openrouter_service.dart';
import 'package:erasmus_simulasyon/service/assessment_api_service.dart';
import 'package:erasmus_simulasyon/models/challenge_type.dart';
import 'package:erasmus_simulasyon/screens/english_placement_result_screen.dart';
import 'package:erasmus_simulasyon/screens/motivation_letter_screen.dart';

const Color _primaryPurple = Color(0xFF5E4DB8);
const Color _pageBackground = Color(0xFFF7F4FF);
const Color _cardBorder = Color(0xFFDAD6F1);

class MiniErasmusChallengeScreen extends StatefulWidget {
  final String name;
  final String gender;
  final String category;
  final String projectDescription;
  final String interests;
  final ChallengeType challengeType;

  const MiniErasmusChallengeScreen({
    super.key,
    required this.name,
    required this.gender,
    required this.category,
    required this.projectDescription,
    required this.interests,
    required this.challengeType,
  });

  @override
  State<MiniErasmusChallengeScreen> createState() => _MiniErasmusChallengeScreenState();
}

class _MiniErasmusChallengeScreenState extends State<MiniErasmusChallengeScreen> {
  int _index = 0;
  bool _isFinished = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _loadedProjectKey;
  List<Map<String, dynamic>> _scenarios = [];
  final List<EnglishPlacementAnswer> _englishAnswers = [];
  final TextEditingController _shortAnswerController = TextEditingController();
  String? _shortAnswerError;

  int? _assessmentSessionId;
  Future<void>? _sessionFuture;
  bool _isStartingSession = false;
  String? _sessionErrorMessage;

  // Answer selection state for English questions
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool? _isAnswerCorrect;
  Map<String, dynamic>? _pendingContrib;
  bool _answerRecorded = false;

  // raw sums per competency (0..21 max)
  final Map<String, int> _rawSums = {
    'teamwork': 0,
    'communication': 0,
    'responsibility': 0,
    'interculturalAwareness': 0,
    'problemSolving': 0,
    'motivation': 0,
    'adaptability': 0,
    'leadership': 0,
    'language': 0,
  };

  void _selectOption(Map<String, dynamic> contrib) {
    // add contributions
    contrib.forEach((k, v) {
      if (_rawSums.containsKey(k)) {
        _rawSums[k] = (_rawSums[k] ?? 0) + (v as int);
      }
    });

    if (_index < _scenarios.length - 1) {
      setState(() => _index++);
    } else {
      _finishChallenge();
    }
  }

  void _moveToNextQuestion() {
    // Apply pending contribution only once
    if (!_answerRecorded && _pendingContrib != null) {
      _selectOption(_pendingContrib!);
      _answerRecorded = true;
    }

    // Reset answer selection state for next question
    setState(() {
      _selectedOptionIndex = null;
      _isAnswered = false;
      _isAnswerCorrect = null;
      _pendingContrib = null;
      _answerRecorded = false;
    });
  }

  void _recordEnglishAnswer({
    required EnglishPlacementQuestion question,
    required bool isCorrect,
    required String selectedAnswer,
    int? selectedOptionIndex,
    String? textAnswer,
  }) {
    _englishAnswers.add(EnglishPlacementAnswer(
      question: question,
      isCorrect: isCorrect,
      selectedAnswer: selectedAnswer,
      selectedOptionIndex: selectedOptionIndex,
      textAnswer: textAnswer,
    ));
  }

  EnglishPlacementQuestion _convertScenarioToQuestion(Map<String, dynamic> scenario) {
    return EnglishPlacementQuestion(
      id: scenario['id']?.toString() ?? '',
      type: scenario['type']?.toString() ?? '',
      level: scenario['level']?.toString() ?? 'A2',
      skill: scenario['skill']?.toString() ?? 'grammar',
      title: scenario['title']?.toString() ?? '',
      instruction: scenario['instruction']?.toString() ?? '',
      passageId: null,
      passage: scenario['passage']?.toString() ?? '',
      question: scenario['question']?.toString() ?? '',
      options: (scenario['options'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((option) => EnglishPlacementOption.fromJson(option))
              .toList() ??
          [],
      acceptedAnswers: (scenario['acceptedAnswers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctOptionIndex: scenario['correctOptionIndex'] is int
          ? scenario['correctOptionIndex'] as int
          : (int.tryParse(scenario['correctOptionIndex']?.toString() ?? '') ?? 0),
      explanation: scenario['explanation']?.toString() ?? '',
      weight: 1,
      sentence: scenario['sentence']?.toString(),
      keyword: scenario['keyword']?.toString(),
    );
  }

  void _finishChallenge() {
    if (widget.challengeType == ChallengeType.englishSkills) {
      if (_isStartingSession) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait while your test session is created.')),
        );
        return;
      }
      if (_sessionErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sessionErrorMessage!)),
        );
        return;
      }
      if (_assessmentSessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start the placement session. Please try again.')),
        );
        return;
      }
    }

    // normalize: max raw per competency = numQuestions*3
    final Map<String, int> normalized = {};
    final int numQuestions = _scenarios.isNotEmpty ? _scenarios.length : gameScenarios.length;
    final int maxRaw = numQuestions * 3;
    _rawSums.forEach((k, raw) {
      final n = maxRaw > 0 ? (raw * 20 / maxRaw).round() : 0;
      normalized[k] = n.clamp(0, 20);
    });

    final int gameScore;
    final double gameScorePercentage;
    final String summary;

    if (widget.challengeType == ChallengeType.englishSkills) {
      if (_englishAnswers.length != _scenarios.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer all questions before seeing your result.')),
        );
        return;
      }

      if (_englishAnswers.length != _scenarios.length || _englishAnswers.length != 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all 30 questions before viewing your result.')),
        );
        return;
      }

      final result = EnglishPlacementService.calculateResult(_englishAnswers);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EnglishPlacementResultScreen(
            result: result,
            sessionId: _assessmentSessionId!,
            answers: _buildAnswerPayloads(),
          ),
        ),
      );
      return;
    } else {
      int total = 0;
      normalized.forEach((k, value) {
        if (k != 'language') total += value;
      });
      gameScore = total;
      gameScorePercentage = ((gameScore / 160) * 100);
      final sorted = normalized.entries
        .where((entry) => entry.key != 'language')
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final strong = sorted.take(2).map((e) => '${e.key} (${e.value})').join(', ');
      final weak = sorted.reversed.take(2).map((e) => '${e.key} (${e.value})').join(', ');
      summary = 'Güçlü: $strong. Geliştirilebilir: $weak.';
    }

    final simulationData = Provider.of<SimulationData>(context, listen: false);
    simulationData.setGameScore(gameScore);
    simulationData.setGameScorePercentage(double.parse(gameScorePercentage.toStringAsFixed(1)));
    simulationData.setGameScoreProfile(normalized);
    simulationData.setGameSummary(summary);

    setState(() {
      _isFinished = true;
    });

    // navigate to MotivationLetterScreen preserving params
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MotivationLetterScreen(
          name: widget.name,
          gender: widget.gender,
          category: widget.category,
          projectDescription: widget.projectDescription,
          interests: widget.interests,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    if (widget.challengeType == ChallengeType.englishSkills) {
      _startSessionOnce();
    }
  }

  Future<void> _loadChallenges() async {
    final simulationData = Provider.of<SimulationData>(context, listen: false);
    final title = simulationData.selectedProjectTitle;
    final link = simulationData.selectedProjectLink;
    final description = widget.projectDescription.trim().isNotEmpty
        ? widget.projectDescription
        : simulationData.projectDescription;
    final category = widget.category.trim().isNotEmpty
        ? widget.category
        : simulationData.selectedProjectCategory;
    final userInterests = simulationData.userInterests.trim().isNotEmpty
        ? simulationData.userInterests
        : widget.interests;
    final projectKey = '${widget.challengeType.name}_${title.trim()}_${description.trim().hashCode}';

    if (_loadedProjectKey == projectKey) {
      return;
    }
    _loadedProjectKey = projectKey;

    debugPrint('CHALLENGE TITLE: $title');
    debugPrint('CHALLENGE CATEGORY: $category');
    debugPrint('CHALLENGE DESCRIPTION LENGTH: ${description.length}');
    debugPrint('CHALLENGE INTERESTS: $userInterests');

    try {
      List<Map<String, dynamic>> loadedScenarios;
      if (widget.challengeType == ChallengeType.englishSkills) {
        final bank = await EnglishPlacementService.loadQuestions();
        final selectedQuestions = EnglishPlacementService.preparePlacementTest(bank, totalQuestions: 30);
        loadedScenarios = selectedQuestions.map((question) {
          final options = question.options.asMap().entries.map((entry) {
            return {
              'text': entry.value.text,
              'contrib': {
                'language': entry.key == question.correctOptionIndex ? 3 : 0,
              },
            };
          }).toList();

          return {
            'id': question.id,
            'type': question.type,
            'level': question.level,
            'skill': question.skill,
            'title': question.title,
            'instruction': question.instruction,
            'passage': question.passage,
            'question': question.question,
            'options': options,
            'correctOptionIndex': question.correctOptionIndex,
            'acceptedAnswers': question.acceptedAnswers,
            'explanation': question.explanation,
          };
        }).toList();
      } else {
        loadedScenarios = await OpenRouterService.generateProjectChallenges(
          projectTitle: title,
          projectDescription: description,
          category: category,
          projectLink: link,
          userInterests: userInterests,
        );
      }

      if (!mounted) return;
      setState(() {
        _scenarios = loadedScenarios;
        _isLoading = false;
        _errorMessage = null;
      });
      debugPrint('CHALLENGE COUNT: ${_scenarios.length}');
    } catch (error) {
      debugPrint('Challenge generation failed: $error');
      if (widget.challengeType == ChallengeType.projectFit) {
        debugPrint('Using static ChallengeGeneratorService fallback.');
        try {
          final fallbackScenarios = ChallengeGeneratorService.getScenariosForProject(
            title: title,
            description: description,
            link: link,
            category: category,
          );
          if (!mounted) return;
          setState(() {
            _scenarios = fallbackScenarios;
            _isLoading = false;
            _errorMessage = null;
          });
        } catch (fallbackError) {
          if (!mounted) return;
          setState(() {
            _scenarios = [];
            _isLoading = false;
            _errorMessage = 'AI and fallback challenge generation failed. Please try again later.';
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _scenarios = [];
          _isLoading = false;
          _errorMessage = 'English placement questions could not be loaded. Please try again later.';
        });
      }
    }
  }

  Future<void> _startSessionOnce() async {
    if (_sessionFuture != null) {
      return _sessionFuture;
    }

    final simulationData = Provider.of<SimulationData>(context, listen: false);
    final email = simulationData.userEmail.trim();

    if (email.isEmpty) {
      _sessionErrorMessage = 'Please provide your email before starting the English placement session.';
      _sessionFuture = Future.value();
      return _sessionFuture!;
    }

    _sessionFuture = _initializeAssessmentSession(email);
    return _sessionFuture!;
  }

  Future<void> _initializeAssessmentSession(String email) async {
    _isStartingSession = true;
    _sessionErrorMessage = null;

    final simulationData = Provider.of<SimulationData>(context, listen: false);
    final selectedProject = _buildProjectPayload(simulationData);

    try {
      final sessionId = await AssessmentApiService.startEnglishPlacementSession(
        userEmail: email,
        userName: widget.name,
        userGender: widget.gender,
        selectedProject: selectedProject,
      );
      if (!mounted) return;
      setState(() {
        _assessmentSessionId = sessionId;
      });
    } catch (error) {
      debugPrint('English placement session start failed: $error');
      if (!mounted) return;
      setState(() {
        _sessionErrorMessage = 'Unable to start the English placement session. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingSession = false;
        });
      }
    }
  }

  Map<String, dynamic>? _buildProjectPayload(SimulationData simulationData) {
    final title = simulationData.selectedProjectTitle.trim();
    final sourceUrl = simulationData.selectedProjectLink.trim();
    final sourceName = simulationData.selectedProjectCategory.trim();

    if (title.isEmpty && sourceUrl.isEmpty && sourceName.isEmpty) {
      return null;
    }

    final project = {
      'projectId': '',
      'title': title,
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
    };

    if (project.values.every((value) => value.toString().isEmpty)) {
      return null;
    }

    return project;
  }

  List<Map<String, dynamic>> _buildAnswerPayloads() {
    if (_englishAnswers.length != _scenarios.length || _englishAnswers.length != 30) {
      throw StateError('Answer count mismatch: found ${_englishAnswers.length}, expected 30.');
    }

    final answers = <Map<String, dynamic>>[];
    final ids = <String>{};

    for (var i = 0; i < _englishAnswers.length; i++) {
      final answer = _englishAnswers[i];
      final question = answer.question;
      if (question.id.trim().isEmpty) {
        throw StateError('Question ID is empty for answer ${i + 1}.');
      }
      if (!ids.add(question.id)) {
        throw StateError('Duplicate Question ID found: ${question.id}.');
      }

      final levelWeight = EnglishPlacementService.levelWeight(question.level);
      final weightedValue = question.weight * levelWeight;
      final optionIndex = question.isMultipleChoice ? answer.selectedOptionIndex : null;
      final textAnswer = question.isShortAnswer ? answer.textAnswer : null;

      if (question.isMultipleChoice && optionIndex == null) {
        throw StateError('Multiple-choice answer missing selectedOptionIndex for question ${question.id}.');
      }
      if (question.isShortAnswer && textAnswer == null) {
        throw StateError('Short-answer answer missing textAnswer for question ${question.id}.');
      }

      answers.add({
        'questionId': question.id,
        'displayOrder': i + 1,
        'questionType': question.type,
        'skill': question.skill,
        'cefrLevel': question.level,
        'questionText': question.question,
        'passageText': question.passage,
        'options': question.options.map((option) => option.toJson()).toList(),
        'selectedOptionIndex': optionIndex,
        'textAnswer': textAnswer,
        'isCorrect': answer.isCorrect,
        'earnedScore': answer.isCorrect ? weightedValue : 0,
        'maximumScore': weightedValue,
      });
    }
    return answers;
  }

  @override
  Widget build(BuildContext context) {
    final simulationData = Provider.of<SimulationData>(context, listen: false);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(title: Text(widget.challengeType.screenTitle), backgroundColor: _primaryPurple, elevation: 0),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Loading... Please wait.'),
              ],
            ),
          ),
        ),
      );
    }

    if (_scenarios.isEmpty) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(title: Text(widget.challengeType.screenTitle), backgroundColor: _primaryPurple, elevation: 0),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _errorMessage ?? 'Challenge questions could not be loaded. Please try again later.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.6),
              ),
            ),
          ),
        ),
      );
    }

    final scenario = _scenarios[_index];
    final options = scenario['options'] as List<dynamic>;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(title: Text(widget.challengeType.screenTitle), backgroundColor: _primaryPurple, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.challengeType.screenTitle, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryPurple)),
                            const SizedBox(height: 10),
                            Text(
                              widget.challengeType.screenDescription,
                              style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (simulationData.selectedProjectTitle.isNotEmpty) ...[
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'This challenge is based on your selected project details and helps generate more relevant feedback.',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / _scenarios.length,
                        minHeight: 8,
                        backgroundColor: Colors.white,
                        color: _primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Question ${_index + 1}/${_scenarios.length}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(scenario['title'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                            const SizedBox(height: 12),
                            Text(scenario['question'], style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87, height: 1.6)),
                            if (scenario['instruction'] != null && scenario['instruction'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(scenario['instruction'], style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, height: 1.5)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (scenario['type'] == 'open_cloze' || scenario['type'] == 'word_formation' || scenario['type'] == 'sentence_transformation') ...[
                      TextField(
                        controller: _shortAnswerController,
                        enabled: !_isAnswered,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Type your answer here',
                          errorText: _shortAnswerError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _cardBorder)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isAnswered ? null : _submitShortAnswer,
                        child: Text('Submit Answer', style: GoogleFonts.poppins(fontSize: 15, color: Colors.white)),
                      ),
                      if (_isAnswered) ...[
                        const SizedBox(height: 14),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: _isAnswerCorrect! ? Colors.green.shade50 : Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  _isAnswerCorrect! ? Icons.check_circle : Icons.cancel,
                                  color: _isAnswerCorrect! ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isAnswerCorrect! ? 'Correct answer!' : 'Incorrect answer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _isAnswerCorrect! ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _moveToNextQuestion,
                          child: Text(
                            _index == _scenarios.length - 1 ? 'View Results' : 'Next Question',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ] else ...[
                      ...options.asMap().entries.map((entry) {
                        final opt = entry.value as Map<String, dynamic>;
                        final index = entry.key;
                        final text = opt['text'] as String;
                        final contrib = opt['contrib'] as Map<String, dynamic>;
                        final question = _convertScenarioToQuestion(scenario);
                        final isCorrect = index == question.correctOptionIndex;
                        final isSelected = _selectedOptionIndex == index;

                        // Determine button color based on selection state
                        Color buttonColor = Colors.white;
                        if (isSelected) {
                          buttonColor = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? (isCorrect ? Colors.green.shade400 : Colors.red.shade400)
                                      : _cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: _isAnswered
                                ? null
                                : () {
                                    setState(() {
                                      _selectedOptionIndex = index;
                                      _isAnswered = true;
                                      _isAnswerCorrect = isCorrect;
                                      _pendingContrib = contrib;
                                      _answerRecorded = false;
                                    });

                                    _recordEnglishAnswer(
                                      question: question,
                                      isCorrect: isCorrect,
                                      selectedAnswer: text,
                                      selectedOptionIndex: index,
                                      textAnswer: null,
                                    );
                                  },
                            child: Text(text, style: GoogleFonts.poppins(fontSize: 15, height: 1.4)),
                          ),
                        );
                      }).toList(),
                      if (_isAnswered) ...[
                        const SizedBox(height: 14),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: _isAnswerCorrect! ? Colors.green.shade50 : Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  _isAnswerCorrect! ? Icons.check_circle : Icons.cancel,
                                  color: _isAnswerCorrect! ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isAnswerCorrect! ? 'Correct answer!' : 'Incorrect answer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _isAnswerCorrect! ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _moveToNextQuestion,
                          child: Text(
                            _index == _scenarios.length - 1 ? 'View Results' : 'Next Question',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                    if (_isFinished) ...[
                      const SizedBox(height: 20),
                      Text('Finishing...', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryPurple)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitShortAnswer() {
    final scenario = _scenarios[_index];
    final answer = _shortAnswerController.text.trim();
    if (answer.isEmpty) {
      setState(() {
        _shortAnswerError = 'Please enter your answer before continuing.';
      });
      return;
    }

    final acceptedAnswers = (scenario['acceptedAnswers'] as List<dynamic>?)?.map((value) => value.toString()).toList() ?? [];
    final isCorrect = acceptedAnswers.any((option) => EnglishPlacementQuestion.normalizeAnswer(option) == EnglishPlacementQuestion.normalizeAnswer(answer));
    
    final question = _convertScenarioToQuestion(scenario);
    _recordEnglishAnswer(
      question: question,
      isCorrect: isCorrect,
      selectedAnswer: answer,
      selectedOptionIndex: null,
      textAnswer: answer,
    );

    setState(() {
      _isAnswered = true;
      _isAnswerCorrect = isCorrect;
      _shortAnswerError = null;
      _pendingContrib = {'language': isCorrect ? 3 : 0};
      _answerRecorded = false;
    });

    _shortAnswerController.clear();
  }
}
