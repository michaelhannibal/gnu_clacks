import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_example/main.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('ExampleRoboto');
    for (final name in [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/$name'));
    }
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final gallery in [false, true]) {
    testWidgets('${gallery ? 'gallery' : 'home'} example golden', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: const ClacksExampleApp()),
      );
      await tester.pumpAndSettle();
      if (gallery) {
        await tester.runAsync(() async {
          final context = tester.element(find.byType(ClacksExampleApp));
          await precacheImage(const AssetImage('assets/river.png'), context);
          await precacheImage(const AssetImage('assets/lantern.png'), context);
        });
        await tester.ensureVisible(find.text('Open memorial gallery'));
        await tester.tap(find.text('Open memorial gallery'));
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          'goldens/example_${gallery ? 'gallery' : 'home'}.png',
        ),
      );
    });
  }
}
