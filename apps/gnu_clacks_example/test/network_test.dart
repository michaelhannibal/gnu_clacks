@TestOn('vm')
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:gnu_clacks_example/demo_network.dart';
import 'package:gnu_clacks_example/memorials.dart';
import 'package:http/io_client.dart';
import 'package:test/test.dart';

import '../../../tool/test_support/loopback.dart';

void main() {
  test('invalid, remote and non-HTTPS test origins are rejected before client creation', () async {
    var created = 0;
    for (final origin in [
      '',
      'http://localhost:8443',
      'https://example.org',
      'https://127.0.0.1.evil.org',
      'https://localhost/path',
    ]) {
      final network = DemoNetwork(
        registry: exampleRegistry,
        origin: origin,
        httpFactory: () {
          created++;
          throw StateError('Client');
        },
        dioFactory: () {
          created++;
          throw StateError('Client');
        },
      );
      expect(network.configured, isFalse);
      await expectLater(network.sendHttp(enabled: true), throwsStateError);
      await expectLater(network.sendDio(enabled: true), throwsStateError);
    }
    expect(created, 0);
  });

  for (final useDio in [false, true]) {
    test(
      '${useDio ? 'Dio' : 'HTTP'} demo sends only approved fictional alias on explicit opt-in',
      () async {
        final fixture = await Loopback.start();
        addTearDown(fixture.close);
        fixture.handler = (request) async {
          request.response.headers.set('content-type', 'application/json');
          request.response.write(
            jsonEncode({
              'receivedHeader': request.headers.value('x-clacks-overhead'),
            }),
          );
          await request.response.close();
        };
        final network = DemoNetwork(
          registry: exampleRegistry,
          origin: fixture.origin,
          httpFactory: () => IOClient(Loopback.trustedClient()),
          dioFactory: () => Dio()
            ..httpClientAdapter = IOHttpClientAdapter(
              createHttpClient: Loopback.trustedClient,
            ),
        );
        expect(network.configured, isTrue);
        expect(fixture.observations, isEmpty);
        final disabled = useDio
            ? await network.sendDio(enabled: false)
            : await network.sendHttp(enabled: false);
        expect(disabled.status, 200);
        expect(disabled.receivedHeader, isNull);
        final enabled = useDio
            ? await network.sendDio(enabled: true)
            : await network.sendHttp(enabled: true);
        expect(enabled.receivedHeader, 'GNU Alex Example');
        expect(fixture.observations, hasLength(2));
        expect(fixture.observations.last.body, isEmpty);
      },
    );
  }

  test(
    'sample registry has separate display/network flags and local assets',
    () {
      expect(exampleRegistry.displayEntries, hasLength(3));
      expect(
        exampleRegistry.entries
            .where((e) => e.networkApproved)
            .map((e) => e.id),
        ['alex-example'],
      );
      expect(
        exampleRegistry.entries
            .where((e) => e.imageAsset != null)
            .every((e) => e.imageAsset!.startsWith('assets/')),
        isTrue,
      );
    },
  );
}
