import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erasmus_simulasyon/models/simulation_data.dart';
import 'package:erasmus_simulasyon/screens/challenge_type_selection_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

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

  final Map<String, String> projectDescriptions = {
    'ESC Gönüllülük': 'This project allows you to do volunteer work in local communities. Teamwork and social impact are emphasized.',
    'Gençlik Değişimi': 'Projects focused on cultural exchange and interaction, bringing together youth from different countries.',
    'Eğitim Kursları': 'Training opportunities and capacity building for youth workers.',
  };

  void _startSimulation() {
    if (_nameController.text.isEmpty || _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen adınızı girin ve bir kategori seçin.')),
      );
      return;
    }

    final simulationData = Provider.of<SimulationData>(context, listen: false);
    simulationData.setUserName(_nameController.text);
    simulationData.setUserGender(_selectedGender);
    simulationData.setCategoryAndProject(
      category: _selectedCategory,
      description: _customProjectDescriptionController.text.isNotEmpty
          ? _customProjectDescriptionController.text
          : _projectDescription,
      interests: _interestsController.text,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeTypeSelectionScreen(
          name: _nameController.text,
          gender: _selectedGender,
          category: _selectedCategory,
          projectDescription: _customProjectDescriptionController.text.isNotEmpty
              ? _customProjectDescriptionController.text
              : _projectDescription,
          interests: _interestsController.text,
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
      appBar: AppBar(title: const Text('Karakter ve Kategori Seçimi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Adınızı girin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Cinsiyet Seçimi:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Kız'),
                  selected: _selectedGender == 'Kız',
                  onSelected: (_) => setState(() => _selectedGender = 'Kız'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Erkek'),
                  selected: _selectedGender == 'Erkek',
                  onSelected: (_) => setState(() => _selectedGender = 'Erkek'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Erasmus+ Kategorisi Seçimi:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Column(
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _projectDescription = projectDescriptions[_selectedCategory]!;
                    });
                  },
                  child: Card(
                    elevation: isSelected ? 6 : 2,
                    color: isSelected ? Colors.deepPurple.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        category == 'ESC Gönüllülük'
                            ? Icons.volunteer_activism
                            : category == 'Gençlik Değişimi'
                                ? Icons.group
                                : Icons.school,
                        color: Colors.deepPurple,
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        projectDescriptions[category]!,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.deepPurple)
                          : const Icon(Icons.radio_button_unchecked),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _interestsController,
              decoration: const InputDecoration(
                labelText: 'Kendinizi kısaca tanıtın / İlgi Alanlarınız (Tercihen İngilizce)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _customProjectDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Başvurmak istediğiniz proje açıklamasını yapıştırın (İngilizce)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startSimulation,
              child: const Text('Simülasyonu Başlat'),
            ),
          ],
        ),
      ),
    );
  }
}
