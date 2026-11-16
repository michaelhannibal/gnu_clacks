# GNU Clacks example

An offline-first demonstration using three fictional memorials, original local river/lantern illustrations, bundled Roboto typography and original tower application icons. No real memorial permissions or identities are implied. MIT, copyright 2026 Ydesignz; font notices are retained separately.

## Run locally

From the repository root, resolve the workspace with `flutter pub get`. From this directory, use `flutter run -d linux` or `flutter run -d chrome`. The default configuration makes no requests and starts with symbolic motion off. Appearance controls and the three modes change presentation/configuration only; they never edit memorial content or approval flags.

- Visual-only: opens the packaged gallery/detail UI and compact signature; no network action is shown.
- Header-only: shows the explicit local test controls without a memorial gallery. A plain-Dart entry point is also available below.
- Full tribute: combines the local tribute UI with the same deliberate test controls.

All approval, formatting, byte-limit and origin policy comes from Core. Only Alex Example is developer-approved for transmission. The example adds a local-only destination restriction to prevent accidental public demonstration traffic. It is not the source of package business rules.

## Optional network test

No endpoint is configured by default. To enable the buttons, build/run with `--dart-define=GNU_CLACKS_TEST_ORIGIN=https://localhost:8443` (or canonical 127.0.0.1 with an explicit port). Only HTTPS localhost/127.0.0.1 origins are accepted. Remote origins, non-HTTPS endpoints, credentials and non-origin URLs are rejected before client creation. The request is GET `/echo`; the fixture returns JSON with a nullable `receivedHeader` string.

Start the optional fixture separately from the repository root with `dart run tool/local_echo.dart 8443`. It binds IPv4 loopback only, logs no header values and forwards nothing. Its default certificate/key are public self-signed **test data**, so a normal app/browser will reject them unless its existing trust configuration accepts that certificate. Automated native tests explicitly trust the test certificate; production/demo code never disables verification or silently adds trust.

For a manual successful test, use an HTTPS localhost endpoint already trusted by the target environment. The fixture can use developer-supplied certificate/key paths through `GNU_CLACKS_FIXTURE_CERT` and `GNU_CLACKS_FIXTURE_KEY`. No certificate installation or trust-store changes are performed by this project. Do not deploy the bundled test key.

Pressing HTTP/Dio sends one request; there are no automatic retries. The header switch starts off and affects only the host policy's enabled flag. The example host deliberately chooses `followRedirects=false` for this test. Native adapters can then attach eligible names; browser adapters still omit generated headers. The app displays the fixture's observed value, not a prediction that transmission succeeded. TLS/CORS/errors remain errors. The fixture permits CORS only for local page origins.

The same native integration can be exercised without a Flutter UI using `dart run bin/header_only.dart --origin=https://localhost:8443 --enable-header`; add `--dio` for Dio. `--help` performs no request. It uses normal certificate validation and has the same local-only restriction. The plain-Dart entry point imports no Flutter library.

Android 127.0.0.1 refers to the device, not the development host. No forwarding or device installation is performed automatically; a developer who separately chooses device testing must explicitly arrange the local endpoint and trust configuration. Android runtime testing was declined for this handoff, so validation remains build-only.

## Deployment differences

- Web: build with `flutter build web --no-pub --no-web-resources-cdn --no-wasm-dry-run`. Renderer resources and fonts stay on the serving origin. The custom bootstrap selects local `canvaskit/`. Serve the generated directory over HTTP/HTTPS; direct file URLs are not the deployment model. No PWA cache/service worker is introduced: a disconnected cold browser load still depends on the host's static-asset caching/availability. Once required assets are available, no external service is needed. Browser adapters do not generate tribute headers.
- Linux: `flutter build linux --no-pub` produces the local release bundle. The binary has received a short launch smoke check, not a full desktop/screen-reader audit.
- Android: `flutter build apk --debug --no-pub` builds the debug APK. No install/launch was performed on the connected device. Debug artifacts and template debug signing are for local validation, not release publication. The example declares Internet permission for explicit tests; libraries declare no app permissions.
- iOS/macOS: runner scaffolds are supplied but require a macOS/Xcode host for validation. macOS network-client entitlements support explicit tests, not background calls. No insecure ATS exception is added.
- Windows: runner scaffold is supplied; validation requires Windows tooling. A generated scaffold is not evidence of support.

See [platform evidence](../../docs/PLATFORM_MATRIX.md) before making platform claims.

## Tests and review

Run `flutter test --no-pub` here for widget/golden/local HTTPS/performance-smoke tests. Use `flutter test --no-pub --platform chrome test/web_test.dart` for browser composition. Tests require local sockets. Goldens explicitly decode bundled illustrations and load local fonts before comparison; review changes rather than automatically accepting new baselines.

The example has no backend requirement, telemetry, persisted user settings, accounts or consumer memorial-editing flows. Privacy/attribution is accessible inside the app. See [Phase 4 validation](../../docs/VALIDATION.md) and the [dependency/privacy audit](../../docs/PHASE4_AUDIT.md).
