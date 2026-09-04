import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:erasmus_simulasyon/models/simulation_data.dart';
import 'package:erasmus_simulasyon/screens/application_form_screen.dart';
import 'package:erasmus_simulasyon/service/openrouter_service.dart';

const Color _primaryPurple = Color(0xFF5E4DB8);
const Color _pageBackground = Color(0xFFF7F4FF);
const Color _cardBorder = Color(0xFFDAD6F1);

/// CV oluşturma ekranı – AI destekli CV + karakter ilerlemesi
class CVBuilderScreen extends StatefulWidget {
  final String name;
  final String gender;
  final String category;

  const CVBuilderScreen({
    super.key,
    required this.name,
    required this.gender,
    required this.category,
  });

  @override
  State<CVBuilderScreen> createState() => _CVBuilderScreenState();
}

class _CVBuilderScreenState extends State<CVBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aboutMeCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _langCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  String? _aiSuggestedCV;
  bool _loading = false;
  String _selectedLanguage = 'English';

  

  /* —— AI taslağı üret —— */
  Future<void> _generateCV() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final result = await OpenRouterService.generateCV(
        name: widget.name,
        gender: widget.gender,
        category: widget.category,
        skills: _skillsCtrl.text,
        language: _selectedLanguage,
      );
      if (!mounted) return;
      setState(() => _aiSuggestedCV = result);
    } catch (e) {
      if (mounted) {
        setState(() => _aiSuggestedCV = "Hata oluştu: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /* —— Adımı tamamlama —— */
  Future<void> _completeStep() async {
    if (!_formKey.currentState!.validate()) return;

    final sim = Provider.of<SimulationData>(context, listen: false);
    sim
      ..userSkills = _skillsCtrl.text
      ..userAboutMe = _aboutMeCtrl.text
      ..userEducation = _educationCtrl.text
      ..userExperience = _experienceCtrl.text
      ..setGeneratedCV(_aiSuggestedCV ?? _buildRawCV())
      ..setUserCVLanguage(_selectedLanguage);
    sim.evaluateSuitability();

    // Karakter preview removed for main flow; keep navigation and data intact.

    if (!sim.isSuitable) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Uygunluk Yetersiz'),
          content: Text('Projeye uygunluk puanınız %${sim.suitabilityScore}.\nEn az %60 olmalı. CV / becerilerinizi güncellemeyi deneyin.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplicationFormScreen(),
      ),
    );
  }

  String _buildRawCV() => '''
${widget.name} – ${widget.gender}
Kategori: ${widget.category}

ABOUT ME
${_aboutMeCtrl.text}

EDUCATION
${_educationCtrl.text}

WORK EXPERIENCE
${_experienceCtrl.text}

LANGUAGE SKILLS
${_langCtrl.text}

DIGITAL SKILLS
${_skillsCtrl.text}
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(title: const Text('CV Builder'), backgroundColor: _primaryPurple, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
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
                              Text('CV Builder', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryPurple)),
                              const SizedBox(height: 10),
                              Text(
                                'Provide your professional profile details and generate a polished CV draft with AI support.',
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Profile Overview', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 14),
                              Text('Name: ${widget.name}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
                              const SizedBox(height: 8),
                              Text('Gender: ${widget.gender}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.6)),
                              const SizedBox(height: 8),
                              Text('Category: ${widget.category}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.6)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text('CV Language', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        onChanged: (v) => setState(() => _selectedLanguage = v!),
                        decoration: _inputDecoration(null, null),
                        items: ['English', 'Turkish', 'Spanish', 'German']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      _buildField('About Me', _aboutMeCtrl, 4),
                      _buildField('Education', _educationCtrl, 4),
                      _buildField('Work Experience', _experienceCtrl, 4),
                      _buildField('Language Skills', _langCtrl, 3),
                      _buildField('Digital Skills', _skillsCtrl, 3, hint: 'Example: Flutter, Python, Teamwork'),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _generateCV,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text('Generate AI CV Draft', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_aiSuggestedCV != null) ...[
                        const SizedBox(height: 24),
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AI Suggested CV', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 12),
                                SelectableText(_aiSuggestedCV!, style: GoogleFonts.poppins(fontSize: 14, height: 1.7, color: Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _completeStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _primaryPurple,
                          side: BorderSide(color: _primaryPurple.withValues(alpha: 230)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text('Complete CV and Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, int lines, {String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          maxLines: lines,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'This field cannot be empty' : null,
          decoration: _inputDecoration(label, hint),
        ),
      );

  InputDecoration _inputDecoration(String? label, String? hintText) => InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryPurple.withValues(alpha: 204), width: 1.5)),
      );
}
