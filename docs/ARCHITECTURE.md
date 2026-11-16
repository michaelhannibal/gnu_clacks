# GNU Clacks — Architecture and domain specification

**Status:** Phase 0 approved; Core, optional HTTP/Dio integrations, Flutter UI and example implemented for Phase 4 review. Platform claims are limited to `PLATFORM_MATRIX.md`.

## System context and rationale

GNU Clacks is a collection of Dart/Flutter packages embedded into a host app. The host developer owns the memorial content, permissions and HTTP client configuration. The project has no hosted service or central database. The package is not an OS-level plugin; it can be built with regular Dart and Flutter modules. No application-wide network hook is permitted.

## Component dependency graph

```text
                        Host Flutter App
                    /       |         \
               Gallery    HTTP client    Dio client
                  |           |             |
         gnu_clacks_flutter   |             |
                  |    gnu_clacks_http   gnu_clacks_dio
                  |           |             |
                  +----- gnu_clacks_core ---+
                             |
              local, developer-owned memorial registry
```

**Dependency rule:** Core never imports Flutter, `http`, Dio, platform channels, file I/O or a hosting client. Adapters do not import UI. The example app is the repository's combined consumer; host applications may also combine the packages.

## Proposed repository

```text
gnu_clacks/
  README.md
  AGENTS.md
  LICENSE                    [MIT, Ydesignz]
  CHANGELOG.md               [unreleased]
  packages/
    gnu_clacks_core/         [Phase 1]
    gnu_clacks_flutter/      [Phase 3]
    gnu_clacks_http/         [Phase 2]
    gnu_clacks_dio/          [Phase 2]
  apps/
    gnu_clacks_example/      [Phase 4]
  docs/
    ARCHITECTURE.md
    PROTOCOL.md
    UX_SPEC.md
    DEVELOPMENT_PLAN.md
    DECISIONS.md
    VALIDATION.md
    HTTP_INTEGRATIONS.md
    FLUTTER_UI.md
    PLATFORM_MATRIX.md
    PHASE4_AUDIT.md
    DEPENDENCY_AUDIT.json
  .github/                   [planned]
```

## Domain model (conceptual)

### Memorial

- `id`: stable, unique developer-defined identifier; never placed in outgoing headers.
- `displayName`: Unicode, nonempty, trimmed, can include diacritics and non-Latin scripts.
- `networkName`: separate ASCII-safe name/alias for optional HTTP use; never auto-transliterate identities.
- `dedication`: optional plain-text original text; UI only.
- `birthDate` / `deathDate`: optional partial dates; preserve uncertainty and avoid forcing complete dates.
- `imageAsset`: optional packaged local asset reference; image permissions remain developer's responsibility.
- `imageAltText`: text description where a meaningful image exists.
- `displayEnabled`: whether shown in UI.
- `networkApproved`: separate opt-in to send `networkName`.
- `sortOrder`: stable ordinal selected by developer; otherwise name/id fallback.

### Registry

- Immutable snapshot of zero or more memorial entries.
- Validates IDs, safe fields and duplicate IDs. Core validates asset-reference syntax only; asset existence and decoding checks belong to Flutter or host tooling, without Core file I/O.
- Provides filtered lists for UI and header composition.
- Never fetches, mutates, uploads or persists memorials without host app code.

### HeaderPolicy

- `enabled`: explicit opt-in; defaults false.
- `allowlistedOrigins`: exact HTTPS origins; defaults empty.
- `maxHeaderValueBytes`: default 512, hard cap 1024; accepted budget rules are in `PROTOCOL.md`. These are project limits, not HTTP guarantees.
- `includeNames`: approved names only, deterministic order; strict encoding and deduplication.
- `redirectPolicy`: drop on unapproved redirect origin, recompute on approved origin.
- Existing header rule: preserve host values without merging, replacing or duplicating them. Approval guarantees cover package-generated values only; diagnostics contain no names or header values.

### PresentationConfiguration

- Theme tokens (colours, typography, spacing, radii, light/dark); screen/card/compact variants; animation enablement; reduced-motion precedence; localisation and semantics labels.

## Use cases

1. **Visual-only:** registry + UI; no HTTP dependency; no sending.
2. **Header-only:** core + adapter; explicitly approved names and destinations; no Flutter UI.
3. **Full tribute:** registry + gallery/detail/semaphore + one or both adapters.
4. **Offline:** all views use packaged assets, with no external content service. Native assets are bundled; web hosting/cold-offline caching remains the host's responsibility as documented in the example guide.
5. **Server participation (external):** cooperating backend independently chooses whether to add/forward response headers. Flutter clients cannot compel propagation.

## Event and data flows

### Display

Host supplies immutable registry → Flutter filters `displayEnabled` → responsive gallery → memorial detail screen → optional Clacks relay of the display name. Direct detail access and compact widgets also enforce display eligibility. No analytics, persistent storage or background activity.

### Request

Host issues request through opted-in adapter → normalise target origin → check enabled and explicit allowlist → select `networkApproved` entries → validate and bound ASCII wire names → compose `X-Clacks-Overhead` → send request. If ineligible, pass request unchanged. Adapter must not inspect bodies or credentials.

### Redirect

On redirect, resolve redirect URI, recompute origin and enforce the same policy **before** forwarding. If the chosen client cannot guarantee per-hop enforcement, omit the package-generated header from the initial request and preserve normal client behaviour. Do not silently disable automatic redirects or introduce a strict mode. A future controlled redirect mechanism requires separate review and proof that request semantics are preserved. No leakage to newly encountered origins.

## Runtime and platform boundaries

- Pure Dart functions should work on VM and web without importing `dart:io`.
- Flutter UI uses portable widgets and bundled assets; no platform-specific channel is anticipated.
- HTTP libraries may differ in redirect behaviour on web vs VM. Record proven guarantees per adapter and runtime before claiming support.
- Browser CORS: the `X-Clacks-Overhead` custom request header can trigger preflight; server must authorise the header/origin; CORS failures propagate normally without bypasses or hidden retries. Developers can disable transmission per destination; adding the header can make previously working requests fail.
- Distinguish HTTP **request** headers from response headers. Some reverse proxies may strip unknown headers; no guarantee of delivery.

## Public API (Core, integrations and Flutter UI implemented)

- Immutable registry constructor/factory from developer-owned definitions.
- `HeaderPolicy` object; explicit opt-in and immutable host allowlist.
- Pure `HeaderPolicy.evaluate` method accepts a raw request URL, registry, existing field names and a default-false transport safety assertion, returning a nullable generated value and fixed diagnostic codes without names.
- Opt-in `ClacksClient` wrapping an explicit `http.Client`, and `ClacksDioInterceptor.install` installing a per-Dio interceptor plus private final transport guard. The guard evaluates after host interceptors/transforms; see `HTTP_INTEGRATIONS.md`.
- `MemorialGallery`, `MemorialDetailScreen`, `MemorialCard`, `MemorialBadge`, `MemorialPortrait` and `ClacksSignal` implement the tribute surfaces. Full screens accept registry/ID or gallery callbacks; composable content widgets independently enforce display eligibility. `ClacksTheme` and `ClacksLocalizations` provide host configuration. See `FLUTTER_UI.md`.
- API consumers can supply their own UI instead of using package widgets.

## Non-functional goals

- No startup network requests or background timers when memorial UI is not visible.
- Responsive design: narrow phones through large desktop widths.
- Performance: avoid repeated decoding of local assets, allocate animations only while visible, deterministic and cheap request policy checks.
- Reliability: errors in optional header generation never turn otherwise valid requests into failed requests; invalid config is surfaced clearly during development and fails closed for transmission.
- Security: reject control characters and header injection; never append unrelated secrets or personal data.
- Maintainability: public API semver, clear package boundaries, dependency constraints and CI coverage.

## Out of scope for v1

End-user creation and cloud sync, public memorial directory, accounts, searchable global network, server middleware, central analytics, automatic interception of all application traffic, geo-location, comments, donations, ads, user profiles, animated audio, text-to-speech, native OS APIs.

## Long-term portability

Publish a small independent wire/protocol specification and equivalent test vectors. Other ecosystems must reproduce the allowlist, safety rules and wire format; UI is implementation-specific. Avoid Dart-only semantics leaking into the public protocol.

## Umbrella package

`gnu_clacks` depends on and re-exports Core, Flutter, HTTP and Dio. It contains no business rules or network initialisation. Consumers may install it for the full suite or choose standalone packages. The umbrella requires Flutter and both transport dependencies.
