import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:erasmus_simulasyon/models/english_placement_result.dart';
import 'package:erasmus_simulasyon/service/assessment_api_service.dart';
import 'package:erasmus_simulasyon/service/openrouter_service.dart';

class EnglishPlacementResultScreen extends StatefulWidget {
  final EnglishPlacementResult result;
  final int sessionId;
  final List<Map<String, dynamic>> answers;

  const EnglishPlacementResultScreen({
    super.key,
    required this.result,
    required this.sessionId,
    required this.answers,
  });

  @override
  State<EnglishPlacementResultScreen> createState() => _EnglishPlacementResultScreenState();
}

class _EnglishPlacementResultScreenState extends State<EnglishPlacementResultScreen> {
  bool _isLoadingFeedback = true;
  bool _isSavingResult = true;
  bool _resultSaved = false;
  String _feedback = '';
  String? _saveError;

  @override
  void initState() {
    super.initState();
    // Start the result flow without storing a long-lived future reference.
    _initializeResultFlow();
  }

  Future<void> _initializeResultFlow() async {
    final result = widget.result;
    final feedback = await _requestFeedback();
    await _saveResult(feedback ?? _buildFallbackFeedback(result));
  }

  Future<String?> _requestFeedback() async {
    final result = widget.result;
    final weakTopics = result.weaknesses;
    try {
      final feedback = await OpenRouterService.generateEnglishPlacementFeedback(
        estimatedLevel: result.estimatedLevel,
        percentage: result.percentage,
        correctAnswers: result.correctAnswers,
        totalQuestions: result.totalQuestions,
        skillScores: result.skillScores.cast<String, int>(),
        weakTopics: weakTopics,
      );
      if (!mounted) return null;
      setState(() {
        _feedback = feedback;
        _isLoadingFeedback = false;
      });
      return feedback;
    } catch (_) {
      if (!mounted) return null;
      final fallback = _buildFallbackFeedback(result);
      setState(() {
        _feedback = fallback;
        _isLoadingFeedback = false;
      });
      return fallback;
    }
  }

  Future<void> _saveResult(String aiFeedback) async {
    if (_resultSaved) {
      return;
    }

    setState(() {
      _isSavingResult = true;
      _saveError = null;
    });

    try {
      final result = widget.result;
      await AssessmentApiService.completeEnglishPlacementSession(
        sessionId: widget.sessionId,
        result: result,
        answers: widget.answers,
        aiFeedback: aiFeedback,
        feedbackSource: 'openrouter',
      );
      if (!mounted) return;
      setState(() {
        _isSavingResult = false;
        _resultSaved = true;
        _saveError = null;
      });
    } catch (error) {
      debugPrint('Saving English placement result failed: $error');
      if (!mounted) return;
      setState(() {
        _isSavingResult = false;
        _saveError = 'Unable to save your placement result. Please retry.';
      });
    }
  }

  String _buildFallbackFeedback(EnglishPlacementResult result) {
    final strengths = result.strengths.isNotEmpty ? result.strengths.join(', ') : 'classroom use of English';
    final weaknesses = result.weaknesses.isNotEmpty ? result.weaknesses.join(', ') : 'grammar accuracy and reading comprehension';
    return 'Your estimated level is ${result.estimatedLevel}.\n\n'
        'You performed well in $strengths.\n'
        'You should focus on $weaknesses.\n\n'
        'This result is an approximate placement estimate and is not an official language certificate.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        title: const Text('English Placement Result'),
        backgroundColor: const Color(0xFF5E4DB8),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard(
                    title: 'Estimated English Level',
                    content: widget.result.estimatedLevel,
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: 'Overall Percentage',
                    content: '${widget.result.percentage}%',
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: 'Correct / Incorrect Answers',
                    content: '${widget.result.correctAnswers} / ${widget.result.incorrectAnswers}',
                  ),
                  const SizedBox(height: 14),
                  _buildSkillScoresCard(),
                  const SizedBox(height: 14),
                  _buildFeedbackCard(),
                  const SizedBox(height: 14),
                  if (_isSavingResult) ...[
                    const Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 14),
                            Expanded(child: Text('Saving your placement result...')),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_saveError != null) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _saveError!,
                              style: GoogleFonts.poppins(fontSize: 15, color: Colors.red.shade700, height: 1.6),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E4DB8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isSavingResult ? null : () {
                                _saveResult(_feedback.isNotEmpty ? _feedback : _buildFallbackFeedback(widget.result));
                              },
                              child: const Text('Retry saving result'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF4A2CB7))),
            const SizedBox(height: 10),
            Text(content, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillScoresCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skill Scores', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF4A2CB7))),
            const SizedBox(height: 14),
            ...widget.result.skillScores.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87)),
                    Text('${entry.value}%', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Feedback', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF4A2CB7))),
            const SizedBox(height: 14),
            if (_isLoadingFeedback) ...[
              Text('Generating your personalised feedback...', style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 18),
              const LinearProgressIndicator(minHeight: 6),
            ] else ...[
              Text(
                _feedback.isNotEmpty
                    ? _feedback
                    : 'Feedback is not available at the moment. Please review your placement results above.',
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87, height: 1.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
