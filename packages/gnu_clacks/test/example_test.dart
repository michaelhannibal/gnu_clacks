import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks/gnu_clacks.dart';

import '../example/gnu_clacks_example.dart';

void main() {
  testWidgets('example lists the memorials and relays a name', (tester) async {
    await tester.pumpWidget(createTributeApp(animate: false));
    await tester.pumpAndSettle();
    for (final name in ['Alex Example', 'Sam Example']) {
      expect(find.textContaining(name), findsWidgets, reason: name);
    }

    await tester.tap(find.textContaining('Alex Example').first);
    await tester.pumpAndSettle();
    expect(find.byType(ClacksSignal), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('example names are display-only', () {
    expect(exampleRegistry.entries.every((m) => !m.networkApproved), isTrue);
    final decision = HeaderPolicy().evaluate(
      requestUrl: 'https://example.org',
      registry: exampleRegistry,
    );
    expect(decision.value, isNull);
  });
}
