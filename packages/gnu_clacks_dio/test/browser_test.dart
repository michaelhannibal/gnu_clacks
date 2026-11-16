@TestOn('browser')
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_dio/gnu_clacks_dio.dart';
import 'package:test/test.dart';

import '../../../tool/test_support/browser_server.dart';

void main() {
  test('real XHR redirects and CORS errors pass through without generated headers or retries', () async {
    final server = spawnHybridCode(browserServer);
    final incoming = StreamIterator<dynamic>(server.stream);
    await incoming.moveNext();
    final origins = List<String>.from(incoming.current as List);
    final dio = Dio();
    ClacksDioInterceptor.install(
      dio,
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
      dio.close(force: true);
      await server.sink.close();
      await incoming.cancel();
    });
    expect(
      (await dio.get<dynamic>(
        '${origins.first}/redirect',
        options: Options(followRedirects: false),
      )).statusCode,
      200,
    );
    await expectLater(
      dio.get<dynamic>('${origins.first}/deny'),
      throwsA(isA<DioException>()),
    );
    await dio.get<dynamic>(
      '${origins.first}/host',
      options: Options(headers: {'X-Clacks-Overhead': 'GNU Host'}),
    );
    await expectLater(
      dio.get<dynamic>(
        '${origins.first}/deny-preflight',
        options: Options(headers: {'X-Clacks-Overhead': 'GNU Host'}),
      ),
      throwsA(isA<DioException>()),
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
    expect(records.where((r) => r['path'] == '/redirect'), hasLength(1));
    expect(records.where((r) => r['path'] == '/ok'), hasLength(1));
  });
}
