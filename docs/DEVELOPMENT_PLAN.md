# GNU Clacks — Codex development plan

**Status:** Phase 0 accepted and closed by the human on 16 November 2026; Phases 1–3 implemented; Phase 4 explicitly authorised by the human on 16 November 2026. Available-host example/build/test/audit work is implemented for review; Phase 5 is now explicitly authorised and prepared. Remaining release gates are explicit in `RELEASE.md`.

## Engineering strategy

A staged monorepo of four packages and an example app. Work in vertical slices; define tests before integration; preserve independent core, UI and optional transports. Use British English for prose. All production behaviour must be privacy-safe by default.

## Phase 0 — Validation and repository baseline

**Objective:** remove foundational uncertainty before implementation.

Tasks:
- Check `gnu_clacks` and subpackage naming availability on pub.dev and suitable repository naming; adjust names only after review.
- Review the selected project-specific comma-separated multi-name grammar and exact test vectors; explicitly retain the accepted unverified interoperability limitation.
- Review licence attribution and trademark/non-affiliation wording; record Ydesignz as MIT copyright holder and project steward (confirmed).
- Choose current supported stable Dart/Flutter toolchain by testing, not guessing versions.
- Document supported Dart HTTP/Dio versions, web redirect/CORS constraints and whether safe redirect interception is feasible for each runtime.
- Finalise local asset attribution policies and full UI information architecture.

**Exit:** architecture decision record explicitly signed off; detailed header grammar approved, unverified multi-name interoperability disclosed, and redirect rules resolved through proven guarantees or explicit transmission disablement. Phase 0 approval does not itself authorise implementation.

### Audit baseline — 16 November 2026

- Package-name lookups failed; no availability or reservation is claimed.
- At the initial Phase 0 audit, the calculator scaffold, YAML files and placeholder licence/changelog were left untouched. Phase 1 subsequently replaced that scaffold. The inspected directory did not expose a Git repository.
- Cached SDK metadata reports Flutter 3.47.4 stable and Dart 3.13.3; the cached Dart executable confirmed 3.13.3. Standard Dart/Flutter launchers failed attempting writes to the read-only SDK cache. No compatibility tests or builds ran; these observations do not establish supported versions or the latest stable release.
- Registry pages inspected during the audit listed http 1.6.0 and Dio 5.11.1 as candidates. No dependency support range is approved until tested.
- The human subsequently accepted the rules, explicitly closed Phase 0 and authorised Phase 1. Name availability, dependency/platform windows and transport runtime evidence carry forward without support claims.

## Phase 1 — Pure-Dart core

Core implementation passed its VM/browser checks; executed evidence and remaining limitations are recorded in `VALIDATION.md`.

Tasks:
- Initialise monorepo infrastructure and `gnu_clacks_core` package with lint/test tooling.
- Immutable memorial and registry models with field validation and independent display/network eligibility.
- Safe ASCII alias requirements, deterministic sorting/deduplication, byte-limited header composer and structured non-sensitive diagnostics.
- Exact HTTPS origin matcher and redirect origin recomputation policy.
- API documentation and exhaustive pure-Dart tests.

**Exit:** all policy test vectors pass in Dart VM and browser-compatible environment; no network dependency.

## Phase 2 — HTTP integrations

Implemented for review. The conservative native no-follow path and explicit browser/custom-transport disablement are documented in `HTTP_INTEGRATIONS.md`. No automatic redirect handling or hidden retries were introduced.

Tasks:
- `gnu_clacks_http`: opt-in `package:http` client wrapper, robust handling of request clones, redirects and retries.
- `gnu_clacks_dio`: opt-in Dio interceptor, preserve existing headers without merging, and omit generated headers where redirect safety is unproven. Default Dio browser transmission remains disabled.
- Explicit per-origin allowlist, default-off, robust errors, no accidental interception of unrelated HTTP clients.
- Mock-server integration tests including HTTP-to-HTTPS, cross-origin, ports, preflight and header logging warnings.

**Exit:** no name leaks across unapproved origins under all supported transport runtime scenarios; where impossible to guarantee, fail closed and document limitation.

## Phase 3 — Full Flutter experience

Implemented for visual/accessibility review. See `FLUTTER_UI.md`, the three inspected golden snapshots and `VALIDATION.md`. Example app and platform build work remain Phase 4.

Tasks:
- Build themed local memorial cards, gallery, detail, compact entry points, animations and reduced-motion semantics.
- Design token system: classic Clacks, light, dark, minimalist, host override.
- Accessibility: keyboard navigation, screen readers, text scaling, localisation infrastructure and contrast review.
- Golden/widget tests for devices and viewport classes; asset fallbacks; no background timers when unused.

**Exit:** visual and accessibility review approved, offline behaviour verified.

## Phase 4 — Example app and platform compatibility

Implemented for available-host review. The example demonstrates all three configurations with fictional/local content, no default endpoint and explicit localhost-only test actions. See `PLATFORM_MATRIX.md`, `PHASE4_AUDIT.md` and `VALIDATION.md`. Web/Linux release and Android debug builds have evidence; Android runtime testing was explicitly declined. iOS/macOS/Windows builds and real-device cold-start/accessibility profiling remain unverified. No blanket six-platform support claim is made.

Tasks:
- Build polished demonstration app containing fictional sample names, with local assets and test endpoints only.
- Demonstrate visual-only, header-only and full-tribute setups; document deployment differences.
- Run integration/build matrix on Android, iOS, web, Windows, macOS and Linux, with real browser CORS checks.
- Performance smoke tests, dependency audits and privacy audit.

**Exit:** every claimed platform has evidence; accurate platform limitations published.

## Phase 5 — Documentation, release and maintenance

Authorised on 16 November 2026. Release preparation is implemented for review; the 1.0 exit criterion remains blocked by the gates in `RELEASE.md`. No publication is authorised.

Tasks:
- Complete end-user README, quick-start examples (implementation code only at this phase), API docs, changelogs, versioning and contribution policy.
- Add formal MIT `LICENSE`, attribution/non-affiliation notice and original visual assets.
- Setup GitHub Actions CI, release checklists and security issue reporting.
- Execute publish dry-runs, resolve warnings and verify pub.dev metadata for each publishable package.
- Human sign-off before first publication.

**Exit:** documented 1.0 release ready; **publishing requires separate instruction**.

## Backlog for later frameworks (not v1)

- Publish framework-independent test vectors and protocol document.
- Server-side response middleware examples for major frameworks (Node, Python, .NET, Java).
- React/React Native, Kotlin, Swift libraries, each independently privacy-checked.
- Optional community-managed memorial network only if a later explicit product decision warrants privacy, hosting and moderation complexity.

## Milestone acceptance matrix

| Requirement | Acceptance evidence |
|---|---|
| Developer-only content | No runtime end-user creation flows, network or accounts |
| Display/network separation | Tests prove display cannot enable network transmission |
| Approved-host automation | Exact-origin tests, redirect tests, default-off tests |
| Header correctness | Interoperability vectors, validation and byte-budget tests |
| Full tribute | Screens, widget/golden tests, theming and responsive layout |
| Accessibility | Semantics tests, focus/keyboard, contrast, reduced motion |
| Offline-first | All tribute screens work without network |
| Multi-platform | CI builds/smoke checks with evidence per platform |
| Open source | MIT licence, attribution, changelog and contributor guidance |

## First six Codex implementation tasks after approval

1. Scaffold repo, package metadata and test infrastructure (no feature UI).
2. Create pure-Dart immutable memorial and registry model with validation tests.
3. Create network eligibility, URI origin policy and no-leak test vectors.
4. Implement safe wire format and byte-limited composer with header test vectors.
5. Implement `package:http` adapter with redirect proof and integration tests.
6. Implement Dio adapter with safety tests and web preflight documentation.

Steps 1–6 are implemented for review under the human's Phase 1 and Phase 2 authorisations. Phase 3 UI is also implemented under separate explicit authorisation; Phase 4 example/validation work is also authorised and implemented within the documented host/device limits. Phase 5 is explicitly authorised by the human; documentation, CI and non-publishing release inspection are being prepared. Publication still requires separate instruction.
