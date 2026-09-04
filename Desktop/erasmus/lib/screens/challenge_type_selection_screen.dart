import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:erasmus_simulasyon/models/challenge_type.dart';
import 'package:erasmus_simulasyon/screens/mini_erasmus_challenge_screen.dart';

const Color _primaryPurple = Color(0xFF5E4DB8);
const Color _pageBackground = Color(0xFFF7F4FF);
// _cardBorder was unused here; remove to avoid unused constant.

class ChallengeTypeSelectionScreen extends StatefulWidget {
  final String name;
  final String gender;
  final String category;
  final String projectDescription;
  final String interests;

  const ChallengeTypeSelectionScreen({
    super.key,
    required this.name,
    required this.gender,
    required this.category,
    required this.projectDescription,
    required this.interests,
  });

  @override
  State<ChallengeTypeSelectionScreen> createState() => _ChallengeTypeSelectionScreenState();
}

class _ChallengeTypeSelectionScreenState extends State<ChallengeTypeSelectionScreen> {
  void _selectChallengeType(ChallengeType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MiniErasmusChallengeScreen(
          name: widget.name,
          gender: widget.gender,
          category: widget.category,
          projectDescription: widget.projectDescription,
          interests: widget.interests,
          challengeType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _primaryPurple,
        title: const Text('Choose Test Type'),
        elevation: 0,
      ),
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
                    Text(
                      'Choose Your Test',
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: _primaryPurple),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a challenge type to begin. Each test evaluates different aspects of your readiness.',
                      style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.black87),
                    ),
                    const SizedBox(height: 32),
                    _buildChallengeCard(
                      icon: Icons.language,
                      title: 'Test Your English',
                      subtitle: 'Evaluate your grammar, vocabulary, reading and communication skills.',
                      onTap: () => _selectChallengeType(ChallengeType.englishSkills),
                    ),
                    const SizedBox(height: 20),
                    _buildChallengeCard(
                      icon: Icons.trending_up,
                      title: 'Test Your Project Fit',
                      subtitle: 'Evaluate how well your skills and decisions match the selected project.',
                      onTap: () => _selectChallengeType(ChallengeType.projectFit),
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

  Widget _buildChallengeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _primaryPurple.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: _primaryPurple, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Get Started',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryPurple),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: _primaryPurple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
