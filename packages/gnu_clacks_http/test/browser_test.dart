@TestOn('browser')
library;

import 'dart:async';

import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_http/gnu_clacks_http.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../../tool/test_support/browser_server.dart';

void main() {
  test('real Fetch redirects/CORS errors retain normal behaviour without generated headers or retries', () async {
    final server = spawnHybridCode(browserServer);
    final incoming = StreamIterator<dynamic>(server.stream);
    await incoming.moveNext();
    final origins = List<String>.from(incoming.current as List);
    final client = ClacksClient(
      BrowserClient(),
      registry: MemorialRegistry([
        Memorial(
          id: 'a',
          displayName: 'Private',
          networkName: 'Alex',
          networkApproved: true,
        ),
      ]),
      policy: HeaderPolicy(
        enabled: true,
        allowlistedOrigins: [origins.first.replaceFirst('http:', 'https:')],
      ),
    );
    addTearDown(() async {
      client.close();
      await server.sink.close();
      await incoming.cancel();
    });
    final response = await client.get(Uri.parse('${origins.first}/redirect'));
    expect(response.statusCode, 200);
    await expectLater(
      client.get(Uri.parse('${origins.first}/deny')),
      throwsA(isA<http.ClientException>()),
    );
    final noFollow = http.Request('GET', Uri.parse('${origins.first}/redirect'))
      ..followRedirects = false;
    await expectLater(
      client.send(noFollow),
      throwsA(isA<http.ClientException>()),
    );
    expect(noFollow.followRedirects, isFalse);
    await client.get(
      Uri.parse('${origins.first}/host'),
      headers: {'X-Clacks-Overhead': 'GNU Host'},
    );
    await expectLater(
      client.get(
        Uri.parse('${origins.first}/deny-preflight'),
        headers: {'X-Clacks-Overhead': 'GNU Host'},
      ),
      throwsA(isA<http.ClientException>()),
    );
    server.sink.add('records');
    await incoming.moveNext();
    final records = List<Map<String, dynamic>>.from(
      (incoming.current as List).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    expect(
      records.where((r) => r['path'] != '/host').map((r) => r['clacks']),
      everyElement(isNull),
    );
    expect(
      records
          .where((r) => r['path'] == '/host' && r['method'] == 'GET')
          .single['clacks'],
      'GNU Host',
    );
    expect(
      records.where((r) => r['path'] == '/deny-preflight').single['method'],
      'OPTIONS',
    );
    expect(records.where((r) => r['method'] == 'OPTIONS'), hasLength(2));
    expect(records.where((r) => r['path'] == '/deny'), hasLength(1));
    expect(records.where((r) => r['path'] == '/redirect'), hasLength(2));
    expect(records.where((r) => r['path'] == '/ok'), hasLength(1));
  });
}
