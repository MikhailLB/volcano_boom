/// Number formatting helpers for big incremental-game values.
library;

const List<String> _suffixes = [
  '',
  'K',
  'M',
  'B',
  'T',
  'aa',
  'ab',
  'ac',
  'ad',
  'ae',
  'af',
  'ag',
  'ah',
  'ai',
  'aj',
];

/// Formats a (possibly huge) value into a compact string like `12.3K`, `4.56M`.
String formatShort(num value) {
  if (value.isNaN || value.isInfinite) return '0';
  final bool negative = value < 0;
  double v = value.abs().toDouble();
  if (v < 1000) {
    // Show up to 1 decimal for small fractional values, otherwise integer.
    final String s = (v == v.roundToDouble()) ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return negative ? '-$s' : s;
  }
  int tier = 0;
  while (v >= 1000 && tier < _suffixes.length - 1) {
    v /= 1000;
    tier++;
  }
  String num;
  if (v >= 100) {
    num = v.toStringAsFixed(1);
  } else if (v >= 10) {
    num = v.toStringAsFixed(2);
  } else {
    num = v.toStringAsFixed(2);
  }
  // Trim trailing zeros for cleaner look.
  if (num.contains('.')) {
    num = num.replaceAll(RegExp(r'0+$'), '');
    num = num.replaceAll(RegExp(r'\.$'), '');
  }
  final String result = '$num${_suffixes[tier]}';
  return negative ? '-$result' : result;
}

/// Formats an integer count with thousands separators (e.g. `1,234,567`).
String formatInt(int value) {
  final String digits = value.abs().toString();
  final StringBuffer sb = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) sb.write(',');
    sb.write(digits[i]);
  }
  return (value < 0 ? '-' : '') + sb.toString();
}

/// Formats a duration in seconds into `1h 02m`, `12m 30s` style.
String formatDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final int h = d.inHours;
  final int m = d.inMinutes % 60;
  final int s = d.inSeconds % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}
