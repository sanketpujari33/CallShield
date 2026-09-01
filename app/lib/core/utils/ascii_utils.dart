class AsciiUtils {
  /// Filters a string down to ASCII digits '0'-'9' only.
  static String filterAsciiDigits(String? input) {
    if (input == null || input.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code >= 0x30 && code <= 0x39) {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// Extracts the last [count] ASCII digits from [input].
  static String filterAsciiDigitsLast(String? input, int count) {
    final digits = filterAsciiDigits(input);
    if (digits.length <= count) return digits;
    return digits.substring(digits.length - count);
  }
}
