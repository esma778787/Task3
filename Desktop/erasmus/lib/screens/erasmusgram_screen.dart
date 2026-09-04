import 'package:flutter/material.dart';
import '../service/project_service.dart';
import '../service/api_config.dart';
import 'category_selection_screen.dart';
import 'project_webview_screen.dart'; // ✅ WebView sayfasını ekledik

class ErasmusgramScreen extends StatefulWidget {
  const ErasmusgramScreen({super.key});

  @override
  State<ErasmusgramScreen> createState() => _ErasmusgramScreenState();
}

class _ErasmusgramScreenState extends State<ErasmusgramScreen> {
  late Future<List<dynamic>> _projects;

  @override
  void initState() {
    super.initState();
    _projects = ProjectService.fetchProjectsFromAPI(endpoint: ApiConfig.projectsEndpoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Erasmusgram Projeleri")),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: FutureBuilder<List<dynamic>>(
              future: _projects,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Hiç proje bulunamadı."));
                }

                final projects = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final title = project['title'] as String? ?? 'Başlık yok';
                    final description = (project['description'] as String?)?.trim() ?? (project['content'] as String?)?.trim() ?? '';
                    final link = project['link'] as String? ?? '';
                    final category = project['category'] as String? ?? 'Erasmus+';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(
                              description.isNotEmpty ? description : link,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProjectWebviewScreen(url: link),
                                        ),
                                      );
                                    },
                                    child: const Text('Detayları İncele'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategorySelectionScreen(
                                            selectedProjectTitle: title,
                                            selectedProjectDescription: description,
                                            selectedProjectLink: link,
                                            selectedProjectCategory: category,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Bu Projeye Başvur'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
