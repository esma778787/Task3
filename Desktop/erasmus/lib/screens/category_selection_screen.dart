
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:erasmus_simulasyon/models/simulation_data.dart';
import 'package:erasmus_simulasyon/screens/challenge_type_selection_screen.dart';

const Color _primaryPurple = Color(0xFF5E4DB8);
const Color _pageBackground = Color(0xFFF7F4FF);
const Color _cardBorder = Color(0xFFDAD6F1);

class CategorySelectionScreen extends StatefulWidget {
  final String? selectedProjectTitle;
  final String? selectedProjectDescription;
  final String? selectedProjectLink;
  final String? selectedProjectCategory;

  const CategorySelectionScreen({
    super.key,
    this.selectedProjectTitle,
    this.selectedProjectDescription,
    this.selectedProjectLink,
    this.selectedProjectCategory,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();
  final TextEditingController _customProjectDescriptionController = TextEditingController();

  String _selectedGender = 'Kız';
  String _selectedCategory = '';
  String _projectDescription = '';

  final List<String> categories = [
    'ESC Gönüllülük',
    'Gençlik Değişimi',
    'Eğitim Kursları',
  ];

  final Map<String, String> _categoryLabels = {
    'ESC Gönüllülük': 'ESC Volunteering',
    'Gençlik Değişimi': 'Youth Exchange',
    'Eğitim Kursları': 'Training Courses',
  };

  final Map<String, String> projectDescriptions = {
    'ESC Gönüllülük':
        'This project allows you to do volunteer work in local communities. Teamwork and social impact are emphasized.',
    'Gençlik Değişimi':
        'Projects focused on cultural exchange and interaction, bringing together youth from different countries.',
    'Eğitim Kursları':
        'Training opportunities and capacity building for youth workers.',
  };

  bool get _hasSelectedProject => widget.selectedProjectDescription != null && widget.selectedProjectTitle != null;

  String get _effectiveProjectDescription {
    if (_hasSelectedProject) {
      return widget.selectedProjectDescription!;
    }
    if (_customProjectDescriptionController.text.isNotEmpty) {
      return _customProjectDescriptionController.text;
    }
    return _projectDescription;
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedProjectDescription != null) {
      _projectDescription = widget.selectedProjectDescription!;
    }
  }

  void _startSimulation() {
    if (_nameController.text.isEmpty || _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and select a category.')),
      );
      return;
    }

    // Seçilen proje bilgilerini SimulationData'ya kaydet
    final simulationData = Provider.of<SimulationData>(context, listen: false);
    if (widget.selectedProjectTitle != null && widget.selectedProjectCategory != null) {
      simulationData.setSelectedProject(
        title: widget.selectedProjectTitle!,
        link: widget.selectedProjectLink ?? '',
        category: widget.selectedProjectCategory!,
        description: widget.selectedProjectDescription?.trim().isNotEmpty == true
            ? widget.selectedProjectDescription!
            : simulationData.projectDescription,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeTypeSelectionScreen(
          name: _nameController.text,
          gender: _selectedGender,
          category: _selectedCategory,
          projectDescription: _effectiveProjectDescription,
          interests: _interestsController.text,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _interestsController.dispose();
    _customProjectDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _primaryPurple,
        title: const Text('Category Selection'),
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
                    Text('Category Selection', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: _primaryPurple)),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your details and choose a project path. The selected project details will be used to personalize your Erasmus simulation.',
                      style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.black87),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Personal Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            _buildLabel('Full Name'),
                            TextField(
                              controller: _nameController,
                              decoration: _inputDecoration('Enter your full name'),
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Interests'),
                            TextField(
                              controller: _interestsController,
                              decoration: _inputDecoration('Share your main interests'),
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Gender'),
                            DropdownButtonFormField<String>(
                              value: ['Kız', 'Erkek'].contains(_selectedGender) ? _selectedGender : 'Kız',
                              onChanged: (value) {
                                setState(() => _selectedGender = value!);
                              },
                              decoration: _inputDecoration(null),
                              items: const [
                                DropdownMenuItem<String>(value: 'Kız', child: Text('Female')),
                                DropdownMenuItem<String>(value: 'Erkek', child: Text('Male')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Choose a Category', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            Column(
                              children: categories.map((category) {
                                return RadioListTile<String>(
                                  visualDensity: const VisualDensity(vertical: -3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                                  title: Text(_categoryLabels[category] ?? category, style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87)),
                                  value: category,
                                  groupValue: _selectedCategory,
                                  activeColor: _primaryPurple,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                      _projectDescription = projectDescriptions[value] ?? '';
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_hasSelectedProject) ...[
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selected Project', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 14),
                              Text(widget.selectedProjectTitle ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 10),
                              Text(
                                widget.selectedProjectDescription ?? '',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.6),
                              ),
                              if (widget.selectedProjectLink != null && widget.selectedProjectLink!.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  widget.selectedProjectLink!,
                                  style: GoogleFonts.poppins(fontSize: 14, color: _primaryPurple, decoration: TextDecoration.underline),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You can start the application simulation for this project. Review the details and continue to the next step.',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, height: 1.6),
                      ),
                    ] else ...[
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Project Description (Optional)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _customProjectDescriptionController,
                                maxLines: 5,
                                decoration: _inputDecoration('Describe the project you are interested in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 280,
                        child: ElevatedButton(
                          onPressed: _startSimulation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text('Start Simulation', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
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

  Widget _buildLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
      );

  InputDecoration _inputDecoration(String? hintText) => InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryPurple.withValues(alpha: 204), width: 1.5)),
      );
}
