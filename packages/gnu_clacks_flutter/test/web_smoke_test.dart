@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

void main() {
  testWidgets(
    'browser gallery respects visibility and uses the configured navigation callback',
    (tester) async {
      final registry = MemorialRegistry([
        Memorial(id: 'a', displayName: 'Alex Example', displayEnabled: true),
        Memorial(id: 'hidden', displayName: 'Hidden', networkApproved: true),
      ]);
      var selected = '';
      await tester.pumpWidget(
        MaterialApp(
          home: MemorialGallery(
            registry: registry,
            onOpenMemorial: (m) => selected = m.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alex Example'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
      await tester.tap(find.text('Alex Example'));
      expect(selected, 'a');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'browser detail with reduced motion stays static and retains content',
    (tester) async {
      final registry = MemorialRegistry([
        Memorial(
          id: 'a',
          displayName: 'Alex Example',
          dedication: 'Remembered locally.',
          displayEnabled: true,
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MemorialDetailScreen(registry: registry, memorialId: 'a'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remembered locally.'), findsOneWidget);
      expect(find.text('GNU Alex Example'), findsOneWidget);
      expect(find.text('Pause motion'), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
