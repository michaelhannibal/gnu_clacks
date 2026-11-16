@TestOn('vm')
library;

import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:http/io_client.dart';
import 'package:test/test.dart';

import '../example/gnu_clacks_http_example.dart' as example;
import '../../../tool/test_support/loopback.dart';

void main() {
  test(
    'public HTTP example consumes its response and preserves the privacy gate',
    () async {
      final fixture = await Loopback.start();
      addTearDown(fixture.close);
      final response = await example.fetchWithTribute(
        transport: IOClient(Loopback.trustedClient()),
        destination: fixture.url(),
        registry: MemorialRegistry([
          Memorial(
            id: 'a',
            displayName: 'Fictional',
            networkApproved: true,
            networkName: 'Alex Example',
          ),
        ]),
        policy: HeaderPolicy(
          enabled: true,
          allowlistedOrigins: [fixture.origin],
        ),
      );
      expect(response.body, 'received');
      expect(fixture.observations.single.clacks, 'GNU Alex Example');
    },
  );
}
