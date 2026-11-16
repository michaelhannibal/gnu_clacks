# Release preparation

Phase 5 prepares an unpublished `0.1.0-dev.1` candidate. It does not establish the development plan's 1.0 exit criterion. Publication requires separate explicit human instruction and completion of the gates below.

## Gates

- Obtain human visual/accessibility approval, real screen-reader review and device performance/cold-start evidence. Investigate Linux ATK warnings.
- Obtain actual iOS, macOS and Windows build/runtime evidence before claiming support. Android currently has build-only evidence by explicit user choice. Obtain actual CI runs; workflow configuration alone is insufficient.
- Supply the actual source repository URL. The steward supplied https://ydesignz.co.za as the project homepage and apps@ydesignz.co.za as the private security contact; these are now documented and the homepage is in package metadata. Confirm mailbox delivery/monitoring, verify public links and agree a maintenance/support policy. No reporting email was sent during preparation.
- Confirm ownership of package names immediately before release. Live pub.dev lookups on 16 November 2026 returned HTTP 404 for `gnu_clacks`, `gnu_clacks_core`, `gnu_clacks_flutter`, `gnu_clacks_http` and `gnu_clacks_dio`; this neither reserves names nor guarantees availability. No names were registered.
- Review public APIs, licences, original asset provenance, dependencies/advisories, version constraints, changelogs and migration guidance. Retain the explicitly unverified multi-name interoperability limitation.
- Run all relevant checks, API docs and publish dry-runs against the final candidates. Inspect archive contents and warnings. Do not call a warning-free dry-run successful unless it actually is.
- Obtain steward sign-off on version and package publication order. Never jump to 1.0 merely because the numbered implementation phases are finished.

## Reproducible inspection

Run `python3 tool/sync_package_docs.py --check`, then `python3 tool/stage_release.py`. It requires a resolved cached SDK/dependency set and network access for pub validation. `GNU_CLACKS_DART` can select the Dart executable. The tool creates a temporary workspace, verifies source `publish_to: none` guards, copies distributable contents and removes that guard only in disposable copies. It invokes only `dart pub publish --dry-run`; it never uploads. The report is `RELEASE_DRY_RUN.json`. Tests, benchmark outputs, lockfiles and shared TLS fixtures are intentionally excluded from package archives; their tests remain in the repository.

Package READMEs embed the actual tested public example sources. Bundled `doc/` copies keep protocol, security, migration, platform and adapter/UI guidance available within each archive. Root `docs/` remains authoritative; `tool/sync_package_docs.py --check` detects drift. Generate API HTML using `dart doc --output <directory>` from each package.

The initial dry-runs exited 65 for missing repository/homepage metadata on all candidates and exact dependency constraints on HTTP/Dio. The supplied homepage now resolves the missing metadata field; the refreshed dry-runs pass for Core and Flutter (exit 0); HTTP and Dio retain their exact-version warnings (exit 65). Those pins intentionally retain the proven transport boundary. All archives reached validation; this is not a warning-free pass. The staged workspace resolves Core locally, so it does not prove independent consumer resolution of an unpublished Core version. Dependent package validation after workspace-independent resolution may report that Core has no published matching version. Do not publish merely to clear a dry-run warning. After explicit publication approval, publish Core first, wait for registry visibility, then revalidate dependent candidates against the published version before individually publishing them. Source guards must remain until that separate instruction. No publication token is configured here.

The normal dry-run, publisher verification and archive review process is described in the [official Dart publication guide](https://dart.dev/tools/pub/publishing). A staged report is evidence about that invocation, not registry acceptance or name ownership.
