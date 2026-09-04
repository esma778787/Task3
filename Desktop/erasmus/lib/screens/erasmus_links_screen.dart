import 'package:flutter/material.dart';
import 'project_webview_screen.dart'; // ✅ WebView sayfası import edildi

class ErasmusLinksScreen extends StatelessWidget {
  const ErasmusLinksScreen({super.key});

  void _openInWebView(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectWebviewScreen(url: url),
      ),
    );
  }

  void _showEuLoginInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("EU Login Nedir?"),
          content: const Text(
            "EU Login, Avrupa Birliği platformlarında oturum açmak için kullanılan resmi giriş sistemidir. "
            "European Youth Portal gibi Erasmus+ sitelerinde başvuru yapabilmek için bu hesabın oluşturulması gerekir.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openInWebView(context, "https://webgate.ec.europa.eu/cas/");
              },
              child: const Text("EU Login'e Git"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<Map<String, String>> sites = [
      {
        "name": "European Youth Portal",
        "description": "Gençlik fırsatlarını keşfet",
        "url": "https://youth.europa.eu/"
      },
      {
        "name": "SALTO-YOUTH",
        "description": "Eğitimler ve projeler",
        "url": "https://www.salto-youth.net/"
      },
      {
        "name": "Erasmus+ Project Results Platform",
        "description": "Geçmiş projeleri incele",
        "url": "https://erasmus-plus.ec.europa.eu/projects"
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Erasmus Siteleri")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🟨 Bilgilendirme kutusu
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      'Proje Arama Adımları',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "🔹 European Youth Portal (youth.europa.eu)\n"
                  "• 'Volunteering Opportunities' bölümüne tıklayın.\n"
                  "• Ülke, süre ve faaliyet türüne göre filtreleyin.\n"
                  "• Başvurmak için EU Login hesabınız olmalı.\n\n"
                  "🔹 SALTO-YOUTH\n"
                  "• 'European Training Calendar' bölümüne gidin.\n"
                  "• Activity Type: Youth Exchange, Training Course vs.\n"
                  "• Country ve Deadline'a göre filtreleme yapın.\n"
                  "• Size uygun projeye tıklayın ve başvuru detaylarını okuyun.",
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),

                // 🟦 "EU Login Nedir?" Butonu
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showEuLoginInfo(context),
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text("EU Login Nedir?"),
                  ),
                ),
              ],
            ),
          ),

          // 🟪 Erasmus site link kartları
          ...sites.map((site) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(site['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(site['description']!),
                trailing: const Icon(Icons.open_in_browser),
                onTap: () => _openInWebView(context, site['url']!),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
