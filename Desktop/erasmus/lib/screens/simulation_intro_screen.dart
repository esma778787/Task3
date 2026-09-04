import 'package:flutter/material.dart';
import 'category_selection_screen.dart';

class SimulationIntroScreen extends StatelessWidget {
  const SimulationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Simülasyona Başla")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Erasmus+ Başvuru Simülasyonu",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Bu simülasyon, seni gerçek bir Erasmus+ başvuru sürecinden geçirecek. ",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Kategori seçimi, CV ve motivasyon mektubu hazırlığı gibi adımlarda sana rehberlik edeceğiz.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("Devam Et"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategorySelectionScreen(),
                            ),
                          );
                        },
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
