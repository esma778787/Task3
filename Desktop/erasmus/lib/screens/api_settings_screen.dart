import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:erasmus_simulasyon/service/api_config.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final current = await ApiConfig.getCustomBaseUrl();
    if (mounted) {
      _ctrl.text = current ?? '';
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      // basic validation
      if (!text.startsWith('http')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL http veya https ile başlamalı.')));
        return;
      }
    }

    await ApiConfig.setCustomBaseUrl(text.isEmpty ? null : text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API base URL kaydedildi.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Özel backend base URL girin (örneğin: http://192.168.1.75:5000)'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'http://192.168.x.x:5000'),
                    keyboardType: TextInputType.url,
                    inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          _ctrl.clear();
                          await ApiConfig.setCustomBaseUrl(null);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Özel URL temizlendi.')));
                          Navigator.pop(context, true);
                        },
                        child: const Text('Temizle'),
                      ),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('Kaydet'),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
