import 'package:url_launcher/url_launcher.dart';

class LauncherHelper {
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("URL açılamadı: $url");
    }
  }
}
