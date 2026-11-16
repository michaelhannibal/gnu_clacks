# GNU Clacks Core

Pure Dart memorial definitions and a default-off, exact-origin HTTP header policy. No Flutter imports, runtime dependencies, I/O, timers, persistence or telemetry. This is an unpublished development package; package-name availability is unverified.

## API

Import `package:gnu_clacks_core/gnu_clacks_core.dart`.

| API | Purpose |
|---|---|
| `Memorial` | Immutable developer-owned content; display and network approval independently default off |
| `PartialDate` | Year, optional month, optional day; calendar validation without invented precision |
| `AssetAttribution` | Local creator, provenance, licence/permission and notice records |
| `MemorialRegistry` | Defensive immutable snapshot with unique trimmed IDs and filtered display entries |
| `ClacksLampCode.encode` | Nine-lamp display pattern for one character (8-bit ASCII on the outer ring; centre lamp only for `ClacksLampCode.end`); display only, never used in headers |
| `HttpsOrigin.tryParse` | Validate an allowlist origin under the conservative ASCII v1 profile |
| `HttpsOrigin.forRequest` | Extract an origin from a raw request URL without DNS or IDNA conversion |
| `normaliseNetworkName` | Validate an explicit alias, then trim/collapse ASCII spaces; no transliteration |
| `HeaderPolicy.evaluate` | Return a generated value to add, or null to leave the host request unchanged |
| `HeaderDecision.diagnostics` | Immutable enum codes containing no IDs, names, values or URLs |

A policy is disabled by default with an empty allowlist. To generate a value, enable it, configure exact HTTPS origins, approve individual entries, supply valid explicit aliases, and have a proven transport integration assert redirect safety. `redirectSafetyVerified` defaults false and does not itself verify any transport. Core never attaches a header.

`evaluate` accepts the **raw URL string** so unsupported authority spellings can be rejected before URI normalisation. Preserve raw input when available; Core cannot reconstruct information already discarded by another parser. IDNs require externally validated ASCII punycode. IPv6, Unicode hostnames, encoded hostnames and ambiguous numeric hosts are outside the v1 profile.

Pass existing header **names** to `existingHeaderNames`. An existing field in any casing suppresses generation; its value is neither inspected nor merged. The caller remains responsible for preserving its request. Generated values must be tracked separately, removed before redirect recomputation, and recalculated for every resolved destination. No redirect-following mechanism is included here. A client with unproven redirect handling must omit generated headers from the initial request.

Invalid network aliases are omitted with a diagnostic, leaving display content usable. Invalid budgets or any invalid allowlist entry disable the entire policy for transmission. Invalid required model text, duplicate IDs, invalid dates and non-local asset references throw generic `ArgumentError`s without embedding the supplied values. Core validates asset syntax, not existence, decoding, rights or permission. Optional dates remain independent; no lifespan or cultural assumptions are inferred.

The single-name value follows `GNU Name`. Multiple names use a project-specific comma-separated format with a `GNU ` prefix for every name; interoperability is unverified. Aliases are sorted and deduplicated case-sensitively. Whole names that exceed the byte budget are skipped; later names may fit. The default value budget is 512 bytes with a hard maximum of 1024. See [the protocol](doc/PROTOCOL.md) for complete rules.

Do not log `HeaderDecision.value`. HTTP servers and proxies can log transmitted names; the letter N does not prohibit this. Browser custom headers may trigger CORS preflight. No network adapter or CORS bypass is provided.

## Development

Dart SDK constraint: `^3.13.3`, matching the initially tested local SDK. Older SDKs and Flutter/platform support are not claimed. Development dependencies only: `test` and `lints`. The private workspace lockfile records resolved versions. The package is marked `publish_to: none` until explicit publication approval and release gates are resolved.

From the repository root, run `dart pub get`, `dart format --output=none --set-exit-if-changed packages` and `dart analyze --fatal-infos`. Run `dart test` and `dart test --platform chrome` **from this package directory** so browser test assets resolve correctly. Browser tests require Chrome and local loopback access. In restricted environments with cached dependencies, use `dart pub get --offline`.

MIT, copyright 2026 Ydesignz. Independent community tribute; no official Discworld or Terry Pratchett estate affiliation.

## Quick start

The suite is unpublished. Resolve the checked-out workspace with `flutter pub get`; do not assume a hosted package can be installed yet. The self-contained [public example](example/gnu_clacks_core_example.dart) is compiled and checked with the package source. It uses fictional content and makes no automatic external request.

Read the [security model](doc/SECURITY_MODEL.md), [protocol](doc/PROTOCOL.md), [migration policy](doc/MIGRATION.md) and [platform limits](doc/PLATFORM_MATRIX.md) before integration. Production use and publication still require the recorded release gates.

<!-- EXAMPLE_BEGIN -->
```dart
import 'package:gnu_clacks_core/gnu_clacks_core.dart';

/// A pure policy demonstration. No transport, I/O or real memorials are involved.
void main() {
  final registry = MemorialRegistry([
    Memorial(
      id: 'fictional-alex',
      displayName: 'Alex Example',
      displayEnabled: true,
      networkApproved: true,
      networkName: 'Alex Example',
    ),
    Memorial(
      id: 'fictional-sam',
      displayName: 'Sam Example',
      displayEnabled: true,
    ),
  ]);
  final policy = HeaderPolicy(
    enabled: true,
    allowlistedOrigins: ['https://api.example.org'],
  );
  final decision = policy.evaluate(
    requestUrl: 'https://api.example.org/path',
    registry: registry,
  );
  // A URL/allowlist alone does not prove redirect safety. Adapters own that gate.
  if (decision.value != null ||
      !decision.diagnostics.contains(
        HeaderDiagnostic.unverifiedRedirectSafety,
      )) {
    throw StateError('Unverified transport must not generate a header.');
  }
}
```
<!-- EXAMPLE_END -->
