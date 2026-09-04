import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/simulation_data.dart';
import 'application_feedback_screen.dart';

class ApplicationFormScreen extends StatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _languageLevel = 'B2';

  @override
  void initState() {
    super.initState();
    // Context initState'te doğrudan kullanılamaz, bu yüzden post-frame callback kullanılır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final simulationData = Provider.of<SimulationData>(context, listen: false);
        _emailController.text = simulationData.userEmail;
        _noteController.text = simulationData.userNote;
      }
    });
  }

  void _completeStep() {
    final simulationData = Provider.of<SimulationData>(context, listen: false);
    simulationData.setUserEmail(_emailController.text);
    simulationData.setUserNote(_noteController.text);
    simulationData.setUserLanguageLevel(_languageLevel);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationFeedbackScreen(
          email: _emailController.text,
          languageLevel: _languageLevel,
          note: _noteController.text,
          cv: simulationData.generatedCV,
          motivationLetter: simulationData.generatedMotivationLetter,
        ),
      ),
    ).then((_) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Başvuru Formu")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("E-posta adresiniz", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: "ornek@email.com",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Dil Seviyeniz", style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField(
            value: _languageLevel,
            onChanged: (val) => setState(() => _languageLevel = val!),
            items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)))
                .toList(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text("Ek Açıklama (isteğe bağlı)", style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Kendini veya projenle ilgili beklentilerini kısaca anlat...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _completeStep,
            child: const Text("AI ile Başvurumu Değerlendir"),
          ),
        ],
      ),
    );
  }
}
