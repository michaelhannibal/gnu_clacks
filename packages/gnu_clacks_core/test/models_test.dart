import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:test/test.dart';

void main() {
  test('display and network approval default off and stay independent', () {
    final defaults = Memorial(id: 'a', displayName: '山田');
    expect(defaults.displayEnabled, isFalse);
    expect(defaults.networkApproved, isFalse);
    final entries = [
      defaults,
      Memorial(id: 'b', displayName: 'Visible', displayEnabled: true),
      Memorial(id: 'c', displayName: 'Hidden', networkApproved: true),
    ];
    final registry = MemorialRegistry(entries);
    entries.clear();
    expect(registry.entries, hasLength(3));
    expect(registry.displayEntries.map((e) => e.id), ['b']);
    expect(() => registry.entries.clear(), throwsUnsupportedError);
    expect(() => registry.displayEntries.clear(), throwsUnsupportedError);
  });

  test('IDs and display names are validated without leaking values', () {
    expect(Memorial(id: ' a ', displayName: ' Renée ').displayName, 'Renée');
    for (final text in ['', '  ', 'a\nb', 'a\u007fb']) {
      expect(
        () => Memorial(id: text, displayName: 'Name'),
        throwsArgumentError,
      );
      expect(() => Memorial(id: 'a', displayName: text), throwsArgumentError);
    }
    expect(
      () => MemorialRegistry([
        Memorial(id: 'a', displayName: 'One'),
        Memorial(id: ' a ', displayName: 'Two'),
      ]),
      throwsArgumentError,
    );
    try {
      MemorialRegistry([
        Memorial(id: 'PRIVATE-ID', displayName: 'Secret'),
        Memorial(id: 'PRIVATE-ID', displayName: 'Secret'),
      ]);
      fail('Expected duplicate validation');
    } on ArgumentError catch (error) {
      expect(error.toString(), isNot(contains('PRIVATE-ID')));
      expect(error.toString(), isNot(contains('Secret')));
    }
  });

  test(
    'display sorting uses ordinals and Unicode scalars rather than UTF-16',
    () {
      final registry = MemorialRegistry([
        Memorial(
          id: 'supplementary',
          displayName: '\u{10000}',
          displayEnabled: true,
        ),
        Memorial(id: 'bmp', displayName: '\uE000', displayEnabled: true),
        Memorial(
          id: 'last',
          displayName: 'Same',
          sortOrder: 0,
          displayEnabled: true,
        ),
        Memorial(
          id: 'first',
          displayName: 'Same',
          sortOrder: 0,
          displayEnabled: true,
        ),
      ]);
      expect(registry.displayEntries.map((e) => e.id), [
        'first',
        'last',
        'bmp',
        'supplementary',
      ]);
    },
  );

  test(
    'partial dates preserve precision and validate leap/calendar boundaries',
    () {
      expect(PartialDate(1980).month, isNull);
      expect(PartialDate(1980, month: 2).day, isNull);
      expect(PartialDate(2000, month: 2, day: 29).day, 29);
      for (final construct in <PartialDate Function()>[
        () => PartialDate(0),
        () => PartialDate(10000),
        () => PartialDate(2000, month: 0),
        () => PartialDate(2000, month: 13),
        () => PartialDate(2000, day: 1),
        () => PartialDate(1900, month: 2, day: 29),
        () => PartialDate(2001, month: 2, day: 29),
        () => PartialDate(2000, month: 4, day: 31),
        () => PartialDate(2000, month: 1, day: 0),
      ]) {
        expect(construct, throwsArgumentError);
      }
    },
  );

  test('local assets are syntax-only and attribution stays local', () {
    final attribution = AssetAttribution(
      creator: 'Creator',
      source: 'Developer-owned original',
      licence: 'Permission',
      notice: 'Credit',
      modifications: 'Crop',
    );
    final entry = Memorial(
      id: 'a',
      displayName: 'Name',
      imageAsset: 'assets/portrait.png',
      imageAltText: 'Portrait',
      imageAttribution: attribution,
      dedication: 'Remembered',
      birthDate: PartialDate(1980),
    );
    expect(entry.imageAttribution!.notice, 'Credit');
    for (final asset in [
      '',
      '/absolute',
      '../outside',
      'a/../b',
      'a//b',
      'https://example.org/image',
      'a\\b',
      'a?query',
      'a#fragment',
      '%2e%2e/a',
      'a\nb',
    ]) {
      expect(
        () => Memorial(id: 'a', displayName: 'Name', imageAsset: asset),
        throwsArgumentError,
      );
    }
    expect(
      () => AssetAttribution(creator: '', source: 'x', licence: 'x'),
      throwsArgumentError,
    );
  });
}
