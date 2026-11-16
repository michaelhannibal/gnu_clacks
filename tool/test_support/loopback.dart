// Test-only loopback servers. The bundled self-signed key is public test data.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

final class Observation {
  Observation(this.method, this.path, this.headers, this.body);
  final String method;
  final String path;
  final Map<String, List<String>> headers;
  final String body;
  String? get clacks => headers['x-clacks-overhead']?.join(', ');
}

final class Loopback {
  Loopback._(this.server, this.secure) {
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final headers = <String, List<String>>{};
      request.headers.forEach(
        (name, values) => headers[name] = List.of(values),
      );
      observations.add(
        Observation(request.method, request.uri.path, headers, body),
      );
      _arrived.add(null);
      if (handler != null) {
        await handler!(request);
      } else {
        request.response.headers.contentType = ContentType.text;
        request.response.write('received');
        await request.response.close();
      }
    });
  }

  final HttpServer server;
  final bool secure;
  final observations = <Observation>[];
  final _arrived = StreamController<void>.broadcast();
  Future<void> Function(HttpRequest)? handler;
  String get origin =>
      '${secure ? 'https' : 'http'}://127.0.0.1:${server.port}';
  Uri url([String path = '/']) => Uri.parse('$origin$path');

  static Directory get support => Directory.fromUri(
    // Native tests run from their package directory.
    Directory.current.uri.resolve('../../tool/test_support/'),
  );

  static Future<Loopback> start({bool secure = true}) async {
    if (!secure) {
      return Loopback._(
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
        false,
      );
    }
    final context = SecurityContext()
      ..useCertificateChain('${support.path}/localhost-cert.pem')
      ..usePrivateKey('${support.path}/localhost-key.pem');
    return Loopback._(
      await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context),
      true,
    );
  }

  static HttpClient trustedClient() => HttpClient(
    context: SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificates('${support.path}/localhost-cert.pem'),
  )..findProxy = (_) => 'DIRECT';

  Future<void> waitForRequests(int count) async {
    if (observations.length >= count) return;
    await _arrived.stream
        .firstWhere((_) => observations.length >= count)
        .timeout(const Duration(seconds: 5));
  }

  Future<void> close() async {
    await server.close(force: true);
    await _arrived.close();
  }
}
