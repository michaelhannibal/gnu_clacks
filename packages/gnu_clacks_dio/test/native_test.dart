@TestOn('vm')
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_dio/gnu_clacks_dio.dart';
import 'package:test/test.dart';

import '../../../tool/test_support/loopback.dart';

final registry = MemorialRegistry([
  Memorial(
    id: 'a',
    displayName: 'Private display',
    networkName: 'Alex Example',
    networkApproved: true,
  ),
  Memorial(
    id: 'b',
    displayName: 'Visible only',
    networkName: 'Private',
    displayEnabled: true,
  ),
]);

final class OtherIOAdapter extends IOHttpClientAdapter {
  OtherIOAdapter() : super(createHttpClient: Loopback.trustedClient);
}

void main() {
  late Loopback a;
  late Loopback b;
  late Dio dio;
  late ClacksDioInterceptor interceptor;
  setUp(() async {
    a = await Loopback.start();
    b = await Loopback.start();
    dio = Dio()
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: Loopback.trustedClient,
      );
    interceptor = ClacksDioInterceptor.install(
      dio,
      registry: registry,
      policy: HeaderPolicy(enabled: true, allowlistedOrigins: [a.origin]),
    );
  });
  tearDown(() async {
    dio.close(force: true);
    await a.close();
    await b.close();
  });

  Future<Response<String>> send(
    String url, {
    bool follow = false,
    Map<String, dynamic>? headers,
  }) => dio.get<String>(
    url,
    options: Options(
      followRedirects: follow,
      headers: headers,
      responseType: ResponseType.plain,
      validateStatus: (_) => true,
    ),
  );

  test('adds approved alias to private copy after transforms; preserves host options', () async {
    final options = RequestOptions(
      path: a.url('/body').toString(),
      method: 'PUT',
      data: 'payload',
      followRedirects: false,
      persistentConnection: false,
      maxRedirects: 2,
      headers: {
        'Authorization': 'Bearer local',
        'Cookie': 'local=yes',
        'X-Host': 'retained',
      },
      responseType: ResponseType.plain,
      sendTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    );
    final before = Map.of(options.headers);
    final response = await dio.fetch<String>(options);
    expect(response.data, 'received');
    expect(a.observations.single.clacks, 'GNU Alex Example');
    expect(a.observations.single.body, 'payload');
    expect(a.observations.single.method, 'PUT');
    expect(a.observations.single.headers['authorization'], ['Bearer local']);
    expect(a.observations.single.headers['cookie'], ['local=yes']);
    expect(options.headers.keys, containsAll(before.keys));
    expect(
      options.headers.keys.map((s) => s.toLowerCase()),
      isNot(contains('x-clacks-overhead')),
    );
    expect(response.requestOptions, same(options));
    expect(options.followRedirects, isFalse);
    expect(options.persistentConnection, isFalse);
    expect(options.maxRedirects, 2);
    expect(options.sendTimeout, const Duration(seconds: 3));
    expect(options.receiveTimeout, const Duration(seconds: 3));
  });

  test('default-off and unapproved port suppress generated headers', () async {
    dio.interceptors.remove(interceptor);
    ClacksDioInterceptor.install(dio, registry: registry);
    await send(a.origin);
    await send(b.origin);
    expect(a.observations.single.clacks, isNull);
    expect(b.observations.single.clacks, isNull);
  });

  test('mixed-case host header and repeated installation are preserved without merging', () async {
    final repeated = ClacksDioInterceptor.install(
      dio,
      registry: MemorialRegistry([]),
    );
    expect(repeated, same(interceptor));
    await send(a.origin, headers: {'x-cLaCkS-oVeRhEaD': 'GNU Host Supplied'});
    expect(a.observations.single.clacks, 'GNU Host Supplied');
    await send(a.origin);
    expect(a.observations.last.headers['x-clacks-overhead'], [
      'GNU Alex Example',
    ]);
  });

  test('later interceptor URL/redirect edits are evaluated at final transport boundary', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.path = b.origin;
          handler.next(options);
        },
      ),
    );
    await send(a.origin);
    expect(a.observations, isEmpty);
    expect(b.observations.single.clacks, isNull);
    dio.interceptors.removeLast();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.followRedirects = true;
          handler.next(options);
        },
      ),
    );
    await send(a.origin);
    expect(a.observations.single.clacks, isNull);
  });

  test(
    'removing interceptor disables guard; reinstall uses new immutable policy',
    () async {
      dio.interceptors.remove(interceptor);
      await send(a.origin);
      expect(a.observations.single.clacks, isNull);
      ClacksDioInterceptor.install(
        dio,
        registry: registry,
        policy: HeaderPolicy(enabled: true, allowlistedOrigins: [b.origin]),
      );
      await send(a.origin);
      await send(b.origin);
      expect(a.observations.last.clacks, isNull);
      expect(b.observations.single.clacks, 'GNU Alex Example');
    },
  );

  for (final status in [301, 302, 303, 307, 308]) {
    test(
      '$status automatic redirects: no header on initial or final cross-port request',
      () async {
        a.handler = (r) async {
          r.response.statusCode = status;
          r.response.headers.set('location', b.url().toString());
          await r.response.close();
        };
        expect((await send(a.origin, follow: true)).statusCode, 200);
        expect(a.observations.single.clacks, isNull);
        expect(b.observations.single.clacks, isNull);
      },
    );
    test(
      '$status redirects already disabled: initial header without following',
      () async {
        a.handler = (r) async {
          r.response.statusCode = status;
          r.response.headers.set('location', b.url().toString());
          await r.response.close();
        };
        expect((await send(a.origin)).statusCode, status);
        expect(a.observations.single.clacks, 'GNU Alex Example');
        expect(b.observations, isEmpty);
      },
    );
  }

  test(
    'same-origin relative redirects remain unchanged with no generated header',
    () async {
      a.handler = (r) async {
        if (r.uri.path == '/start') {
          r.response.statusCode = 302;
          r.response.headers.set('location', '/end');
        }
        await r.response.close();
      };
      await send(a.url('/start').toString(), follow: true);
      expect(a.observations.map((o) => o.path), ['/start', '/end']);
      expect(a.observations.map((o) => o.clacks), everyElement(isNull));
    },
  );

  test(
    'downgrade and HTTP-to-HTTPS redirects never acquire a generated header',
    () async {
      final plain = await Loopback.start(secure: false);
      addTearDown(plain.close);
      a.handler = (r) async {
        r.response.statusCode = 302;
        r.response.headers.set('location', plain.url().toString());
        await r.response.close();
      };
      await send(a.origin, follow: true);
      expect(plain.observations.single.clacks, isNull);
      plain.handler = (r) async {
        r.response.statusCode = 302;
        r.response.headers.set('location', b.url().toString());
        await r.response.close();
      };
      await send(plain.origin, follow: true);
      expect(b.observations.single.clacks, isNull);
      expect(a.observations.single.clacks, isNull);
    },
  );

  test(
    'multipart form data, response transforms and upload progress still work',
    () async {
      var sent = 0;
      final data = FormData.fromMap({
        'message': 'hello',
        'file': MultipartFile.fromString('content', filename: 'local.txt'),
      });
      final response = await dio.post<String>(
        a.origin,
        data: data,
        options: Options(
          followRedirects: false,
          responseType: ResponseType.plain,
        ),
        onSendProgress: (count, _) => sent = count,
      );
      expect(response.data, 'received');
      final observed = a.observations.single;
      expect(observed.clacks, 'GNU Alex Example');
      expect(observed.body, contains('hello'));
      expect(observed.body, contains('content'));
      expect(observed.headers['content-type']!.single, contains('boundary='));
      expect(sent, greaterThan(0));
    },
  );

  test(
    'caller retries use host options with no stale generated header',
    () async {
      var attempts = 0;
      a.handler = (r) async {
        r.response.statusCode = ++attempts == 1 ? 503 : 200;
        await r.response.close();
      };
      dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) async {
            if (error.response?.statusCode == 503) {
              expect(
                error.requestOptions.headers.keys.map((s) => s.toLowerCase()),
                isNot(contains('x-clacks-overhead')),
              );
              final retry = await dio.fetch<dynamic>(error.requestOptions);
              handler.resolve(retry);
            } else {
              handler.next(error);
            }
          },
        ),
      );
      final response = await dio.get<String>(
        a.origin,
        options: Options(
          followRedirects: false,
          responseType: ResponseType.plain,
        ),
      );
      expect(response.statusCode, 200);
      expect(a.observations.map((o) => o.clacks), [
        'GNU Alex Example',
        'GNU Alex Example',
      ]);
    },
  );

  test(
    'cancellation and receive timeouts propagate without hidden retries',
    () async {
      final release = Completer<void>();
      a.handler = (r) async {
        await release.future;
        await r.response.close();
      };
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      final token = CancelToken();
      final pending = dio.get<String>(
        a.origin,
        cancelToken: token,
        options: Options(followRedirects: false),
      );
      final assertion = expectLater(
        pending,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      await a.waitForRequests(1);
      token.cancel();
      await assertion;
      await expectLater(
        dio.get<String>(
          a.origin,
          options: Options(
            followRedirects: false,
            receiveTimeout: const Duration(milliseconds: 30),
          ),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.receiveTimeout,
          ),
        ),
      );
      expect(a.observations, hasLength(2));
      release.complete();
    },
  );

  test(
    'transport timeout errors retain no generated header for retry/logging',
    () async {
      final release = Completer<void>();
      a.handler = (r) async {
        await release.future;
        await r.response.close();
      };
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      try {
        await dio.get<String>(
          a.origin,
          options: Options(
            followRedirects: false,
            receiveTimeout: const Duration(milliseconds: 30),
          ),
        );
        fail('Expected receive timeout');
      } on DioException catch (error) {
        expect(error.type, DioExceptionType.receiveTimeout);
        expect(
          error.requestOptions.headers.keys.map((s) => s.toLowerCase()),
          isNot(contains('x-clacks-overhead')),
        );
        error.requestOptions.path = b.origin;
        error.requestOptions.receiveTimeout = const Duration(seconds: 2);
        await dio.fetch<dynamic>(error.requestOptions);
        expect(b.observations.single.clacks, isNull);
      }
      release.complete();
    },
  );

  test(
    'encoded raw authority is not approved through URI normalisation',
    () async {
      final encoded = a.origin.replaceFirst('127', '%31%32%37');
      await send(encoded);
      expect(a.observations.single.clacks, isNull);
    },
  );

  test('HTTP errors remain errors and close delegates', () async {
    a.handler = (r) async {
      r.response.statusCode = 418;
      await r.response.close();
    };
    await expectLater(
      dio.get<String>(a.origin, options: Options(followRedirects: false)),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          418,
        ),
      ),
    );
    dio.close(force: true);
    await expectLater(send(a.origin), throwsA(isA<DioException>()));
  });
  test('unproven native adapter subclasses omit generated values', () async {
    final custom = Dio()..httpClientAdapter = OtherIOAdapter();
    addTearDown(() => custom.close(force: true));
    ClacksDioInterceptor.install(
      custom,
      registry: registry,
      policy: HeaderPolicy(enabled: true, allowlistedOrigins: [a.origin]),
    );
    await custom.get<dynamic>(
      a.origin,
      options: Options(followRedirects: false),
    );
    expect(a.observations.single.clacks, isNull);
  });
}
