 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:erasmus_simulasyon/models/simulation_data.dart';
import 'package:erasmus_simulasyon/screens/cv_builder_screen.dart';
import 'package:erasmus_simulasyon/service/openrouter_service.dart';

const Color _primaryPurple = Color(0xFF5E4DB8);
const Color _pageBackground = Color(0xFFF7F4FF);

class MotivationLetterScreen extends StatefulWidget {
  final String name;
  final String category;
  final String projectDescription;
  final String interests;
  final String gender;

  const MotivationLetterScreen({
    super.key,
    required this.name,
    required this.category,
    required this.projectDescription,
    required this.interests,
    required this.gender,
  });

  @override
  State<MotivationLetterScreen> createState() => _MotivationLetterScreenState();
}

class _MotivationLetterScreenState extends State<MotivationLetterScreen> {
  final TextEditingController _letterController = TextEditingController();
  bool _isLoading = false;
  String? _generatedLetter;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _generateMotivationLetter() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await OpenRouterService.generateMotivationLetter(
        name: widget.name,
        category: widget.category,
        projectDescription: widget.projectDescription,
        interests: widget.interests,
      );
      if (!mounted) return;
      setState(() {
        _generatedLetter = result;
        _letterController.text = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generatedLetter = null;
        _letterController.text = "Hata oluştu: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _completeStep() {
    final simulationData = Provider.of<SimulationData>(context, listen: false);
    simulationData.setGeneratedMotivationLetter(_letterController.text);

    // progress tracking removed for main flow

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CVBuilderScreen(
          name: widget.name,
          gender: widget.gender,
          category: widget.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(title: const Text('Motivation Letter'), backgroundColor: _primaryPurple, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                            Text('Motivation Letter', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryPurple)),
                            const SizedBox(height: 10),
                            Text(
                              'Create a strong motivation letter with AI support. This step helps you present your motivation clearly to Erasmus evaluators.',
                              style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Project Summary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 14),
                            Text('Project: ${widget.category}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
                            const SizedBox(height: 10),
                            Text(
                              widget.projectDescription.length > 120
                                  ? '${widget.projectDescription.substring(0, 120)}...'
                                  : widget.projectDescription,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.6),
                            ),
                            const SizedBox(height: 12),
                            Text('Interests: ${widget.interests}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: Text('Generate Motivation Letter', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      onPressed: _isLoading ? null : _generateMotivationLetter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 24),
                    if (_generatedLetter != null) ...[
                      Text('AI Generated Letter', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            _generatedLetter!,
                            style: GoogleFonts.poppins(fontSize: 14, height: 1.7, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text('Letter Draft', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _letterController,
                          minLines: 6,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Write or edit your motivation letter here.',
                            hintStyle: GoogleFonts.poppins(color: Colors.black38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _completeStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryPurple,
                        side: BorderSide(color: _primaryPurple.withValues(alpha: 204)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text('Complete Letter and Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
