// Local CPU smoke measurement, not an application cold-start or device benchmark.
import 'dart:convert';

import 'package:gnu_clacks_core/gnu_clacks_core.dart';

void main() {
  final construction = Stopwatch()..start();
  final registry = MemorialRegistry(
    List.generate(
      100,
      (i) => Memorial(
        id: 'sample-$i',
        displayName: 'Fictional Example $i',
        networkName: 'Example $i',
        networkApproved: true,
      ),
    ),
  );
  final enabled = HeaderPolicy(
    enabled: true,
    allowlistedOrigins: ['https://fixture.example'],
  );
  final disabled = HeaderPolicy();
  construction.stop();
  HeaderDecision evaluate(HeaderPolicy policy) => policy.evaluate(
    requestUrl: 'https://fixture.example/echo',
    registry: registry,
    redirectSafetyVerified: true,
  );
  for (var i = 0; i < 1000; i++) {
    evaluate(enabled);
  }
  final expected = evaluate(enabled).value;
  if (expected == null || expected.length > 512) {
    throw StateError('Invalid benchmark policy result.');
  }
  final results = <String, Object>{
    'entries': 100,
    'iterations': 20000,
    'model_and_policy_construction_us': construction.elapsedMicroseconds,
  };
  for (final (name, policy) in [('enabled', enabled), ('disabled', disabled)]) {
    final watch = Stopwatch()..start();
    for (var i = 0; i < 20000; i++) {
      final result = evaluate(policy);
      if (name == 'enabled' && result.value != expected) {
        throw StateError('Non-deterministic result.');
      }
      if (name == 'disabled' && result.value != null) {
        throw StateError('Disabled policy emitted a value.');
      }
    }
    watch.stop();
    results['${name}_us_per_decision'] = watch.elapsedMicroseconds / 20000;
  }
  print(jsonEncode(results));
}
