# GNU Clacks http

Optional, per-client GNU Clacks integration using `ClacksClient` and the immutable Core registry/policy. Policy defaults off. MIT, copyright 2026 Ydesignz. No Flutter dependency, global interception, telemetry or automatic retries.

Generated headers are limited to the tested native transport when the host has already set `followRedirects=false`, with approved aliases and an exact allowlisted HTTPS origin. Automatic redirects, all browser configurations and unknown transports omit generated values. Existing host values are preserved without merging. The adapter never silently disables redirects.

Read the [integration guide](doc/HTTP_INTEGRATIONS.md) before enabling transmission; it covers setup, transport limitations, request ownership, retries, CORS and lifecycle. Names may be logged by servers/proxies. Multi-name wire compatibility and package-name availability remain unverified.

This unpublished development package is marked `publish_to: none`. From this package directory, run `dart test` for native/pass-through tests and `dart test --platform chrome` for browser tests. Tests need local loopback access. See the repository validation record. A minimal public example is included; the full showcase remains in the repository.

## Quick start

The suite is unpublished. Resolve the checked-out workspace with `flutter pub get`; do not assume a hosted package can be installed yet. The self-contained [public example](example/gnu_clacks_http_example.dart) is compiled and checked with the package source. It uses fictional content and makes no automatic external request.

Read the [security model](doc/SECURITY_MODEL.md), [protocol](doc/PROTOCOL.md), [migration policy](doc/MIGRATION.md) and [platform limits](doc/PLATFORM_MATRIX.md) before integration. Production use and publication still require the recorded release gates.

<!-- EXAMPLE_BEGIN -->
```dart
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
```
<!-- EXAMPLE_END -->
