@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_example/main.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

void main() {
  testWidgets('browser example starts offline and opens the local gallery', (
    tester,
  ) async {
    await tester.pumpWidget(const ClacksExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Their names live on.'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.ensureVisible(find.text('Open memorial gallery'));
    await tester.tap(find.text('Open memorial gallery'));
    await tester.pumpAndSettle();
    expect(find.byType(MemorialGallery), findsOneWidget);
    expect(find.text('Tony Stark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
