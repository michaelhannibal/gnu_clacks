import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:test/test.dart';

List<int> lit(int pattern) => [
  for (var lamp = 0; lamp < ClacksLampCode.lampCount; lamp++)
    if (ClacksLampCode.isLit(pattern, lamp)) lamp,
];

void main() {
  test('A is ASCII 01000001 read clockwise from the top-left', () {
    // Ring order 0,1,2,5,8,7,6,3: bit 6 -> lamp 1, bit 0 -> lamp 3.
    expect(lit(ClacksLampCode.encode('A')!), [1, 3]);
  });

  test('space lights one lamp; tilde lights six', () {
    // 0x20 = 00100000 -> third ring position, lamp 2.
    expect(lit(ClacksLampCode.encode(' ')!), [2]);
    // 0x7e = 01111110 -> ring positions 1-6.
    expect(lit(ClacksLampCode.encode('~')!), [1, 2, 5, 6, 7, 8]);
  });

  test('every printable ASCII character and END are distinct', () {
    final patterns = <int>{ClacksLampCode.end};
    for (var unit = 0x20; unit <= 0x7e; unit++) {
      patterns.add(ClacksLampCode.encode(String.fromCharCode(unit))!);
    }
    expect(patterns, hasLength(95 + 1));
    expect(ClacksLampCode.encode('a'), isNot(ClacksLampCode.encode('A')));
    expect(ClacksLampCode.encode('?'), isNotNull);
  });

  test('characters never touch the centre lamp; at most eight are lit', () {
    for (var unit = 0x20; unit <= 0x7e; unit++) {
      final pattern = ClacksLampCode.encode(String.fromCharCode(unit))!;
      expect(
        ClacksLampCode.isLit(pattern, ClacksLampCode.centre),
        isFalse,
        reason: String.fromCharCode(unit),
      );
      expect(lit(pattern).length, lessThanOrEqualTo(8));
    }
  });

  test('END is the centre lamp alone', () {
    expect(lit(ClacksLampCode.end), [ClacksLampCode.centre]);
  });

  test('unsupported or multi-character input is not encoded', () {
    for (final value in ['', 'AB', 'é', '\n', '\u0000', '\u007f', '😀']) {
      expect(ClacksLampCode.encode(value), isNull, reason: value);
    }
  });

  test('lamp index is range-checked', () {
    expect(() => ClacksLampCode.isLit(0, 9), throwsRangeError);
    expect(() => ClacksLampCode.isLit(0, -1), throwsRangeError);
  });
}
