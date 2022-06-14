import 'package:url_launcher/url_launcher_string.dart' as lib;

import 'logger.dart';

Future<bool> launchUrl(String str) async {
  try  {
    return await lib.launchUrlString(
      str,
      mode: lib.LaunchMode.externalApplication,
    );
  } catch (ex) {
    logger.i("failed to launchUrl: ${ex}");
  }
  return false;
}
