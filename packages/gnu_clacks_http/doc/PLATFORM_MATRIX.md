# Platform evidence — Phase 4, 16 November 2026

The suite targets six Flutter platforms. Evidence below is deliberately narrower than a blanket support claim. Runner scaffolds do not count as validated platforms. Toolchain: Flutter 3.47.4 stable, Dart 3.13.3, Linux x64; Chrome 156.0.8078.47. All builds used the example app and the resolved workspace lockfile.

| Target | Build evidence | Runtime evidence | Remaining limitations |
|---|---|---|---|
| Web | Release build passed with local renderer resources and bundled fonts | Chrome smoke tests, local-only built-bundle screenshot with external DNS blocked, package CORS/preflight tests | No browser-generated tribute headers; browser cold-offline loading depends on host asset caching/availability |
| Linux x64 | Release bundle passed with clang 22.1.8, CMake 4.3.0, Ninja 1.13.2, GTK 3.24.52 | Process launched, renderer initialised, remained alive until planned eight-second termination; engine/widget/golden tests | ATK bridge and cursor-theme warnings observed; no complete native interaction/assistive-technology audit |
| Android | Debug APK passed using installed SDK 37.0.0 / JDK 21.0.13 / Gradle 9.3.1 | Not run: user explicitly chose build-only validation | No install, launch, device forwarding, trust change or release/signing validation |
| iOS | Not run; scaffold only | Not run | Requires macOS/Xcode, signing/simulator/device evidence |
| macOS | Not run; scaffold only | Not run | Requires macOS/Xcode and desktop/network/assistive-technology evidence |
| Windows | Not run; scaffold only | Not run | Requires Windows toolchain and runtime evidence |

## Executed build commands

From `apps/gnu_clacks_example`:

- `flutter build web --no-pub --no-web-resources-cdn --no-wasm-dry-run`
- `flutter build linux --no-pub`
- `flutter build apk --debug --no-pub`

The read-only installed SDK was used through the temporary writable Flutter tool cache described in `VALIDATION.md`. Android used installed SDK/Gradle tooling and caches; no device deployment was authorised. The earlier sandboxed doctor/device check failed because ADB could not bind its local socket. A later authorised read-only device inventory succeeded; the user then explicitly declined installation/runtime testing. No device identifier is recorded here.

Build artifacts are local and ignored by source control:

- `apps/gnu_clacks_example/build/web/`
- `apps/gnu_clacks_example/build/linux/x64/release/bundle/gnu_clacks_example`
- `apps/gnu_clacks_example/build/app/outputs/flutter-apk/app-debug.apk`

The Linux runtime check used `timeout 8s` on the built binary. Exit 124 was the planned termination, not a clean application exit or proof of full UI correctness. GTK emitted an ATK socket-embedding assertion and a cursor-theme warning; these are retained as native accessibility/runtime follow-up, not hidden or treated as resolved.

## Privacy and offline checks

The built web bundle rendered from a local server in a fresh headless Chrome profile with external DNS blocked. Its observed requests were to its own origin for bootstrap, CanvasKit, manifest, bundled fonts and icons. The screenshot was opened and inspected: [example web preview](images/example_web.png). This proves that exercised view does not require a CDN; it is not a general guarantee about every possible host/browser request or disconnected first-load behaviour.

Native and browser integration tests preserve the accepted fail-closed redirect/CORS behaviour. Only already no-follow requests through recognised native transports can generate the header. See `HTTP_INTEGRATIONS.md` for the exact contract.

## Before expanding claims

Obtain iOS/macOS/Windows build and runtime evidence on their respective hosts; perform real-device/screen-reader/performance testing; validate release signing/configuration separately; and rerun the privacy/redirect/CORS matrix for any changed dependency/runtime. CI setup belongs to Phase 5. No CI workflow, remote run, publishing or deployment is implied by this matrix.
