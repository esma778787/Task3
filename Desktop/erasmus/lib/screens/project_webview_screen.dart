import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectWebviewScreen extends StatefulWidget {
  final String url;

  const ProjectWebviewScreen({super.key, required this.url});

  @override
  State<ProjectWebviewScreen> createState() => _ProjectWebviewScreenState();
}

class _ProjectWebviewScreenState extends State<ProjectWebviewScreen> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();

    // If running on Web, open link in new tab and pop this screen
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final uri = Uri.parse(widget.url);
        try {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        } catch (_) {}
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    // Mobile platforms: initialize WebView controller
    if (Platform.isAndroid || Platform.isIOS) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Proje Detayı"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
            ? (_controller != null
                ? WebViewWidget(controller: _controller!)
                : const Center(child: CircularProgressIndicator()))
            : Center(
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    kIsWeb
                        ? "Proje yeni sekmede açıldı."
                        : "WebView bu platformda desteklenmiyor.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
      ),
    );
  }
}
