import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String urlString, {LaunchMode mode = LaunchMode.platformDefault}) async {
  final uri = Uri.parse(urlString);
  try {
    final launched = await launchUrl(uri, mode: mode);
    if (!launched) {
      print('launchUrl returned false: $urlString');
    }
  } catch (e, st) {
    print('launchUrl failed: $urlString error=$e\n$st');
  }
}
