import 'package:url_launcher/url_launcher_string.dart' as lib;

Future<bool> launchUrl(String str) {
  return lib.launchUrlString(
    str,
    mode: lib.LaunchMode.platformDefault,
  );
}
