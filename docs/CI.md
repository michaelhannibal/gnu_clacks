# Continuous integration

The workflows are prepared for GitHub Actions but have not run remotely: this workspace has no Git repository or configured remote. A local check of YAML and workflow structure does not establish runner success.

`ci.yml` uses Flutter 3.47.4, Dart from that SDK, the committed lockfile, read-only repository permissions, disabled persisted checkout credentials and immutable action commit pins. The quality job checks formatting, analysis, synchronised package docs, executable examples, Flutter/example tests, Chrome policy/CORS smoke tests and API documentation. Native jobs run Core/adapter tests and desktop builds on Ubuntu 24.04, macOS 15 and Windows 2025; macOS also attempts an unsigned iOS simulator build. Linux owns golden comparisons; other hosts run selected widget tests without regenerating baselines. Another Ubuntu job builds the web bundle and Android debug APK with Java 21. It does not install an app on any device or deploy the web output.

Build artifacts are retained for seven days. They are inspection outputs, not releases. CI does not establish real-device performance, screen-reader usability, signing or publication readiness. Runner/toolchain availability must be confirmed by actual runs and retained evidence before platform claims change.

`release-inspection.yml` is manual only. It runs `tool/stage_release.py` and retains the report even on failure; its final step preserves the failing outcome. It has no publication command, credentials or deployment step. Missing metadata and unpublished dependency checks may keep it red until the release gates are resolved.

Locally, run native suites from their package directories. Run `dart test --platform chrome` in Core, HTTP and Dio; `flutter test --platform chrome test/web_smoke_test.dart` in the Flutter package and `flutter test --platform chrome test/web_test.dart` in the example. Set `CHROME_EXECUTABLE` if Chrome is not discoverable. Build commands and actual host evidence are in [the platform matrix](PLATFORM_MATRIX.md). Inspect the workflow for exact selected cross-platform test paths.

Keep action pins current through reviewed updates. Never add publication secrets to pull-request jobs. GitHub guidance: [secure use of Actions](https://docs.github.com/en/actions/reference/security/secure-use).

`publish.yml` is now prepared for package tag pushes and a protected `pub.dev`
environment. It runs native validation before the separately approved OIDC publish
job, then waits for exact hosted dependencies and requires a clean archive dry-run.
Configure each package's pub.dev repository, package tag pattern and environment
before use; see [release configuration](RELEASE.md#registry-waits-and-github-actions-configuration).
No remote workflow execution or publishing configuration is claimed.
