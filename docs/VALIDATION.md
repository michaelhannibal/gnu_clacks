# Phase 1 validation — 16 November 2026

Phase 0 rules were accepted and closed by explicit human instruction. At the Phase 1 milestone, the private Pub workspace contained one pure-Dart Core package, with no UI, network adapters, CI or publication. Phase 2 evidence is recorded below.

## Environment and commands

Executed with Dart 3.13.3 stable on Linux x64 using the existing SDK at `/home/michael/Flutter/flutter/bin/cache/dart-sdk/bin/dart`. This avoids the Flutter/Dart launcher attempting to update a read-only SDK cache. No SDK installation or upgrade was performed. The initial SDK constraint is `^3.13.3`; lower SDKs and additional platforms are not claimed.

Development dependencies were resolved successfully with `dart pub get --offline`, using a temporary Pub cache whose hosted entries reference the existing local cache. No new package download was needed. The workspace lockfile records the resolved development dependencies; Core has no runtime dependencies. Neither package-name availability nor release dependency/security review is established by this resolution.

| Check | Working directory | Result |
|---|---|---|
| `dart pub get --offline` | Repository root | Passed using local cache |
| `dart format --output=none --set-exit-if-changed packages` | Repository root | Passed |
| `dart analyze --fatal-infos` | Repository root | Passed, no issues |
| `dart test --reporter failures-only` | Core package | 69 tests passed on Dart VM |
| `dart test --platform chrome --reporter failures-only` | Core package | 69 tests passed in Chrome with dart2js |

Browser execution used `/opt/google/chrome/chrome` with configuration/cache directories under `/tmp`. The sandbox initially blocked the runner's loopback server; browser execution required an approved command escalation. Browser tests launched from the workspace root then failed loading relative runner scripts with MIME errors. Running from `packages/gnu_clacks_core` resolved that path problem without disabling browser security. Use the package directory for browser execution.

An initial VM test failed because its test helper reused an injected alias as a required ID; the fixture was corrected to use a valid separate ID. Validation was rerun after corrections. These failures are not reported as passing runs.

## Acceptance coverage

- Immutable snapshots, unique trimmed IDs, required-text validation, partial-date precision/leap-day checks and local-only asset-reference syntax.
- Display and network eligibility independently default off; missing/invalid aliases do not become display names on the wire.
- Locale-independent ordering (including Unicode scalar ordering for display), explicit ordinals, case-sensitive alias deduplication and stable output under reversed input order.
- Project-specific multi-name format, prefix/separator byte accounting, whole-name omission, continuation after oversized entries and every budget from 1 through 1024.
- All C0 controls, DEL and non-ASCII byte values rejected before alias whitespace normalisation; unsupported punctuation and non-Latin aliases rejected.
- Exact HTTPS origin matching, effective ports, case normalisation, valid IPv4/punycode, subdomain/suffix attacks, userinfo, encoded/Unicode hosts, unsupported IPv6, malformed ports and ambiguous numeric hosts (including bare hexadecimal prefixes). Allowlist path checks examine raw suffixes before URI dot-segment normalisation.
- Invalid policy configuration fails closed, including a mixed valid/invalid allowlist; policies and caller collections remain independent.
- Case-insensitive existing-field detection suppresses generation without inspecting or mutating values; repeated application does not append another field.
- Unknown redirect safety suppresses initial generation; pure recomputation across simulated same-origin, approved cross-origin, unapproved cross-origin and downgrade destinations.
- Diagnostics contain fixed codes only and are immutable. Header values themselves contain memorial aliases and must not be logged.

## Limits and carry-forward evidence

Core is pure decision logic. Redirect tests simulate policy inputs; they do not follow HTTP redirects or prove transport safety. Existing-header tests establish the Core decision contract, not an adapter's request-preservation implementation. No sockets or external services are used by production Core.

Runtime redirect proofs, CORS/preflight behaviour, retries, body replay, cancellation, timeouts and concrete http/Dio version support belong to Phase 2. Default Dio browser transmission remains disabled under the approved policy. Multi-name interoperability remains explicitly unverified.

Flutter UI, platform builds, accessibility and asset rendering are later phases. Asset rights/existence are host responsibilities; Core checks syntax only. No publication, remote repository creation, domain registration or Git initialisation was performed. Git status was unavailable because this directory did not expose a Git repository.

# Phase 2 validation — 16 November 2026

Phase 2 was authorised by the human's instruction to move to the next step. Both optional integrations are implemented for review; Flutter UI and later phases remain unauthorised. Dart 3.13.3/Linux x64 and Chrome/dart2js were used, with the same direct SDK invocation, temporary cached Pub configuration and browser executable described above.

## Executed checks

Offline Pub resolution succeeded for pinned http 1.6.0, Dio 5.11.1 and resolved dio_web_adapter 2.2.2, using the existing package cache. Production Core still has no runtime dependencies. Tests require loopback binding and ran with approved command escalation, without disabling browser certificate validation.

| Check | Result |
|---|---|
| `dart pub get --offline` from root | Passed |
| `dart format --output=none --set-exit-if-changed packages tool` | Passed |
| `dart analyze --fatal-infos` from root | Passed, no issues |
| Core `dart test --reporter failures-only` | 69 VM tests passed |
| Core `dart test --platform chrome --reporter failures-only` | 69 Chrome tests passed |
| HTTP `dart test --reporter failures-only` | 24 VM tests passed |
| HTTP `dart test --platform chrome --reporter failures-only` | 3 Chrome tests passed |
| Dio `dart test --reporter failures-only` | 26 VM tests passed |
| Dio `dart test --platform chrome --reporter failures-only` | 3 Chrome tests passed |

Run each test command from its own package directory. VM suites include native and portable pass-through tests; browser suites include a real Fetch/XHR hybrid test and portable pass-through tests. Browser fixtures explicitly distinguish package-generated values (disabled) from host-supplied values used to exercise preflight.

## Acceptance evidence

- Local HTTPS server observations verify generated native values contain only approved aliases, on the exact approved origin/port, and require host-selected no-follow behaviour.
- All 301/302/303/307/308 status codes are exercised both with normal automatic redirects (no generated header on initial/final requests) and host-disabled redirects (initial header, no follow). Additional tests cover relative same-origin redirects, cross-port destinations, HTTPS-to-HTTP downgrade and HTTP-to-HTTPS redirect chains.
- Manual new requests are re-evaluated. Headers do not stack across repeated installation/wrapping or caller-selected retries. Host header casing/values, credentials and cookies are retained. Unknown transports and subclasses fail closed.
- Multipart fields/files/boundaries/byte lengths, streamed bodies, response content/status, upload progress, caller cancellation, receive timeouts and close semantics are exercised against real loopback transports. No adapter consumes or retries bodies itself.
- Dio late interceptor URL/redirect changes are checked at final dispatch. Native transport timeout errors retain no generated header; retrying their request options against an unapproved destination does not leak a stale value. Raw encoded authorities are rejected before URI normalisation can approve them.
- Real Chrome Fetch/XHR tests exercise cross-port redirects, ordinary CORS rejection, successful OPTIONS preflight for a host-supplied field, and denied preflight. A denied preflight produces one OPTIONS and no actual request; ordinary CORS failure is not retried. No generated alias is transmitted by browser integrations.
- Custom transport tests verify options/streams/cancellation futures and response/error objects are delegated unchanged. Native forwarding snapshots and Dio private options copies keep generated values out of reusable host data and remove them from error/response metadata after dispatch.

An initial portable HTTP test incorrectly expected body assignment not to add the upstream content-type header. Its baseline assertion was corrected to compare with the request's actual pre-send headers, then rerun on VM and Chrome. No production behaviour was changed to satisfy that fixture.

## Remaining limits

See `HTTP_INTEGRATIONS.md` for exact support boundaries. Browser CORS fixtures use HTTP loopback endpoints; they do not prove generated HTTPS browser transmission, which remains disabled. Native no-follow proofs rely on standard Dart HttpClient semantics and the exact pinned upstream transport implementations; arbitrary replacement low-level clients are outside support.

No automatic header-bearing redirect/replay mechanism, new timeout budget, hidden retry or strict mode was added. Other dependency versions, native OS/Flutter builds, package-name availability, publish dry-runs and release security review remain unverified. UI and platform matrix work remain later phases.

# Phase 3 validation — 16 November 2026

Phase 3 was explicitly authorised with “phase 3 please”. The Flutter package is implemented for visual/accessibility review, with no changes to production Core or transport policy. Example-app and multi-platform build work remain Phase 4.

## Toolchain and dependency resolution

The existing Flutter tools report stable Flutter 3.47.4 and Dart 3.13.3. The installed SDK is read-only, so commands used its existing Dart executable and flutter_tools.snapshot with `FLUTTER_ROOT=/tmp/gnu-clacks-flutter`. That temporary tool root copies writable cache metadata while referencing the existing SDK packages/artifacts; the installed SDK was not edited or upgraded. `PUB_CACHE=/tmp/gnu-clacks-pub-cache` continued to reference the existing hosted cache. Flutter commands used `--no-version-check --suppress-analytics` and dependency resolution used `pub get --offline`.

Adding the Flutter SDK dependency changed the shared development resolution: for example test 1.31.1, analyzer 13.3.0 and package_config 2.2.0 now satisfy Flutter's pinned test SDK constraints. HTTP 1.6.0 and Dio 5.11.1 remain pinned. Core and adapter regressions were rerun against this lockfile. The UI has only Flutter and Core runtime dependencies; Core still imports no Flutter or I/O.

## Executed checks

| Command/check | Result |
|---|---|
| Flutter `pub get --offline` from workspace | Passed using cached dependencies |
| `dart format --output=none --set-exit-if-changed packages tool` | Passed |
| `dart analyze --fatal-infos` | Passed, no issues |
| Flutter `test --no-pub --reporter failures-only` from UI package | 24 engine tests passed, including 3 golden comparisons |
| Flutter `test --no-pub --platform chrome test/web_smoke_test.dart --reporter failures-only` | 2 browser smoke tests passed |
| Core tests on Dart VM / Chrome | 69 / 69 passed |
| HTTP tests on Dart VM / Chrome | 24 / 3 passed |
| Dio tests on Dart VM / Chrome | 26 / 3 passed |

Flutter tests and browser runs needed approved local-socket access. Existing Core/adapter commands used the new FLUTTER_ROOT environment while preserving their previous package working directories. These are engine/Chrome test results, not claims of native application builds on every target OS.

## UI evidence

- Gallery filtering and navigation/back; hidden/missing direct detail protection; independently guarded cards, badges and portraits; no display of transmission aliases or approval flags.
- Width-dependent one/two/three-column layouts, a host display comparator, long names/dedications, 2.5× text scaling and RTL without reported layout exceptions.
- Tab/Enter activation and visible focus outline; merged card semantics include name/dedication; decorative towers are excluded. Flutter's labelled-target, Android target-size and text-contrast guideline checks pass in the exercised cases.
- Local AssetImage failure fallback and a synthetic local portrait decode with supplied alt semantics. Offline creator/source/licence/notice/modification display, credits callback and static explanation dialog.
- All five appearance presets, low-contrast colour fallback, host localisation delegate and precision-preserving partial dates.
- Explicit static mode and reduced motion schedule no ticking frames. Pause/resume, viewport scrolling, Offstage, TickerMode and app inactivity/resumption exercise the signal's stop/resume behaviour. The lifecycle regression exposed a missing resumption frame; scheduling one on resume fixed it, and inactive states synchronously stop the controller.
- The network guard test pumps gallery/detail with an HTTP-client creation override and observes zero clients. No production portrait/font loader, HTTP/Dio import or network hook exists in the UI package.
- Chrome smoke tests compile and render gallery/detail, enforce display filtering, activate the host navigation callback and retain static content under reduced motion.

## Visual review

Three PNG baselines were generated, opened and visually inspected by the coding agent, then checked in a fresh non-update golden run:

- `packages/gnu_clacks_flutter/test/goldens/gallery_classic_desktop.png` — 1200×900, three-column classic gallery.
- `packages/gnu_clacks_flutter/test/goldens/gallery_light_phone.png` — 390×900, light phone gallery.
- `packages/gnu_clacks_flutter/test/goldens/detail_classic.png` — 800×1100, static classic detail.

The golden harness loads Roboto and MaterialIcons from the installed Flutter SDK, preserving its fonts/notices there and avoiding machine-default typography. Initial snapshots exposed an unloaded icon font and a debug banner in the harness; both were corrected before accepting baselines. Production widgets do not load these test fonts at runtime. Standard Material navigation/control assets remain supplied by Flutter.

Initial test runs also caught compile-time API/promotion issues, test semantics-handle disposal, an attempt to settle a deliberately continuous animation and a scroll test's own overscroll activity. Those were corrected; only the final executed checks above are reported as passing. No test success is inferred from static inspection alone.

## Remaining review and limitations

Human visual/accessibility sign-off, real screen-reader testing, real-device performance, large-registry profiling and the platform build matrix remain outstanding. The gallery eagerly builds its configured cards; it does not claim large-list virtualisation. For unusual retained/hidden render trees and non-rectangular clipping, hosts must provide `ClacksSignal.active=false` as documented in `FLUTTER_UI.md`.

No example app, OS project scaffolds, CI, domain registration, remote repository or publication was created. Package-name availability and multi-name interoperability remain unverified. Git status remains unavailable because this directory does not expose a Git repository.

# Phase 4 validation — 16 November 2026

The human explicitly authorised Phase 4. The example, local test tools, available-host build matrix and audit evidence are implemented for review. CI/release work remains Phase 5. The user explicitly chose Android **build-only** validation; no APK was installed or launched on the connected device.

## Toolchain and build evidence

The existing Flutter 3.47.4/Dart 3.13.3 SDK and temporary tool cache were retained. Android used installed SDK 37.0.0, JDK 21.0.13 and Gradle 9.3.1. Linux used clang 22.1.8, CMake 4.3.0, Ninja 1.13.2 and GTK 3.24.52. Chrome was 156.0.8078.47. Offline Pub resolution added only the cached Cupertino icon asset package to the example; package transport versions stayed pinned.

| Check | Result |
|---|---|
| `flutter build web --no-pub --no-web-resources-cdn --no-wasm-dry-run` | Passed, release web bundle |
| `flutter build linux --no-pub` | Passed, Linux x64 release bundle |
| `flutter build apk --debug --no-pub` | Passed, debug APK; no device deployment |
| Built Linux process via `timeout 8s` | Renderer initialised and process remained alive until intended termination (124); ATK/cursor warnings retained |
| Built web bundle via `tool/web_bundle_smoke.py` | Rendered in a fresh headless browser profile with external DNS blocked; screenshot inspected |
| iOS / macOS / Windows builds | Not run on this Linux host; scaffolds only, no support claim |

The final web/Linux/Android builds were rerun after the image-loading correction. Build artifacts remain local under the example's ignored build directories. Initial sandboxed doctor/device checks failed at ADB socket creation; an authorised read-only inventory later worked. Device details are deliberately not copied into documentation. The user then declined installation/runtime testing. No device forwarding or certificate trust changes occurred.

Full scope, commands, artifact paths and remaining platform limits are in `PLATFORM_MATRIX.md`.

## Final regression matrix

All tests below were executed using the resolved workspace lockfile, with approved local engine/browser/HTTPS sockets where needed. Test commands ran from their own package/app directory.

| Suite | Native VM / Flutter engine | Chrome |
|---|---:|---:|
| Core | 69 passed | 69 passed |
| HTTP | 24 passed | 3 passed |
| Dio | 26 passed | 3 passed |
| Flutter UI | 24 passed, including 3 golden comparisons | 2 smoke tests passed |
| Example | 12 passed, including 2 golden comparisons and a performance smoke | 1 integration smoke passed |

Example coverage includes default-off/no-endpoint/no-client creation, no idle transient callbacks, all three modes, local gallery/detail assets and attribution, 390-pixel layout, 2.5× text controls, privacy copy, local-only destination rejection and real HTTPS echo via both adapters with enabled/disabled policies. Only the developer-approved fictional alias is observed on opted-in native no-follow requests. The plain-Dart CLI help ran without Flutter UI or a network request.

Existing HTTP/Dio Chrome suites re-exercised real CORS/preflight and redirect behaviour. Browser-generated tribute transmission remains disabled; native no-follow guarantees and host-header preservation remain unchanged.

The standalone `tool/local_echo.dart` fixture was independently started on an ephemeral loopback port, queried over verified TLS with a per-request test certificate context, checked for local-origin CORS permission and absent permission for an external origin, then terminated. Its developer-supplied certificate/key configuration was exercised. No global trust-store modification was used.

## Visual and integration corrections

The example home and gallery goldens were rendered and opened, then checked in a normal non-update test run. The gallery's local river and lantern illustrations are visibly decoded, with the original tower fallback on the third entry. The built web screenshot was also opened and inspected: `docs/images/example_web.png`.

Initial example tests exposed a dropdown overflow and a Material surface problem that could hide switch ink/background feedback. The dropdown now expands within its constraint, and panels provide their own Material surface. A framework-referenced Cupertino font was missing from the first build's asset set; the correctly noticed local icon asset dependency resolved the warning.

Visual review also caught blank loading slots before local asset decoding. `MemorialPortrait` now supplies the original local placeholder until a frame is available, as well as on errors. The synthetic portrait test now uses generated known-valid PNG bytes and explicitly waits for real decode before asserting alt semantics; earlier pre-decode semantics alone were insufficient evidence of actual decoding. Example goldens explicitly precache/decode local illustrations instead of accepting a loading state as the baseline. The UI suite passed after this correction.

## Performance observations

The reproducible Core benchmark is `packages/gnu_clacks_core/benchmark/policy_benchmark.dart`. For 100 fictional entries, after 1,000 warm-ups, 20,000 decisions measured approximately **214.72 microseconds per enabled decision** and **0.485 microseconds per disabled decision**. Model/policy construction in that JIT process measured 9.922 ms. Results were deterministic and bounded by the configured byte budget.

A five-sample, single-file example layout smoke measured a 59.319 ms median and a 554.349 ms maximum, with **zero idle transient callbacks**. Other Core/browser smoke tooling was active; these values are descriptive, not isolated hardware measurements. The broader concurrent regression run showed higher timing variance, as expected under load. Machine-readable observations are in `PERFORMANCE_SMOKE.json`.

These are warm/JIT/test-harness observations, not application cold-start, FPS, battery, memory or real-device guarantees. A claim of no material real-device cold-start impact remains unverified. Hidden/reduced-motion/lifecycle scheduling has automated evidence, but real-device performance remains a release gate.

## Dependency and privacy review

A live advisory query returned data for all **62 resolved hosted dependencies**, including development tools, with no matching server-listed affected version. `DEPENDENCY_AUDIT.json` records the dated results. SDK, engine, native build tools, OS libraries, undisclosed issues and future updates are outside that check. The reproducible audit script reports unknown/failing checks as unverified and exits unsuccessfully for incomplete or matching-advisory results.

The privacy/source review and runtime boundaries are recorded in `PHASE4_AUDIT.md`. The example has no startup client creation, endpoint by default, persisted identity/settings, account flow, telemetry, external content loader or automatic requests. The built web view used same-origin packaged resources with external DNS blocked. No PWA cache was added; disconnected browser cold-load caching remains the host's responsibility.

## Remaining gates

Human visual/accessibility sign-off, native ATK warning investigation, real screen-reader/device checks, real-device cold-start/performance, iOS/macOS/Windows build/runtime evidence and release signing remain unverified. CI, publish dry-runs and publication are not part of this phase. Package-name availability and multi-name interoperability are still unverified. No remote repository, publication or domain registration occurred; this directory still does not expose a Git repository for status/diff reporting.

## Phase 5 — documentation and release inspection, 16 November 2026

No production behaviour changed. Public package examples now compile under workspace analysis. Core's executable example was run without I/O; HTTP and Dio examples were exercised against verified loopback HTTPS, and the Flutter example was pumped as a visual-only app. Native regression suites passed: Core **69**, HTTP **25**, Dio **27**, Flutter **25** including its three golden comparisons. Phase 4 browser/app evidence remains the last execution for those unchanged suites; it was not rerun merely for documentation edits.

Executed `dart format packages apps tool` (48 files, zero changes), `dart analyze --fatal-infos` (no issues), `python3 tool/sync_package_docs.py --check`, and API generation from each package with `dart doc --output /tmp/gnu-clacks-api/<package>`. All four API generations finished with **zero warnings and zero errors**. The generated HTML is a local inspection artifact, not a deployed site.

Both workflow files passed **actionlint 1.7.12**, obtained from the official release with its SHA-256 checksum verified. Local Markdown relative links and synchronised package documentation were checked. This does not imply a successful remote Actions run. Runner/toolchain/platform claims remain bounded by actual Phase 4 evidence.

`tool/stage_release.py` ran with pub.dev access and produced `RELEASE_DRY_RUN.json`. Every package reached archive validation and exited **65** with warnings: missing repository/homepage on all; exact http/Dio pins on their respective adapters. Source guards remained `publish_to: none`; no upload occurred. Archive listings contain licences, READMEs, examples, lib and bundled doc files, excluding repository tests/TLS keys. Workspace-local Core resolution is not evidence of published dependency availability. Wider transport constraints were not adopted without tests.

Public registry/name and action-pin lookups are in `RELEASE_LOOKUPS.json`. No name was registered and no ownership is claimed. The initial inspection lacked repository/homepage and security contact details; the follow-up below records the supplied homepage and reporting route. See `RELEASE.md` for unresolved human, device/platform, performance and maintenance gates. The final phase prepares reviewable release materials; its 1.0 release-ready exit criterion has not been met.


### Supplied homepage and security contact

The human supplied `ydesignz.co.za` and `apps@ydesignz.co.za`. All four package manifests now declare `homepage: https://ydesignz.co.za`; SECURITY.md, the security model, README and bundled package docs record the private reporting email. The actual source repository URL remains unconfigured. No email was sent; mailbox delivery/monitoring is unverified.

Refreshed staged dry-runs in RELEASE_DRY_RUN.json: **Core and Flutter exit 0**, with no package validation warnings; **HTTP and Dio exit 65**, each retaining the intentional exact transport-version warning. Homepage metadata warnings are resolved. Package-doc synchronisation, local relative links, homepage fields and source publication guards were checked. No production code changed, so runtime suites were not repeated. No publication occurred.

## Umbrella and release tooling — 16 November 2026

Added the user-requested `gnu_clacks` umbrella, synchronised all five manifests
and the private example to `0.1.0`, and added `tool/release.py`. Source Core's
existing commented publication guard was preserved. Other guards remain active.
Executed offline workspace resolution, Dart analysis with fatal infos (no issues),
format verification of the three new Dart files (no changes), package-doc sync
check, Python compilation and five Python orchestration tests. Mocked publication
tests cover independent copies, order, failure stopping, resume, version validation
and source guard preservation; they make no registry calls. The umbrella Flutter
widget/API smoke test passed after allowing its local test-runner socket. Initial
sandbox execution could not open that socket. Dart analysis was rerun with
`--suppress-analytics` after its default analytics bookkeeping hit a read-only path.
No new registry dry-run, upload, platform build or device launch was performed;
existing dry-run JSON remains historical evidence. Existing component implementation
and privacy policy are unchanged. Final-candidate release checks remain required.
