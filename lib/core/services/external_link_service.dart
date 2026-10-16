import 'package:url_launcher/url_launcher.dart';

/// Opens links outside the app.
///
/// A thin injectable wrapper so cubits never touch the plugin directly, and so
/// the several ways this can fail - malformed URL, no browser, no registered
/// handler - collapse into a plain bool the UI can report instead of an
/// exception it would have to catch.
class ExternalLinkService {
  const ExternalLinkService();

  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
