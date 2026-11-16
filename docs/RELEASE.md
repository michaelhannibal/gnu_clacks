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

## Umbrella and synchronised release command

The user authorised the `gnu_clacks` umbrella and a publishing script on 16 November
2026. This implements tooling; no registry upload was requested or performed.
All five source package versions now match at `0.2.0`. The user reported successful Core `0.2.0` publication; the following Flutter resolution failed during registry propagation. Earlier inspection reports
above describe older candidates and must be regenerated for the final versions.
The example follows the suite version but is never published.

From the repository root:

```bash
# Update all five package versions, example version and internal constraints only:
python3 tool/release.py 0.1.0
flutter pub get
# Run tests, review changelogs, metadata and the release gates above.
python3 tool/sync_package_docs.py --check
# Inspect all five together, including unpublished dependencies locally:
python3 tool/stage_release.py
# After release approval, upload in dependency order with normal pub prompts:
python3 tool/release.py 0.1.0 --publish
```

`GNU_CLACKS_FLUTTER` selects the Flutter executable for the release script.
Publication copies only distributable files into temporary standalone directories,
removes workspace resolution and publication guards there, resolves dependencies
from the registry, and invokes `flutter pub publish` interactively. Local mode retains interactive pub prompts. CI mode requires a successful dry-run before using `--force`; it does not waive validation warnings. Core is first, then Flutter, HTTP,
Dio and finally the umbrella. Installing the umbrella requires Flutter and includes
both transports; network use remains opt-in. Review each package's archive and
warnings at its pub prompt. Authentication uses the normal local pub credentials.

`--dry-run` replaces uploads with `pub publish --dry-run` in those standalone copies.
On a first release it cannot validate dependants until their dependencies are
published. Unlike `stage_release.py`, it does not resolve unpublished packages
locally. Exact upstream pins can still produce validation warnings.

A failure stops immediately. Registry uploads are not atomic and earlier uploads
cannot be rolled back by this script. Wait for registry visibility and resume with,
for example, `python3 tool/release.py 0.1.0 --publish --start-at gnu_clacks_http`.
Use the same version when resuming; the script does not skip existing releases
automatically. Version edits remain after failure. Source publication settings
are preserved, including the user's commented Core guard; active guards on the
other packages remain in place. No push, tag, app deployment, or automatic
changelog generation occurs. Update and review changelogs before publishing.

## Registry waits and GitHub Actions configuration

Local publication now waits for each exact internal dependency version on pub.dev
before standalone resolution, retries failed dependency resolution, and waits for
the uploaded version before continuing. Each wait defaults to 900 seconds with
15-second polling. Configure `--wait-timeout 1200 --poll-interval 20` if needed.
Timeout stops the release; resume using the same version and `--start-at` as above.
If upload succeeded but its visibility wait timed out, wait for visibility and
resume at the *next* package. Do not upload the completed package again.
`--package NAME` selects a single package. `--dry-run` waits for dependencies but
never uploads or waits for the candidate itself. The pub.dev version endpoint is
checked, then standalone `pub get` verifies actual resolution. Resolution retries
are bounded even for errors other than propagation; the original pub errors remain
visible. These are registry requests from release tools, not application runtime.

The prepared `.github/workflows/publish.yml` publishes one package per pushed tag,
following pub.dev's per-package monorepo convention. It has no manual dispatch or
pull-request publishing trigger. Before enabling it:

1. Complete each package's initial manual publication. Pub.dev automated publishing
   currently supports existing packages only. Core's reported upload alone does not
   initialise the other four packages.
2. In each package's pub.dev Admin tab, enable GitHub Actions publishing for the
   actual `OWNER/REPOSITORY`. Set its tag pattern to `PACKAGE-v{{version}}`, e.g.
   `gnu_clacks_core-v{{version}}` and `gnu_clacks-v{{version}}` for the umbrella.
   Require the GitHub environment named `pub.dev` for each package.
3. Create that environment in the GitHub repository and configure required reviewers
   and release-tag restrictions. Protect package release tags against unauthorised
   creation. No long-lived pub token is needed: the pinned official setup-dart action
   configures temporary OIDC credentials with job-scoped `id-token: write`.
4. Commit matching versions, internal constraints, changelogs and resolved lockfile.
   Run the normal full CI/platform checks and obtain the remaining human release
   reviews. The publishing workflow also checks versions/changelogs, format,
   analysis, documentation sync, Python tests and native component/example tests.
   It does not replace browser/platform evidence from the main CI workflow.
5. After review, create/push `gnu_clacks_core-vVERSION` for a future unpublished
   version. When successful, release Flutter, HTTP and Dio with their own tags,
   then the umbrella with `gnu_clacks-vVERSION`. Each workflow waits for its exact
   dependencies. Push in this order; a dependant started too early may time out.

CI checks committed versions instead of editing them. `--ci` requires a matching
package tag push and single package, stages standalone copies, performs a dry-run
and only uploads if validation exits zero. Existing exact HTTP/Dio pins can produce
warnings and block CI publishing; they must be reviewed/resolved without silently
widening proven transport support. Local interactive mode still permits a human to
review warnings at pub's prompt. The protected environment supplies release review;
it must be configured on GitHub, not merely named in YAML.

Failed jobs can be rerun if their package has not uploaded. If upload succeeded,
check registry visibility before rerunning: the tool deliberately does not skip or
replace an existing immutable version. Nothing in this implementation creates tags,
pushes, changes account settings or executes publication.

Configuration reference: [Dart automated publishing](https://dart.dev/tools/pub/automated-publishing).
