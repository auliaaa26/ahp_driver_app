import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  const MapsLauncher._();

  static Future<bool> openRoute({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final Uri uri;

    if (latitude != null && longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      );
    } else if (address != null && address.trim().isNotEmpty) {
      uri = Uri.https(
        'www.google.com',
        '/maps/search/',
        <String, String>{
          'api': '1',
          'query': address,
        },
      );
    } else {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
