// Test fixture only. Not product middleware or a production backend.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8443 : int.parse(args.single);
  if (port < 1 || port > 65535) throw ArgumentError('Invalid local test port.');
  final support = File.fromUri(Platform.script).parent.uri
      .resolve('test_support/');
  final context = SecurityContext()
    ..useCertificateChain(
      Platform.environment['GNU_CLACKS_FIXTURE_CERT'] ??
          File.fromUri(support.resolve('localhost-cert.pem')).path,
    )
    ..usePrivateKey(
      Platform.environment['GNU_CLACKS_FIXTURE_KEY'] ??
          File.fromUri(support.resolve('localhost-key.pem')).path,
    );
  final server = await HttpServer.bindSecure(
    InternetAddress.loopbackIPv4,
    port,
    context,
  );
  stdout.writeln(
    'Local HTTPS test fixture on https://127.0.0.1:${server.port}/echo',
  );
  await for (final request in server) {
    final origin = request.headers.value('origin');
    final caller = origin == null ? null : Uri.tryParse(origin);
    if (caller != null &&
        (caller.host == '127.0.0.1' || caller.host == 'localhost') &&
        (caller.scheme == 'http' || caller.scheme == 'https')) {
      request.response.headers.set('access-control-allow-origin', origin!);
      request.response.headers.set('vary', 'Origin');
      request.response.headers.set(
        'access-control-allow-headers',
        'X-Clacks-Overhead, Content-Type',
      );
      request.response.headers.set(
        'access-control-allow-methods',
        'GET, OPTIONS',
      );
    }
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
    } else if (request.method == 'GET' && request.uri.path == '/echo') {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'receivedHeader': request.headers.value('x-clacks-overhead'),
        }),
      );
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.drain<void>();
    await request.response.close();
  }
}
