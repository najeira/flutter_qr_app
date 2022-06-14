import 'package:flutter/services.dart';

Future<void> clipboardPaste(String value) {
  final data = ClipboardData(text: value);
  return Clipboard.setData(data);
}
