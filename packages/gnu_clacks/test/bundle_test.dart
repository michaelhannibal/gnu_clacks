import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks/gnu_clacks.dart';

void main() {
  testWidgets('umbrella exposes the UI and optional adapters without opt-in', (
    tester,
  ) async {
    final registry = MemorialRegistry([]);
    expect(ClacksClient, isNotNull);
    expect(ClacksDioInterceptor, isNotNull);
    final decision = HeaderPolicy().evaluate(
      requestUrl: 'https://example.org',
      registry: registry,
    );
    expect(decision.value, isNull);
    await tester.pumpWidget(
      MaterialApp(home: MemorialGallery(registry: registry)),
    );
    expect(find.byType(MemorialGallery), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
