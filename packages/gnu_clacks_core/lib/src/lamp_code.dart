/// Nine-lamp Clacks code for the tribute animation: a three-by-three grid.
///
/// Each printable ASCII character (space to `~`) is its 8-bit ASCII code,
/// shown on the eight outer lamps read clockwise from the top-left, most
/// significant bit first. The centre lamp never carries character data: it is
/// lit only, and alone, for [end], the end-of-message signal. So at most eight
/// lamps are ever lit, and END cannot be mistaken for any character.
///
/// Lamps are numbered left to right, then top to bottom (0–8; the centre is
/// [centre], 4). A pattern is a 9-bit mask: bit `n` set means lamp `n` is lit.
///
/// Display only. Nothing here is used to build HTTP header values.
abstract final class ClacksLampCode {
  /// Lamps per pattern: three columns by three rows.
  static const int lampCount = 9;

  /// Lamp columns per pattern.
  static const int columns = 3;

  /// Lamp rows per pattern.
  static const int rows = 3;

  /// The centre lamp, reserved for [end].
  static const int centre = 4;

  /// End-of-message signal: the centre lamp alone.
  static const int end = 1 << centre;

  /// Outer lamps in clockwise order from the top-left; the first carries the
  /// most significant bit of the ASCII byte.
  static const List<int> ring = [0, 1, 2, 5, 8, 7, 6, 3];

  /// The lamp pattern for one character, or `null` when [character] is not a
  /// single printable ASCII character (space to `~`).
  static int? encode(String character) {
    if (character.length != 1) return null;
    final byte = character.codeUnitAt(0);
    if (byte < 0x20 || byte > 0x7e) return null;
    var pattern = 0;
    for (var bit = 0; bit < ring.length; bit++) {
      if ((byte >> (7 - bit)) & 1 == 1) pattern |= 1 << ring[bit];
    }
    return pattern;
  }

  /// Whether [lamp] (0–8) is lit in [pattern].
  static bool isLit(int pattern, int lamp) {
    RangeError.checkValueInInterval(lamp, 0, lampCount - 1, 'lamp');
    return (pattern >> lamp) & 1 == 1;
  }
}
