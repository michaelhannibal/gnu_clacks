# GNU Clacks dio

Optional, per-client GNU Clacks integration using `ClacksDioInterceptor.install` and the immutable Core registry/policy. Policy defaults off. MIT, copyright 2026 Ydesignz. No Flutter dependency, global interception, telemetry or automatic retries.

Generated headers are limited to the tested native transport when the host has already set `followRedirects=false`, with approved aliases and an exact allowlisted HTTPS origin. Automatic redirects, all browser configurations and unknown transports omit generated values. Existing host values are preserved without merging. The adapter never silently disables redirects.

Read the [integration guide](doc/HTTP_INTEGRATIONS.md) before enabling transmission; it covers setup, transport limitations, request ownership, retries, CORS and lifecycle. Names may be logged by servers/proxies. Multi-name wire compatibility and package-name availability remain unverified.

This unpublished development package is marked `publish_to: none`. From this package directory, run `dart test` for native/pass-through tests and `dart test --platform chrome` for browser tests. Tests need local loopback access. See the repository validation record. A minimal public example is included; the full showcase remains in the repository.

## Quick start

The suite is unpublished. Resolve the checked-out workspace with `flutter pub get`; do not assume a hosted package can be installed yet. The self-contained [public example](example/gnu_clacks_dio_example.dart) is compiled and checked with the package source. It uses fictional content and makes no automatic external request.

Read the [security model](doc/SECURITY_MODEL.md), [protocol](doc/PROTOCOL.md), [migration policy](doc/MIGRATION.md) and [platform limits](doc/PLATFORM_MATRIX.md) before integration. Production use and publication still require the recorded release gates.

<!-- EXAMPLE_BEGIN -->
```dart
import 'package:dio/dio.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_dio/gnu_clacks_dio.dart';

/// Configure the transport before calling this function. The caller owns Dio's
/// lifecycle and deliberately chooses no-follow behaviour for this request.
Future<Response<String>> fetchWithTribute({
  required Dio dio,
  required String destination,
  required MemorialRegistry registry,
  required HeaderPolicy policy,
}) async {
  ClacksDioInterceptor.install(dio, registry: registry, policy: policy);
  return dio.get<String>(
    destination,
    options: Options(followRedirects: false, responseType: ResponseType.plain),
  );
}

/// Running this file does not create a client or contact any destination.
void main() {}
```
<!-- EXAMPLE_END -->
