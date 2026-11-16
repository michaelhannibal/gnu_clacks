import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_http/gnu_clacks_http.dart';
import 'package:http/http.dart' as http;

/// Called only by a host that already chooses a no-follow request.
/// The caller explicitly supplies its transport, policy and approved registry.
Future<http.Response> fetchWithTribute({
  required http.Client transport,
  required Uri destination,
  required MemorialRegistry registry,
  required HeaderPolicy policy,
}) async {
  final client = ClacksClient(transport, registry: registry, policy: policy);
  try {
    final request = http.Request('GET', destination)..followRedirects = false;
    return await http.Response.fromStream(await client.send(request));
  } finally {
    client.close(); // The body is consumed before closing the owned transport.
  }
}

/// Running this file does not contact the example.org address or create a client.
void main() {}
