# GNU Clacks — The Living Tribute

> A name continues travelling as long as the signal does.

**Status:** Phases 0–5 authorised; Phase 5 documentation, CI configuration and release inspection prepared for review. **Licence:** MIT, copyright 2026 Ydesignz. **Ecosystem:** Flutter/Dart first, other frameworks later.

GNU Clacks is a proposed open-source family of Dart and Flutter packages that allows application developers to honour people they have lost. It pairs **beautiful in-app memorials** with the established `X-Clacks-Overhead` HTTP tribute convention inspired by Terry Pratchett's *Going Postal*. It does not require an account, hosted backend, tracking or telemetry.

**Core, the optional HTTP/Dio integrations and the Flutter tribute UI are implemented.** The private workspace replaces the original calculator scaffold; the example app and an evidence-based platform matrix are now included. No package is published. Registry lookups returned 404 for the proposed names on 16 November 2026; no availability, ownership or reservation is guaranteed.

## Why GNU?

In the fictional Clacks network, the GNU instruction keeps a name passing along the line. The internet tribute traditionally uses `X-Clacks-Overhead: GNU Terry Pratchett`. GNU Clacks honours that tradition while allowing developers to commemorate other people. This is an independently proposed community tribute, not an official Discworld product or affiliation with the Terry Pratchett estate.

## V1 scope

- Developer-configured memorials, bundled with an application; no user-generated memorial authoring in v1.
- Full responsive memorial gallery, detail cards, customisable themes, graceful image placeholders and an animated, accessible Clacks signal.
- Pure-Dart core for immutable memorial models, validation, safe name selection, header policy and deterministic rendering/serialization.
- Optional adapters for `package:http` and Dio; explicit allowlist of destination origins before **automatic** header attachment.
- Targets Flutter Android, iOS, web, Windows, macOS and Linux; support claims require validation. Transport capabilities may differ by runtime.
- Offline UI, zero required backend, zero required analytics, zero required remote asset fetching.
- MIT licence and conventional contribution and release practices.

## Configuration

1. Set up a registry of memorial entries: unique stable ID, display name, optional lifespan dates, optional dedication, optional local image and attribution.
2. Choose separate display and transmission eligibility for every entry. Public display **does not imply** permission to send a name over the network.
3. Provide a set of explicitly allowed HTTPS origins for transmission. No origin is allowed by default.
4. Wrap the application's chosen HTTP client(s) with GNU Clacks adapters. Other clients remain unaffected.
5. Display a ready-made gallery/detail screen, compact tribute widget or animated Clacks tower where desired.

## Package layout

- `packages/gnu_clacks/` — umbrella re-exporting all four components for a single install.
- `packages/gnu_clacks_core/` — portable Dart data types, validation, privacy selection, formatting, policy engine.
- `packages/gnu_clacks_flutter/` — Flutter screens, animations, theme tokens and accessibility.
- `packages/gnu_clacks_http/` — adapter for `package:http`.
- `packages/gnu_clacks_dio/` — optional Dio interceptor.
- `apps/gnu_clacks_example/` — illustrative and integration-test app.
- `docs/` — architecture, protocol, UI design, roadmap and design decisions.

Core, Flutter, HTTP and Dio exist as source packages. See the [Core guide](packages/gnu_clacks_core/README.md), [HTTP/Dio integration guide](docs/HTTP_INTEGRATIONS.md), [Flutter UI guide](docs/FLUTTER_UI.md) and [validation evidence](docs/VALIDATION.md). See the [example guide](apps/gnu_clacks_example/README.md), [platform evidence](docs/PLATFORM_MATRIX.md) and [built web preview](docs/images/example_web.png).

## Header interoperability

Existing convention: `X-Clacks-Overhead: GNU Terry Pratchett`. For v1, send only header-safe explicitly approved names to approved HTTPS origins; support several names via a deterministic, bounded, project-specific comma-separated format described in `docs/PROTOCOL.md`. Multi-name interoperability is explicitly unverified. The client cannot ensure that another server propagates the header, and `N` does not prohibit servers from logging it. Server-side propagation is an optional later capability.

## Privacy promise

Never silently broadcast a memorial, its image, date, dedication or the user's identity. Header transmission is disabled until **both** the developer has explicitly opted a name into network transmission **and** has approved the destination origin. Adapters omit package-generated headers whenever redirect safety is unproven, preserving normal client behaviour; both browser integrations disable generated transmission. Tested native transmission requires the host to have already disabled automatic redirects for that request; the adapters never change that setting. Existing host headers are preserved without merging and are outside the package-generated-value guarantees. No third-party analytics, background pings, automatic uploads or tracking. The package must never suppress HTTP errors or alter API authentication.

## Visual language

A tasteful memorial, not a game: warm brass/gold on slate for the classic Clacks theme, plus minimal, light, dark and adaptable host-app themes. Avoid visual clutter; always respect reduced-motion and accessibility settings. The detail animation relays `GNU` and the person's name across the towers in a documented nine-lamp code (8-bit ASCII on the outer ring, centre lamp for END only), then an END signal, and respells it as each letter arrives; it is a local display and sends nothing.

## Build and publication

Phase 5 release preparation is authorised; publication requires separate human instruction. See `docs/ARCHITECTURE.md`, `docs/PROTOCOL.md`, `docs/UX_SPEC.md`, `docs/DEVELOPMENT_PLAN.md` and `AGENTS.md`. Before package publication: resolve names, verify MIT licence notices naming Ydesignz as copyright holder and project steward, test every claimed platform, run analysis and tests, and run a `dart pub publish --dry-run` for each release package. No publication has happened.

## Credits and naming

Inspired by Terry Pratchett's *Going Postal* and the community GNU Terry Pratchett/Clacks overhead practice. Terry Pratchett, Discworld and associated marks belong to their respective rights holders. Do not ship copyrighted Discworld artwork, quotes longer than properly licensed excerpts, logos or fictional characters as package assets. The project must include a clear non-affiliation notice. The repository can use original visual designs and original explanatory text.

## Reference material

- https://www.gnuterrypratchett.com/
- https://docs.flutter.dev/packages-and-plugins/developing-packages
- https://dart.dev/tools/pub/publishing
- https://pub.dev/packages/dio

## Contribution and release preparation

See [contributing](CONTRIBUTING.md), [security reporting](SECURITY.md), [security model](docs/SECURITY_MODEL.md), [migration](docs/MIGRATION.md), [CI](docs/CI.md) and [release gates](docs/RELEASE.md). Phase 5 prepares an unpublished development candidate; unavailable platform, human accessibility/performance and remaining release checks still block release. Source publication guards remain enabled.

## Quick start from the workspace

Use Flutter 3.47.4 / Dart 3.13.3, then run `flutter pub get --enforce-lockfile` from this checkout. Start the offline showcase with `cd apps/gnu_clacks_example` followed by `flutter run -d chrome`. It has no default endpoint and makes no tribute request at startup. No public package installation is available yet.

Choose a tested minimal composition: [Core policy](packages/gnu_clacks_core/example/gnu_clacks_core_example.dart), [visual-only Flutter](packages/gnu_clacks_flutter/example/gnu_clacks_flutter_example.dart), [HTTP](packages/gnu_clacks_http/example/gnu_clacks_http_example.dart) or [Dio](packages/gnu_clacks_dio/example/gnu_clacks_dio_example.dart). Each package README embeds that exact source. The transport examples require a caller-supplied client, registry and policy; executing their empty entry points sends nothing. Their no-follow setting is an explicit host choice. Follow [adapter guidance](docs/HTTP_INTEGRATIONS.md) before opting into network transmission.

Project homepage: [ydesignz.co.za](https://ydesignz.co.za). Private security reports: [apps@ydesignz.co.za](mailto:apps@ydesignz.co.za); see [reporting guidance](SECURITY.md).

The `gnu_clacks` umbrella offers one dependency for the complete suite while standalone packages remain available. All five use matching versions. See [release commands](docs/RELEASE.md#umbrella-and-synchronised-release-command) for version updates, inspection and interactive publishing with `tool/release.py`. Creating the tooling has not published any package.

Release tooling now waits for pub.dev propagation. A package-tag GitHub Actions publishing workflow is prepared; follow [configuration instructions](docs/RELEASE.md#registry-waits-and-github-actions-configuration) before enabling automated releases.
