import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_example/demo_network.dart';
import 'package:gnu_clacks_example/main.dart';
import 'package:gnu_clacks_example/memorials.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

void main() {
  testWidgets('starts offline with no clients or background frames', (
    tester,
  ) async {
    var created = 0;
    final network = DemoNetwork(
      registry: exampleRegistry,
      httpFactory: () {
        created++;
        throw StateError('Unexpected client');
      },
      dioFactory: () {
        created++;
        throw StateError('Unexpected client');
      },
    );
    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(ClacksExampleApp(network: network));
        await tester.pumpAndSettle();
        expect(find.text('Their names live on.'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
        await tester.tap(find.text('Header-only'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'No test endpoint configured. This demonstration stays offline.',
          ),
          findsOneWidget,
        );
        for (final button in tester.widgetList<OutlinedButton>(
          find.byType(OutlinedButton),
        )) {
          expect(button.onPressed, isNull);
        }
        await tester.tap(find.text('Full tribute'));
        await tester.pumpAndSettle();
        expect(find.text('Open memorial gallery'), findsOneWidget);
        expect(find.text('Enable the test header'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
      createHttpClient: (_) {
        created++;
        throw StateError('Unexpected network');
      },
    );
    expect(created, 0);
  });

  testWidgets(
    'gallery uses local sample assets and exposes full detail/attribution',
    (tester) async {
      await tester.pumpWidget(const ClacksExampleApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Open memorial gallery'));
      await tester.tap(find.text('Open memorial gallery'));
      await tester.pumpAndSettle();
      expect(find.byType(MemorialGallery), findsOneWidget);
      expect(find.text('Alex Example'), findsOneWidget);
      expect(find.text('Sam Example'), findsOneWidget);
      expect(find.text('Robin Example'), findsOneWidget);
      expect(
        tester
            .widgetList<Image>(find.byType(Image))
            .every((i) => i.image is AssetImage),
        isTrue,
      );
      await tester.tap(find.text('Alex Example'));
      await tester.pumpAndSettle();
      expect(find.byType(MemorialDetailScreen), findsOneWidget);
      expect(find.text('GNU Alex Example'), findsOneWidget);
      expect(find.text('Creator: Ydesignz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('phone layout and all three modes reflow without exceptions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ClacksExampleApp());
    await tester.pumpAndSettle();
    for (final label in ['Header-only', 'Full tribute', 'Visual-only']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('privacy copy is available without enabling networking', (
    tester,
  ) async {
    await tester.pumpWidget(const ClacksExampleApp());
    await tester.tap(find.byTooltip('Privacy and credits'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'All names, dates and dedications in this app are fictional',
      ),
      findsOneWidget,
    );
    expect(find.text('Dependency licences'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('large text keeps demonstration controls reachable on a phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    await tester.pumpWidget(const ClacksExampleApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Header-only'));
    await tester.tap(find.text('Header-only'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
