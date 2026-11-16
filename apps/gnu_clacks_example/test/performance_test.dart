import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_example/main.dart';

void main() {
  testWidgets('warm initial layout smoke and static idle scheduling', (
    tester,
  ) async {
    final samples = <int>[];
    for (var i = 0; i < 5; i++) {
      await tester.pumpWidget(const SizedBox.shrink());
      final watch = Stopwatch()..start();
      await tester.pumpWidget(ClacksExampleApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      watch.stop();
      samples.add(watch.elapsedMicroseconds);
      expect(tester.binding.transientCallbackCount, 0);
    }
    samples.sort();
    // Harness/layout observations only. Never label these as cold-start/FPS.
    debugPrint(
      'PERFORMANCE_SMOKE ${jsonEncode({'samples': 5, 'warm_layout_median_us': samples[2], 'warm_layout_max_us': samples.last, 'idle_transient_callbacks': tester.binding.transientCallbackCount})}',
    );
  });
}
