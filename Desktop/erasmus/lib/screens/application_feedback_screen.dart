import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/simulation_data.dart';
import '../service/openrouter_service.dart';
import 'simulation_result_screen.dart';

const Color _primaryPurple = Color(0xFF5E4DB8);
const Color _pageBackground = Color(0xFFF7F4FF);

class ApplicationFeedbackScreen extends StatefulWidget {
  final String email;
  final String languageLevel;
  final String note;
  final String cv; // YENİ EKLENDİ
  final String motivationLetter; // YENİ EKLENDİ

  const ApplicationFeedbackScreen({
    super.key,
    required this.email,
    required this.languageLevel,
    required this.note,
    required this.cv, // YENİ
    required this.motivationLetter, // YENİ
  });

  @override
  State<ApplicationFeedbackScreen> createState() => _ApplicationFeedbackScreenState();
}

class _ApplicationFeedbackScreenState extends State<ApplicationFeedbackScreen> {
  String? _feedback;
  bool _isLoading = true;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _evaluateApplication();
  }

  Future<void> _evaluateApplication() async {
    try {
      // Artık sabit değerler yerine gelen gerçek değerleri kullanıyoruz
      final result = await OpenRouterService.evaluateApplication(
        cv: widget.cv,
        motivationLetter: widget.motivationLetter,
        languageLevel: widget.languageLevel,
        note: widget.note,
      );

      if (!mounted) return;
      final simulationData = Provider.of<SimulationData>(context, listen: false);
      simulationData.setAIFeedback(result);
      setState(() {
        _feedback = result;
        _score = _generateScoreFromFeedback(result);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedback = "Hata oluştu: $e";
        _isLoading = false;
      });
    }
  }

  int _generateScoreFromFeedback(String feedback) {
    final lower = feedback.toLowerCase();
    int tempScore = 0;
    if (lower.contains("çok başarılı") || lower.contains("mükemmel")) tempScore += 30;
    if (lower.contains("başarılı") || lower.contains("uygun")) tempScore += 20;
    if (lower.contains("güçlü yönler")) tempScore += 10;
    if (lower.contains("eksik") || lower.contains("geliştirilebilir")) tempScore -= 10;
    if (lower.contains("önemli eksiklikler") || lower.contains("zayıf")) tempScore -= 20;

    return (tempScore + 50).clamp(0, 100); // Skoru 0-100 arasında tut
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(title: const Text('Application Feedback'), backgroundColor: _primaryPurple, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
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
                                  Text('Application Feedback', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryPurple)),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Review the AI evaluation of your application documents and continue to the final result screen.',
                                    style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _feedback ?? 'No feedback available',
                                  style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.black87),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SimulationResultScreen(score: _score, feedback: _feedback!),
                                  ),
                                ).then((_) {
                                  if (!context.mounted) return;
                                  Navigator.pop(context, true);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: Text('View Simulation Result', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}