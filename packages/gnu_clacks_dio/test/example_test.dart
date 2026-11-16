@TestOn('vm')
library;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:test/test.dart';

import '../example/gnu_clacks_dio_example.dart' as example;
import '../../../tool/test_support/loopback.dart';

void main() {
  test('public Dio example uses the installed final dispatch guard', () async {
    final fixture = await Loopback.start();
    addTearDown(fixture.close);
    final dio = Dio()
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: Loopback.trustedClient,
      );
    addTearDown(() => dio.close(force: true));
    final response = await example.fetchWithTribute(
      dio: dio,
      destination: fixture.origin,
      registry: MemorialRegistry([
        Memorial(
          id: 'a',
          displayName: 'Fictional',
          networkApproved: true,
          networkName: 'Alex Example',
        ),
      ]),
      policy: HeaderPolicy(enabled: true, allowlistedOrigins: [fixture.origin]),
    );
    expect(response.data, 'received');
    expect(fixture.observations.single.clacks, 'GNU Alex Example');
  });
}
