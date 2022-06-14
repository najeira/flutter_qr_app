String breakWord(String str) {
  final buf = StringBuffer();
  for (final element in str.runes) {
    buf.writeCharCode(element);
    buf.writeCharCode(0x200B);
    // buf.write('\u200b');
    // buf.write(' ');
  }
  return buf.toString();
}
