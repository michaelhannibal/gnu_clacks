import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

final registry = MemorialRegistry([
  Memorial(
    id: 'a',
    displayName: 'Alex Example',
    displayEnabled: true,
    birthDate: PartialDate(1942),
    deathDate: PartialDate(2020),
    dedication: 'Remembered for a generous spirit, a curious mind and a love of the everyday.',
  ),
  Memorial(
    id: 'b',
    displayName: 'Sam Example',
    displayEnabled: true,
    dedication: 'The stories and laughter stay with us.',
  ),
  Memorial(
    id: 'c',
    displayName: 'Robin Example',
    displayEnabled: true,
    birthDate: PartialDate(1956),
    deathDate: PartialDate(2024),
    dedication: 'For the kindness shared, and the paths we walked together.',
  ),
]);

void main() {
  setUpAll(() async {
    // SDK fonts give reproducible typography without shipping fonts or fetching.
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root == null) {
      throw StateError('FLUTTER_ROOT is required for SDK golden fonts.');
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
    await icons.load();
    final loader = FontLoader('Roboto');
    for (final name in [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ]) {
      loader.addFont(
        File('$root/bin/cache/artifacts/material_fonts/$name')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)),
      );
    }
    await loader.load();
  });

  for (final (name, size, appearance) in [
    (
      'gallery_classic_desktop',
      const Size(1200, 900),
      ClacksAppearance.classic,
    ),
    ('gallery_light_phone', const Size(390, 900), ClacksAppearance.light),
  ]) {
    testWidgets('$name golden', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Roboto'),
            home: MemorialGallery(registry: registry, appearance: appearance),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }

  testWidgets('detail and static signal golden', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1100);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: MemorialDetailScreen(
            registry: registry,
            memorialId: 'a',
            animate: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/detail_classic.png'),
    );
  });
}
