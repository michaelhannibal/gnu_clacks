@TestOn('vm')
library;

import 'dart:async';

import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_http/gnu_clacks_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/retry.dart';
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

final class OtherIOClient extends IOClient {
  OtherIOClient() : super(Loopback.trustedClient());
}

void main() {
  late Loopback a;
  late Loopback b;
  late ClacksClient client;
  setUp(() async {
    a = await Loopback.start();
    b = await Loopback.start();
    client = ClacksClient(
      IOClient(Loopback.trustedClient()),
      registry: registry,
      policy: HeaderPolicy(enabled: true, allowlistedOrigins: [a.origin]),
    );
  });
  tearDown(() async {
    client.close();
    await a.close();
    await b.close();
  });

  Future<http.Response> send(
    Uri uri, {
    bool follow = false,
    Map<String, String>? headers,
  }) async {
    final request = http.Request('GET', uri)..followRedirects = follow;
    request.headers.addAll(headers ?? {});
    return http.Response.fromStream(await client.send(request));
  }

  test(
    'adds only approved aliases and preserves caller headers/options/body',
    () async {
      final request = http.Request('PUT', a.url('/echo?x=1'))
        ..followRedirects = false
        ..maxRedirects = 2
        ..persistentConnection = false
        ..body = 'payload';
      request.headers.addAll({
        'Authorization': 'Bearer local',
        'Cookie': 'local=yes',
        'X-Host': 'retained',
      });
      final before = Map.of(request.headers);
      final response = await http.Response.fromStream(
        await client.send(request),
      );
      expect(response.statusCode, 200);
      expect(response.body, 'received');
      expect(
        response.request!.headers.containsKey(HeaderPolicy.headerName),
        isFalse,
      );
      expect(a.observations.single.clacks, 'GNU Alex Example');
      expect(a.observations.single.method, 'PUT');
      expect(a.observations.single.body, 'payload');
      expect(a.observations.single.headers['authorization'], ['Bearer local']);
      expect(a.observations.single.headers['cookie'], ['local=yes']);
      expect(request.headers, before);
      expect(request.finalized, isTrue);
      expect(request.followRedirects, isFalse);
      expect(request.maxRedirects, 2);
      expect(request.persistentConnection, isFalse);
    },
  );

  test('default-off and unapproved port requests are unchanged', () async {
    final disabled = ClacksClient(
      IOClient(Loopback.trustedClient()),
      registry: registry,
    );
    addTearDown(disabled.close);
    final request = http.Request('GET', a.url())..followRedirects = false;
    await (await disabled.send(request)).stream.drain<void>();
    await send(b.url());
    expect(a.observations.single.clacks, isNull);
    expect(b.observations.single.clacks, isNull);
  });

  test(
    'host header stays exact and repeated wrappers never stack names',
    () async {
      await send(a.url(), headers: {'x-cLaCkS-oVeRhEaD': 'GNU Host Supplied'});
      expect(a.observations.single.clacks, 'GNU Host Supplied');
      client = ClacksClient(
        client,
        registry: registry,
        policy: HeaderPolicy(enabled: true, allowlistedOrigins: [a.origin]),
      );
      await send(a.url());
      expect(a.observations.last.headers['x-clacks-overhead'], [
        'GNU Alex Example',
      ]);
    },
  );

  for (final status in [301, 302, 303, 307, 308]) {
    test(
      '$status redirects enabled: no header on initial or cross-port destination',
      () async {
        a.handler = (r) async {
          r.response.statusCode = status;
          r.response.headers.set('location', b.url().toString());
          await r.response.close();
        };
        expect((await send(a.url(), follow: true)).statusCode, 200);
        expect(a.observations.single.clacks, isNull);
        expect(b.observations.single.clacks, isNull);
      },
    );
    test(
      '$status redirects already disabled: header on initial request, no follow',
      () async {
        a.handler = (r) async {
          r.response.statusCode = status;
          r.response.headers.set('location', b.url().toString());
          await r.response.close();
        };
        expect((await send(a.url())).statusCode, status);
        expect(a.observations.single.clacks, 'GNU Alex Example');
        expect(b.observations, isEmpty);
      },
    );
  }

  test(
    'relative redirects follow unchanged without a generated header',
    () async {
      a.handler = (r) async {
        if (r.uri.path == '/start') {
          r.response.statusCode = 302;
          r.response.headers.set('location', '/end');
        }
        await r.response.close();
      };
      await send(a.url('/start'), follow: true);
      expect(a.observations.map((o) => o.path), ['/start', '/end']);
      expect(a.observations.map((o) => o.clacks), everyElement(isNull));
    },
  );

  test('HTTP downgrade and HTTP-to-HTTPS redirects never acquire a generated header', () async {
    final plain = await Loopback.start(secure: false);
    addTearDown(plain.close);
    a.handler = (r) async {
      r.response.statusCode = 302;
      r.response.headers.set('location', plain.url().toString());
      await r.response.close();
    };
    await send(a.url(), follow: true);
    expect(plain.observations.single.clacks, isNull);
    plain.handler = (r) async {
      r.response.statusCode = 302;
      r.response.headers.set('location', b.url().toString());
      await r.response.close();
    };
    await send(plain.url(), follow: true);
    expect(b.observations.single.clacks, isNull);
    expect(a.observations.single.clacks, isNull);
  });

  test(
    'manual new request re-evaluates approved and unapproved destinations',
    () async {
      await send(a.url());
      await send(b.url());
      expect(a.observations.single.clacks, 'GNU Alex Example');
      expect(b.observations.single.clacks, isNull);
      final both = ClacksClient(
        IOClient(Loopback.trustedClient()),
        registry: registry,
        policy: HeaderPolicy(
          enabled: true,
          allowlistedOrigins: [a.origin, b.origin],
        ),
      );
      addTearDown(both.close);
      await (await both.send(
        http.Request('GET', b.url())..followRedirects = false,
      )).stream.drain<void>();
      expect(b.observations.last.clacks, 'GNU Alex Example');
    },
  );

  test(
    'multipart finalisation preserves boundary, fields, files and byte length',
    () async {
      final request = http.MultipartRequest('POST', a.url())
        ..followRedirects = false
        ..fields['message'] = 'hello'
        ..files.add(
          http.MultipartFile.fromString(
            'file',
            'content',
            filename: 'local.txt',
          ),
        );
      await (await client.send(request)).stream.drain<void>();
      final observed = a.observations.single;
      expect(observed.clacks, 'GNU Alex Example');
      expect(observed.headers['content-type']!.single, contains('boundary='));
      expect(observed.body, contains('hello'));
      expect(observed.body, contains('content'));
      expect(
        observed.headers['content-length']!.single,
        request.contentLength.toString(),
      );
      expect(request.headers.containsKey(HeaderPolicy.headerName), isFalse);
    },
  );

  test('streamed bodies are forwarded once without buffering', () async {
    final request = http.StreamedRequest('POST', a.url())
      ..followRedirects = false;
    final response = client.send(request);
    request.sink.add([65, 66]);
    await request.sink.close();
    await (await response).stream.drain<void>();
    expect(a.observations.single.body, 'AB');
    expect(a.observations.single.clacks, 'GNU Alex Example');
  });

  test('cancellation and caller timeouts propagate, without retries', () async {
    final release = Completer<void>();
    a.handler = (r) async {
      await release.future;
      await r.response.close();
    };
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final abort = Completer<void>();
    final request = http.AbortableRequest(
      'GET',
      a.url(),
      abortTrigger: abort.future,
    )..followRedirects = false;
    final pending = client.send(request);
    final assertion = expectLater(
      pending,
      throwsA(isA<http.RequestAbortedException>()),
    );
    await a.waitForRequests(1);
    abort.complete();
    await assertion;
    expect(a.observations, hasLength(1));
    final second = client.send(
      http.Request('GET', a.url())..followRedirects = false,
    );
    await expectLater(
      second.timeout(const Duration(milliseconds: 30)),
      throwsA(isA<TimeoutException>()),
    );
    release.complete();
    await (await second).stream.drain<void>();
    expect(a.observations, hasLength(2));
  });

  test('retries outside the wrapper regenerate a single header without touching input', () async {
    var attempts = 0;
    a.handler = (r) async {
      r.response.statusCode = ++attempts == 1 ? 503 : 200;
      await r.response.close();
    };
    final retry = RetryClient(client, retries: 1, delay: (_) => Duration.zero);
    addTearDown(retry.close);
    final request = http.Request('GET', a.url())..followRedirects = false;
    await (await retry.send(request)).stream.drain<void>();
    expect(a.observations.map((o) => o.clacks), [
      'GNU Alex Example',
      'GNU Alex Example',
    ]);
    expect(request.headers.containsKey(HeaderPolicy.headerName), isFalse);
  });

  test(
    'close delegates; errors and response status are not suppressed',
    () async {
      a.handler = (r) async {
        r.response.statusCode = 418;
        await r.response.close();
      };
      expect((await send(a.url())).statusCode, 418);
      client.close();
      await expectLater(send(a.url()), throwsA(isA<http.ClientException>()));
    },
  );
  test(
    'unproven native IOClient subclasses pass through without generation',
    () async {
      final custom = ClacksClient(
        OtherIOClient(),
        registry: registry,
        policy: HeaderPolicy(enabled: true, allowlistedOrigins: [a.origin]),
      );
      addTearDown(custom.close);
      await (await custom.send(
        http.Request('GET', a.url())..followRedirects = false,
      )).stream.drain<void>();
      expect(a.observations.single.clacks, isNull);
    },
  );
}
