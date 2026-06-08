import 'package:flutter_test/flutter_test.dart';

import 'package:volcano_boom/util/format.dart';

void main() {
  test('formatShort produces compact strings', () {
    expect(formatShort(0), '0');
    expect(formatShort(999), '999');
    expect(formatShort(1500), '1.5K');
    expect(formatShort(2500000), '2.5M');
    expect(formatShort(1000000000), '1B');
  });

  test('formatInt adds separators', () {
    expect(formatInt(1234567), '1,234,567');
    expect(formatInt(999), '999');
  });
}
