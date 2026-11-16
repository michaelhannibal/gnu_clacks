/// An optional month/day preserves the precision supplied by the developer.
final class PartialDate {
  PartialDate(this.year, {this.month, this.day}) {
    if (year < 1 ||
        year > 9999 ||
        (month != null && (month! < 1 || month! > 12)) ||
        (day != null && month == null)) {
      throw ArgumentError('Invalid partial date.');
    }
    if (day != null) {
      final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
      final days = [
        31,
        if (leap) 29 else 28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
      ];
      if (day! < 1 || day! > days[month! - 1]) {
        throw ArgumentError('Invalid partial date.');
      }
    }
  }

  final int year;
  final int? month;
  final int? day;
}

/// Offline provenance and permission records; Core never resolves [source].
final class AssetAttribution {
  AssetAttribution({
    required String creator,
    required String source,
    required String licence,
    this.notice,
    this.modifications,
  }) : creator = _requiredText(creator),
       source = _requiredText(source),
       licence = _requiredText(licence);

  final String creator;
  final String source;
  final String licence;
  final String? notice;
  final String? modifications;
}

/// A developer-owned immutable definition. Display does not approve transmission.
///
/// Invalid [networkName] values remain available to the host but are never used
/// on the wire. The policy reports a value-free diagnostic instead of breaking
/// otherwise valid display content. Missing aliases are never inferred.
final class Memorial {
  Memorial({
    required String id,
    required String displayName,
    this.networkName,
    this.dedication,
    this.birthDate,
    this.deathDate,
    this.imageAsset,
    this.imageAltText,
    this.imageAttribution,
    this.displayEnabled = false,
    this.networkApproved = false,
    this.sortOrder,
  }) : id = _requiredText(id),
       displayName = _requiredText(displayName) {
    if (imageAsset != null && !_localAsset(imageAsset!)) {
      throw ArgumentError('Asset reference must be a relative local path.');
    }
  }

  final String id;
  final String displayName;
  final String? networkName;
  final String? dedication;
  final PartialDate? birthDate;
  final PartialDate? deathDate;
  final String? imageAsset;
  final String? imageAltText;
  final AssetAttribution? imageAttribution;
  final bool displayEnabled;
  final bool networkApproved;
  final int? sortOrder;
}

/// A defensive immutable snapshot; IDs are unique after trimming.
final class MemorialRegistry {
  MemorialRegistry(Iterable<Memorial> entries)
    : entries = List<Memorial>.unmodifiable(entries) {
    final ids = <String>{};
    for (final entry in this.entries) {
      if (!ids.add(entry.id)) {
        throw ArgumentError('Duplicate memorial ID.');
      }
    }
  }

  final List<Memorial> entries;

  /// Display order is independent of wire aliases and approval.
  List<Memorial> get displayEntries {
    final visible = entries.where((entry) => entry.displayEnabled).toList();
    visible.sort((a, b) {
      final order = compareOrder(a.sortOrder, b.sortOrder);
      if (order != 0) return order;
      final name = compareScalars(a.displayName, b.displayName);
      return name != 0 ? name : compareScalars(a.id, b.id);
    });
    return List<Memorial>.unmodifiable(visible);
  }
}

String _requiredText(String input) {
  final value = input.trim();
  if (value.isEmpty || input.runes.any((c) => c < 32 || c == 127)) {
    throw ArgumentError('Required text is empty or contains controls.');
  }
  return value;
}

bool _localAsset(String path) =>
    path.isNotEmpty &&
    path == path.trim() &&
    !path.startsWith('/') &&
    !path.contains(RegExp(r'[:\\?#%]')) &&
    !path.runes.any((c) => c < 32 || c == 127) &&
    path
        .split('/')
        .every((part) => part.isNotEmpty && part != '.' && part != '..');

// Avoid locale collation and Dart's UTF-16 ordering for supplementary characters.
int compareScalars(String a, String b) {
  final left = a.runes.iterator;
  final right = b.runes.iterator;
  while (true) {
    final hasLeft = left.moveNext();
    final hasRight = right.moveNext();
    if (!hasLeft || !hasRight) {
      return hasLeft == hasRight ? 0 : (hasLeft ? 1 : -1);
    }
    final comparison = left.current.compareTo(right.current);
    if (comparison != 0) return comparison;
  }
}

int compareOrder(int? a, int? b) =>
    a == null ? (b == null ? 0 : 1) : (b == null ? -1 : a.compareTo(b));
