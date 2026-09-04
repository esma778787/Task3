import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/simulation_data.dart';
import '../service/simulation_result_service.dart';

const Color _primaryPurple = Color(0xFF5E4DB8);
const Color _pageBackground = Color(0xFFF7F4FF);

class SimulationResultScreen extends StatefulWidget {
  final int score;
  final String feedback;

  const SimulationResultScreen({
    super.key,
    required this.score,
    required this.feedback,
  });

  @override
  State<SimulationResultScreen> createState() => _SimulationResultScreenState();
}

class _SimulationResultScreenState extends State<SimulationResultScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    final simulationData = Provider.of<SimulationData>(context, listen: false);

    setState(() {
      _isSaving = true;
    });

    try {
      await SimulationResultService.saveSimulationResult(
        simulationData: simulationData,
        score: widget.score,
        feedback: widget.feedback,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simülasyon sonucu başarıyla kaydedildi.')),
      );
      debugPrint('Simulation result saved to server.');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simülasyon kaydedilirken hata oluştu: $e')),
      );
      debugPrint('Simulation result save failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(title: const Text('Simulation Results'), backgroundColor: _primaryPurple, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                            Text('Simulation Results', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryPurple)),
                            const SizedBox(height: 10),
                            Text(
                              'Your score is calculated based on your application documents and challenge performance.',
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
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Score: ${widget.score} / 100', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 18),
                            Text('AI Feedback', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                            const SizedBox(height: 12),
                            SelectableText(widget.feedback, style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isSaving)
                      const Center(child: CircularProgressIndicator()),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveResult,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(_isSaving ? 'Saving Result...' : 'Save Result', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Your simulation result has been saved and is ready for review.', style: GoogleFonts.poppins(fontSize: 14, height: 1.7, color: Colors.black54)),
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
