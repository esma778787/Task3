import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_selection_screen.dart'; // Mevcut
import 'erasmus_links_screen.dart'; // Mevcut
import 'simulation_intro_screen.dart'; // YENİ İMPORT
import 'erasmusgram_screen.dart'; // Mevcut
import 'european_youth_screen.dart'; // YENİ İMPORT
// information_screen import removed; start screen is handled by main.dart

const Color _primaryPurple = Color(0xFF5E4DB8);
const Color _pageBackground = Color(0xFFF7F4FF);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _primaryPurple,
        title: Text(
          'Erasmus+ Simulation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Erasmus+ Simulation',
                              style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryPurple),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'A clear and modern Erasmus application experience. Browse projects, refine your documents, and follow your progress with ease.',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  height: 1.7,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 20),
                            Text('Choose a starting point',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 18),
                            _buildHomeCard(
                              icon: Icons.category,
                              title: 'Category Selection',
                              subtitle:
                                  'Choose the project path that fits your goals.',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const CategorySelectionScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildHomeCard(
                              icon: Icons.language,
                              title: 'Erasmus Websites',
                              subtitle:
                                  'Browse useful Erasmus resources and official materials.',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ErasmusLinksScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildHomeCard(
                              icon: Icons.list_alt,
                              title: 'Erasmusgram Projects',
                              subtitle:
                                  'Explore curated project listings for your application.',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ErasmusgramScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildHomeCard(
                              icon: Icons.public,
                              title: 'European Youth Projects',
                              subtitle:
                                  'Browse live European Youth Portal opportunities.',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const EuropeanYouthScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        'Start Simulation',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                        textStyle: const TextStyle(fontSize: 16),
                        elevation: 5,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SimulationIntroScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Select a source or project to begin your application simulation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black54),
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

  Widget _buildHomeCard({
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
            border: Border.all(color: _primaryPurple.withValues(alpha: 36)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 31),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: _primaryPurple, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.black54, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios,
                  size: 18, color: _primaryPurple.withValues(alpha: 230)),
            ],
          ),
        ),
      ),
    );
  }
}
