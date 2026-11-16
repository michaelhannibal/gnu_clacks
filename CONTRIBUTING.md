# Contributing

Ydesignz stewards this project. Read `AGENTS.md`, `README.md` and `docs/` before changing behaviour; recorded decisions are authoritative. Discuss architecture changes before implementing them. Use British English and fictional memorial data in tests and examples.

## Local checks

Use Flutter 3.47.4 / Dart 3.13.3 and the committed workspace lockfile. Run `flutter pub get --enforce-lockfile` at the root, `dart format --output=none --set-exit-if-changed packages apps tool`, `dart analyze --fatal-infos` and `python3 tool/sync_package_docs.py --check`.

Run `dart test` from each Core, HTTP and Dio package directory, and `flutter test` from the Flutter package and example directories. Browser tests and platform builds are defined in [CI guidance](docs/CI.md). Native adapter tests use loopback HTTPS fixtures; their test-only keys must never become production credentials. No personal device installation is required or implied.

Keep public examples executable, update their tests and run `python3 tool/sync_package_docs.py` after editing examples or authoritative docs. Review changed golden images visually before accepting them; never regenerate baselines merely to silence a failure. Include actual commands, outcomes and unavailable checks in a contribution.

## Review expectations

Preserve independent display/network approval, exact origins, default-off transmission, redirect safety and existing host headers. Cover changed policy and transport behaviour with meaningful tests. Test reduced motion, semantics, keyboard use and local asset fallbacks when changing UI. Record asset authorship, licence and attribution. Do not add analytics, default requests, remote assets or consumer memorial editing.

Treat contributors and memorial subjects respectfully. Harassment, personal data disclosure and discriminatory conduct are unacceptable. Maintainers may remove harmful contributions. Use the private reporting route once configured for sensitive security reports; see [SECURITY.md](SECURITY.md). Do not publish exploit details or personal memorial data in public issues.

Publication, repository creation, pushes and domain registration require explicit steward instruction. See the [release checklist](docs/RELEASE.md).
