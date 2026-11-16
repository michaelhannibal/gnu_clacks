# Phase 4 dependency, privacy and performance review

Review date: 16 November 2026. Scope: package source, example wiring, platform configuration, resolved hosted dependencies and exercised local behaviour. This is an engineering review, not a guarantee of absence of vulnerabilities or a complete release security audit.

## Dependency evidence

The workspace resolves offline from the existing cache. Runtime boundaries remain:

- Core: no runtime dependencies or I/O imports.
- Flutter UI: Flutter and Core; no HTTP/Dio import or remote image/font loader.
- HTTP adapter: Core and pinned http 1.6.0.
- Dio adapter: Core and pinned Dio 5.11.1 (resolved dio_web_adapter 2.2.2).
- Example: the four local packages, Flutter, HTTP/Dio and cupertino_icons 1.0.9 for framework-referenced platform navigation glyphs. The icon package adds assets, not a network client.

A live public-advisory query checked all **62 resolved hosted packages**, including development dependencies, against pub.dev's advisory endpoint. All returned data; no advisory's affected-version list matched the selected version. The complete dated result is [DEPENDENCY_AUDIT.json](DEPENDENCY_AUDIT.json). The check follows the public package server's [advisory API](https://github.com/dart-lang/pub/blob/main/doc/repository-spec-v2.md#list-security-advisories-for-a-package); it covers known server-listed advisories, not undisclosed issues, arbitrary dependency code, SDK/native engine/OS vulnerabilities or future updates.

Reproduce the inventory with `dart pub deps --json` into a local JSON file, then run `python3 tool/dependency_audit.py --inventory <file>`. Only public hosted package names are queried; project/root/SDK entries are excluded. Network failure must remain unverified rather than being interpreted as a clean result. Dependencies were not upgraded merely because newer versions exist. SDK and release dependency/security review remain release gates.

Roboto font files and their original Apache 2.0 licence are bundled locally in the example. The licence is registered for the in-app licence page. Original river, lantern and tower icons are MIT project artwork; no stock photograph, copyrighted Discworld asset or estate affiliation is included. Flutter/platform template code and normal framework notices remain part of their existing tooling conventions.

## Privacy review

- Startup is visual-only with symbolic motion and header transmission off. No endpoint exists in the default build; client factories are lazy and no request is triggered by app creation, theme changes, mode selection or navigation.
- Memorial definitions remain developer-owned and immutable. All three names/dates/dedications are fictional. Only Alex Example is independently network-approved; display does not imply transmission.
- The example's optional destination must be an explicit HTTPS localhost/127.0.0.1 origin. Remote origins, HTTP, userinfo and URL paths in origin configuration are rejected before client creation. This is an extra demonstration restriction, not a duplicated replacement for Core's protocol policy.
- Every request requires an explicit test button or CLI invocation. The example host chooses no-follow requests. Adapters never change redirect settings, retry automatically, inspect credentials/bodies or install global interception.
- No app TLS bypass or automatic trust-store modification exists. Automated tests explicitly trust the public self-signed fixture certificate; the manually runnable fixture can use a developer's own already-trusted localhost certificate/key.
- No accounts, consumer memorial editing, telemetry, persistence, tracking SDK, discovery or background pings were added. Test output and fixture logs do not log arbitrary request headers or real identities. The UI deliberately displays only the fictional fixture's echoed header when requested.
- Original illustrations and fonts are bundled. The web bootstrap uses local CanvasKit resources. A fresh browser profile rendered the built home screen with external DNS blocked; no external service was needed for that view. Web cold-offline asset availability is a host caching/deployment responsibility, with no added service worker.
- Android Internet permission and macOS client-network entitlements belong to the combined example, enabling deliberate tests. They do not add permissions to library consumers or cause requests. Default debug runner/service entitlements are development tooling, not a product backend.
- Connected Android-device deployment was explicitly declined. No install, launch, port forwarding or device trust change was performed.

## Performance smoke scope

Core's local benchmark measures 100 fictional entries over 20,000 decisions after 1,000 warm-ups, checks deterministic bounded output and compares enabled/disabled policy paths. It prints aggregate timings only; it performs no I/O beyond stdout and no network call. The example layout smoke measures five test-harness layouts and checks zero idle transient callbacks. These are warm/JIT/harness measurements, not cold-start, FPS, battery, memory or real-device guarantees. See `VALIDATION.md` for the measured observations.

Hidden/reduced-motion/lifecycle animation scheduling is covered by the UI suite. The gallery remains an eager Wrap; large-registry virtualisation and real-device cold-start/renderer profiling remain unverified. There is no material-cold-start claim based on these smoke tests.

## Follow-up

Complete real assistive-technology/device checks (including the Linux ATK warning), cross-host builds, release signing and current dependency/SDK security review before publication. Package-name availability and multi-name interoperability remain unverified. No publication, remote repository, CI workflow or domain registration occurred.
