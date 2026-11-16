import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

void main() {
  final registry = MemorialRegistry([
    Memorial(
      id: 'pictured',
      displayName: 'Pictured Person',
      displayEnabled: true,
      imageAsset: 'assets/missing.png',
      imageAltText: 'A portrait.',
    ),
    Memorial(id: 'name-only', displayName: 'Name Only', displayEnabled: true),
  ]);
  const backdrop = ValueKey('clacks-detail-backdrop');

  Widget detail(String id) => MaterialApp(
    home: MemorialDetailScreen(
      registry: registry,
      memorialId: id,
      animate: false,
    ),
  );

  testWidgets(
    'backdrop and portrait appear only when the person has an image',
    (tester) async {
      await tester.pumpWidget(detail('pictured'));
      await tester.pumpAndSettle();
      expect(find.byKey(backdrop), findsOneWidget);
      expect(find.byType(MemorialPortrait), findsOneWidget);
      // A missing asset falls back to nothing, without an error.
      expect(tester.takeException(), isNull);

      // No image: no backdrop and no placeholder portrait.
      await tester.pumpWidget(detail('name-only'));
      await tester.pumpAndSettle();
      expect(find.byKey(backdrop), findsNothing);
      expect(find.byType(MemorialPortrait), findsNothing);
      // The relay sends GNU, the name and END.
      expect(
        find.text('GNU Name Only\u00a0END', findRichText: true),
        findsWidgets,
      );
    },
  );

  testWidgets('backdrop is hidden from screen readers', (tester) async {
    await tester.pumpWidget(detail('pictured'));
    await tester.pumpAndSettle();
    final excluded = tester.widget<ExcludeSemantics>(
      find
          .ancestor(
            of: find.byKey(backdrop),
            matching: find.byType(ExcludeSemantics),
          )
          .first,
    );
    expect(excluded.excluding, isTrue);
    expect(
      find.ancestor(
        of: find.byKey(backdrop),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
  });

  test('text stays readable over a black or white backdrop in every theme', () {
    for (final appearance in ClacksAppearance.values) {
      final tokens = ClacksTheme.appearance(appearance, ThemeData());
      for (final extreme in [Colors.black, Colors.white]) {
        // Same sRGB source-over blend the backdrop uses: 10% image.
        final behind = Color.alphaBlend(
          tokens.background.withValues(alpha: .9),
          extreme,
        );
        for (final text in [
          tokens.ink(tokens.background),
          tokens.accentOn(tokens.background),
        ]) {
          expect(
            ClacksTheme.contrast(text, behind),
            greaterThanOrEqualTo(4.5),
            reason: '$appearance over $extreme',
          );
        }
      }
    }
  });
}
