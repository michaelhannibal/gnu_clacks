import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

Memorial entry(
  String id,
  String name, {
  bool visible = true,
  String? image,
  String? dedication,
}) => Memorial(
  id: id,
  displayName: name,
  displayEnabled: visible,
  networkName: 'PRIVATE ALIAS',
  networkApproved: true,
  dedication: dedication,
  imageAsset: image,
  imageAltText: image == null ? null : 'A portrait',
  birthDate: PartialDate(1942),
  deathDate: PartialDate(2020, month: 3),
);
final sample = MemorialRegistry([
  entry(
    'a',
    'Alex Example',
    dedication: 'Remembered for a generous spirit and a love of the everyday.',
  ),
  entry(
    'b',
    'Sam Example',
    dedication: 'The stories and laughter stay with us.',
  ),
  entry('hidden', 'Never Display This', visible: false),
]);
Widget host(
  Widget child, {
  ClacksTheme? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  bool reduce = false,
}) => MaterialApp(
  theme: ThemeData(useMaterial3: true, extensions: [?theme]),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(1000, 800),
      textScaler: TextScaler.linear(scale),
      disableAnimations: reduce,
    ),
    child: Directionality(textDirection: direction, child: child),
  ),
);
Future<void> size(WidgetTester tester, Size value) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = value;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'gallery filters hidden entries, never displays aliases, and navigates/back',
    (tester) async {
      await tester.pumpWidget(host(MemorialGallery(registry: sample)));
      await tester.pumpAndSettle();
      expect(find.text('Alex Example'), findsOneWidget);
      expect(find.text('Never Display This'), findsNothing);
      expect(find.textContaining('PRIVATE ALIAS'), findsNothing);
      await tester.tap(find.text('Alex Example'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byType(MemorialDetailScreen), findsOneWidget);
      expect(find.text('GNU Alex Example'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(MemorialDetailScreen), findsNothing);
    },
  );

  testWidgets(
    'hidden direct detail, badge, card and portrait reveal no content',
    (tester) async {
      final hidden = sample.entries.last;
      for (final widget in <Widget>[
        MemorialDetailScreen(registry: sample, memorialId: hidden.id),
        MemorialBadge(memorial: hidden),
        MemorialCard(memorial: hidden, onTap: () {}),
        MemorialPortrait(memorial: hidden),
      ]) {
        await tester.pumpWidget(host(widget));
        await tester.pumpAndSettle();
        expect(find.textContaining('Never Display This'), findsNothing);
        expect(find.byType(Image), findsNothing);
        expect(find.byType(ClacksSignal), findsNothing);
      }
    },
  );

  testWidgets('empty and unknown-detail states are honest static views', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(MemorialGallery(registry: MemorialRegistry([]))),
    );
    expect(find.text('A place for remembrance'), findsOneWidget);
    await tester.pumpWidget(
      host(MemorialDetailScreen(registry: sample, memorialId: 'absent')),
    );
    expect(find.text('This memorial is not available.'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'responsive cards form one, two and three columns by actual width',
    (tester) async {
      for (final (width, columns) in [(360.0, 1), (720.0, 2), (1200.0, 3)]) {
        await size(tester, Size(width, 900));
        final three = MemorialRegistry([
          sample.entries[0],
          sample.entries[1],
          entry('c', 'Robin Example'),
        ]);
        await tester.pumpWidget(host(MemorialGallery(registry: three)));
        await tester.pumpAndSettle();
        final positions = tester.getTopLeft(find.byType(MemorialCard).first);
        final second = tester.getTopLeft(find.byType(MemorialCard).at(1));
        if (columns == 1) {
          expect(second.dx, positions.dx);
          expect(second.dy, greaterThan(positions.dy));
        } else {
          expect(second.dy, positions.dy);
          expect(second.dx, greaterThan(positions.dx));
        }
        if (columns == 3) {
          expect(
            tester.getTopLeft(find.byType(MemorialCard).at(2)).dy,
            positions.dy,
          );
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'large text, long names and RTL reflow without overflow or losing dedication',
    (tester) async {
      await size(tester, const Size(360, 900));
      final long = entry(
        'long',
        'A very long remembered name with many words',
        dedication: List.filled(25, 'A complete local dedication.').join(' '),
      );
      await tester.pumpWidget(
        host(
          MemorialGallery(registry: MemorialRegistry([long])),
          scale: 2.5,
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        host(
          MemorialDetailScreen(
            registry: MemorialRegistry([long]),
            memorialId: long.id,
            animate: false,
          ),
          scale: 2.5,
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(long.dedication!), findsOneWidget);
      expect(find.text('1942 – 2020-03'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard Tab and Enter activate cards; focus has a visible outline',
    (tester) async {
      var opened = '';
      await tester.pumpWidget(
        host(
          MemorialGallery(
            registry: sample,
            onOpenMemorial: (m) => opened = m.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, 'a');
      final material = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.shape is RoundedRectangleBorder);
      expect(
        material.any(
          (m) => (m.shape! as RoundedRectangleBorder).side.width == 3,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'semantics expose button name/dedication, with no hidden identity or decorative towers',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(host(MemorialGallery(registry: sample)));
      await tester.pumpAndSettle();
      final data = tester
          .getSemantics(find.byType(MemorialCard).first)
          .getSemanticsData();
      expect(data.label, contains('Alex Example'));
      expect(data.label, contains('generous spirit'));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, isNot(contains('PRIVATE ALIAS')));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    },
  );

  testWidgets(
    'missing local image gets a quiet fallback without an exception',
    (tester) async {
      await tester.pumpWidget(
        host(
          MemorialGallery(
            registry: MemorialRegistry([
              entry('a', 'Alex', image: 'missing.png'),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
      expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    },
  );

  testWidgets(
    'attribution is retained offline, and explanations never claim actual encoding',
    (tester) async {
      final credited = Memorial(
        id: 'a',
        displayName: 'Alex',
        displayEnabled: true,
        dedication: 'Complete dedication',
        imageAttribution: AssetAttribution(
          creator: 'Local artist',
          source: 'Original work',
          licence: 'Permission granted',
          notice: 'Credit must remain visible',
          modifications: 'Cropped',
        ),
      );
      var callbacks = 0;
      await tester.pumpWidget(
        host(
          MemorialDetailScreen(
            registry: MemorialRegistry([credited]),
            memorialId: 'a',
            animate: false,
            onOpenCredits: () => callbacks++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Credit must remain visible'));
      expect(find.text('Creator: Local artist'), findsOneWidget);
      expect(find.text('Modifications: Cropped'), findsOneWidget);
      await tester.ensureVisible(find.text('Privacy and credits'));
      await tester.tap(find.text('Privacy and credits'));
      expect(callbacks, 1);
      await tester.ensureVisible(find.text('About the Clacks'));
      await tester.tap(find.text('About the Clacks'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('does not encode or send a message'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'default themes and low-contrast overrides supply readable text',
    (tester) async {
      for (final appearance in ClacksAppearance.values) {
        final tokens = ClacksTheme.appearance(appearance, ThemeData());
        expect(
          ClacksTheme.contrast(
            tokens.ink(tokens.background),
            tokens.background,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          ClacksTheme.contrast(tokens.ink(tokens.surface), tokens.surface),
          greaterThanOrEqualTo(4.5),
        );
        await tester.pumpWidget(
          host(MemorialGallery(registry: sample, appearance: appearance)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      const bad = ClacksTheme(
        background: Colors.white,
        surface: Colors.white,
        foreground: Colors.white,
        accent: Colors.white,
      );
      await tester.pumpWidget(
        host(MemorialGallery(registry: sample), theme: bad),
      );
      await tester.pumpAndSettle();
      final name = tester.widget<Text>(find.text('Alex Example'));
      expect(name.style!.color, Colors.black);
      final semantics = tester.ensureSemantics();

      await tester.pump();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    },
  );

  testWidgets('badge activates without overlaying content and hides aliases', (
    tester,
  ) async {
    var activated = false;
    await tester.pumpWidget(
      host(
        Scaffold(
          body: MemorialBadge(
            memorial: sample.entries.first,
            onTap: () => activated = true,
          ),
        ),
      ),
    );
    expect(find.text('GNU · Alex Example'), findsOneWidget);
    await tester.tap(find.text('GNU · Alex Example'));
    expect(activated, isTrue);
    expect(find.textContaining('PRIVATE ALIAS'), findsNothing);
  });

  testWidgets('gallery and detail never create a network client', (
    tester,
  ) async {
    var calls = 0;
    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(host(MemorialGallery(registry: sample)));
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          host(
            MemorialDetailScreen(
              registry: sample,
              memorialId: 'a',
              animate: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
      },
      createHttpClient: (_) {
        calls++;
        throw StateError('Network is forbidden');
      },
    );
    expect(calls, 0);
  });

  test(
    'localisation methods preserve date precision and can be overridden',
    () {
      const strings = ClacksLocalizations();
      expect(strings.date(PartialDate(1942)), '1942');
      expect(strings.date(PartialDate(2020, month: 3)), '2020-03');
      expect(strings.date(PartialDate(2020, month: 3, day: 4)), '2020-03-04');
      expect(const _CustomStrings().title, 'Remembering');
    },
  );
  testWidgets(
    'valid bundled portrait decodes locally and exposes meaningful alt text',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DefaultAssetBundle(
            bundle: _PortraitBundle(),
            child: MemorialGallery(
              registry: MemorialRegistry([
                entry('a', 'Alex', image: 'portrait.png'),
              ]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image = tester.widget<Image>(find.byType(Image));
        await precacheImage(image.image, tester.element(find.byType(Image)));
      });
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('A portrait')), findsWidgets);
      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );

  testWidgets('host localisation delegate overrides visible strings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_CustomDelegate()],
        home: MemorialGallery(registry: MemorialRegistry([])),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Remembering'), findsOneWidget);
    expect(find.text('In remembrance'), findsNothing);
  });
  testWidgets(
    'display comparator changes visual order without exposing hidden entries',
    (tester) async {
      await tester.pumpWidget(
        host(
          MemorialGallery(
            registry: sample,
            displayComparator: (a, b) => b.displayName.compareTo(a.displayName),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = tester
          .widgetList<MemorialCard>(find.byType(MemorialCard))
          .toList();
      expect(cards.map((c) => c.memorial.id), ['b', 'a']);
      expect(find.textContaining('PRIVATE ALIAS'), findsNothing);
    },
  );
}

class _CustomStrings extends ClacksLocalizations {
  const _CustomStrings();
  @override
  String get title => 'Remembering';
}

class _CustomDelegate extends LocalizationsDelegate<ClacksLocalizations> {
  const _CustomDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<ClacksLocalizations> load(Locale locale) =>
      SynchronousFuture(const _CustomStrings());
  @override
  bool shouldReload(_CustomDelegate old) => false;
}

class _PortraitBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object?>{})!;
    }
    if (key == 'portrait.png') {
      return ByteData.sublistView(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGOQ07UBAAD0AIgrn52YAAAAAElFTkSuQmCC',
        ),
      );
    }
    throw FlutterError('Unknown local test asset');
  }
}
