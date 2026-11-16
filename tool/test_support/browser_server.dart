// Sent to spawnHybridCode by browser tests; no production server or backend.
const browserServer = r'''
import 'dart:io';
import 'dart:convert';

void hybridMain(dynamic channel) async {
  final servers = [
    await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
  ];
  final records = <Map<String, Object?>>[];
  for (final server in servers) {
    server.listen((request) async {
      await request.drain<void>();
      records.add({
        'port': server.port,
        'method': request.method,
        'path': request.uri.path,
        'clacks': request.headers.value('x-clacks-overhead'),
      });
      final response = request.response;
      if (!request.uri.path.startsWith('/deny')) {
        response.headers.set('access-control-allow-origin', '*');
        response.headers.set('access-control-allow-headers', 'X-Clacks-Overhead, Content-Type');
        response.headers.set('access-control-allow-methods', 'GET, POST, OPTIONS');
      }
      if (request.uri.path == '/redirect') {
        response.statusCode = 302;
        response.headers.set('location', 'http://127.0.0.1:${servers.last.port}/ok');
      } else {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({'ok': true}));
      }
      await response.close();
    });
  }
  channel.sink.add(servers.map((s) => 'http://127.0.0.1:${s.port}').toList());
  channel.stream.listen((dynamic message) {
    if (message == 'records') channel.sink.add(records);
  }, onDone: () async {
    for (final server in servers) await server.close(force: true);
  });
}
''';
