# GNU Clacks — Architecture decision record

## ADR-001: Flutter/Dart first, portable core

**Accepted.** Deliver as pure Dart Core plus Flutter UI and optional transport adapters. No native platform plugin in v1; future framework ports reuse protocol/test vectors.

## ADR-002: Developer-owned memorials

**Accepted.** All v1 memorials are configured by the host application developer. No user submissions, login, global registry or cloud database.

## ADR-003: Full visual tribute

**Accepted.** Gallery, detail, compact widgets, Clacks animation, original visual themes, local imagery and accessibility are first-release deliverables.

## ADR-004: Approved-host HTTP automation

**Accepted.** Once a developer explicitly enables an adapter, permits a memorial for network use and allowlists an HTTPS origin, the header is automatically added to eligible requests on that client. All controls default off; redirects re-evaluated and no global network hooks.

## ADR-005: MIT

**Accepted.** MIT copyright holder and project steward: **Ydesignz** (confirmed by the human on 16 November 2026). Formal licence text and copyright attribution must be created at implementation stage before release.

## ADR-006: Local-first / no mandatory backend

**Accepted.** No third-party network, analytics or telemetry by default; local gallery and animation work offline.

## ADR-007: Header compatibility

**Accepted by the human on 16 November 2026.** Use conventional `X-Clacks-Overhead: GNU Name` for one name and project-specific comma-separated segments, each prefixed `GNU `, for multiple names. Multi-name interoperability is explicitly unverified; do not claim a community standard. The human subsequently accepted the detailed validation rules and vectors in `PROTOCOL.md` and closed Phase 0.

## ADR-008: Honesty about the protocol

**Accepted.** GNU is a memorial metaphor, not a promise that HTTP servers never log headers or forward names indefinitely.

## ADR-009: Protected origin redirects

**Accepted; clarified by the human on 16 November 2026.** Omit package-generated headers whenever safe redirect handling cannot be guaranteed, preserving the client's normal request behaviour. Do not silently disable redirects or introduce a strict mode. Default Dio browser transmission is disabled; other configurations require evidence before transmission is enabled.

## ADR-010: Cultural and legal boundaries

**Accepted.** Inspired by a literary tradition, but use original artwork and documentation; avoid suggestions of official association with the estate or copied copyrighted materials.

## ADR-011: Existing headers

**Accepted by the human on 16 November 2026.** Preserve host-supplied `X-Clacks-Overhead` headers without merging, replacing or duplicating them. Package approval guarantees apply to values it generates; preserving a host header neither validates it nor establishes network approval.

## Phase 0 closure and Phase 1 authorisation

**Accepted and closed by explicit human instruction on 16 November 2026.** The human accepted the detailed protocol, ordering, byte-budget, origin and asset rules and authorised moving to Phase 1. The scope is monorepo infrastructure and pure-Dart Core only; UI and adapters remain later phases.

Carry-forward evidence does not imply support:
- Package identifier availability remains unverified after failed registry lookups; do not publish or rename without review.
- Multi-name interoperability remains explicitly unverified by accepted choice.
- Adapter/native/web redirect guarantees need runtime validation in Phase 2; unproven configurations omit generated headers. Core assertions and simulated hops do not establish transport safety.
- Core initially targets the local tested Dart 3.13.3 SDK. Minimum-version expansion and Flutter/platform support windows require separate evidence.

## Phase 1 implementation notes

- At the Phase 1 milestone, the private Pub workspace contained only `gnu_clacks_core`. The unused calculator scaffold was replaced; Core has no runtime dependencies. Phase 2 additions are recorded below.
- API entry point is `gnu_clacks_core.dart`: immutable definitions, defensive registry snapshots, partial dates, local attribution, origin validation and `HeaderPolicy.evaluate`.
- Raw URL strings preserve authority spellings for conservative validation. Any invalid allowlist entry or budget disables all generated transmission. Required model validation throws generic, value-free errors; invalid optional aliases produce diagnostic codes and do not disable display.
- `redirectSafetyVerified` is false by default; integrations must prove safety before asserting it. Existing host fields suppress generation and are not parsed. Core does not mutate requests, follow redirects or send data.
- Formal MIT licence names Ydesignz. Both workspace and Core are non-publishable pending release preparation.

## Phase 2 authorisation and implementation notes

**Authorised by the human on 16 November 2026** by instructing the project to move to the next step after Phase 1. Phase 2 adds HTTP/Dio integrations, tests and documentation only.

- Native generation is limited to recognised http 1.6.0 IOClient and Dio 5.11.1 IOHttpClientAdapter configurations with host-selected `followRedirects=false`. Automatic redirects are never silently changed; generated values are omitted from those requests entirely.
- Both browser integrations and custom/subclassed/decorated transports omit generated headers. Unknown low-level HttpClient implementations are outside the tested guarantee. Neither package offers an override that asserts arbitrary transport safety.
- Dio's opted-in interceptor installs a private final dispatch guard to evaluate the destination after later host interceptors/transforms. This stays within the existing Dio package boundary; a request interceptor alone would not establish safety.
- Generated values exist only in private outgoing snapshots and are removed after dispatch, including native transport errors, before retry/logging handlers see those snapshots. Host values remain untouched.
- Dependencies are pinned to tested versions pending a wider support review. No package is published and no Flutter support matrix is claimed. See `HTTP_INTEGRATIONS.md` and `VALIDATION.md`.

## Phase 3 authorisation and implementation notes

**Explicitly authorised by the human on 16 November 2026** with “phase 3 please”. This adds the full Flutter tribute UI and tests without changing Core or transport policy.

- `gnu_clacks_flutter` imports Flutter/Core only. It renders local developer-owned content, never infers display from network approval, and checks eligibility in direct detail and composable widgets.
- Original tower geometry is a local visualisation with no transmission claim (encoding superseded by ADR-013). No portraits/fonts are shipped as package content or fetched at runtime.
- Reduced motion overrides package animation and gallery-created route transitions. App lifecycle, scrolling/viewports, opacity/Offstage and TickerMode pause the signal; custom retained/hidden layouts can explicitly set `active=false`.
- Theme/localisation configuration stays in Flutter. Host typography is respected, opaque surface/foreground pairs have contrast fallbacks, and supplied asset attribution is displayed offline.
- Development uses the existing Flutter 3.47.4/Dart 3.13.3 SDK through a temporary writable tool cache. Flutter SDK constraints changed resolved development-tool versions; Core/adapter regressions were rerun. No SDK upgrade or new runtime dependency on a transport was introduced.
- See `FLUTTER_UI.md` and `VALIDATION.md`. Human visual/accessibility sign-off, the example app and multi-platform build matrix remain outstanding; nothing is published.

## Phase 4 authorisation and implementation notes

**Explicitly authorised by the human on 16 November 2026** with “Phase 4”. The example app, local-only fixtures, available-host compatibility tests/builds and audits are authorised; CI, publication and Phase 5 remain separate.

- The example starts visual-only with motion/transmission off and no endpoint. Three fictional entries and original local illustrations demonstrate display/network separation. By user instruction (16 November 2026) the private demo app now lists only four superheroes who died on screen in recent films, replacing the three fictional entries, with original dedications, in-story years and original illustrations. Tony Stark takes over as the single network-approved name for the localhost header demo; the others are display-only. They are a local demo only and never appear in published package examples or READMEs. The example consumes Core policy; it is not a new source of protocol rules.
- Optional test actions are restricted to developer-configured HTTPS localhost/127.0.0.1 origins and explicit sends. Normal TLS validation remains intact. Test-specific certificate trust is confined to automated fixtures, not app/adapters.
- Plain-Dart header-only, visual-only and full-tribute paths are provided. Web renderer/fonts are served locally; disconnected web cold-start asset caching remains host-owned.
- Generated platform runners and original application icons target all six platforms, but only evidenced builds/runs are claimed. See `PLATFORM_MATRIX.md`; no unsupported Apple/Windows support claim is inferred from scaffolds.
- The user explicitly chose **Android build-only validation**, declining installation/launch on the connected device. No device installation, forwarding or trust modification is permitted without a new instruction.
- The example includes properly noticed bundled Roboto and framework-referenced Cupertino icon assets. A live advisory query covered 62 resolved hosted packages with no matching known advisory; SDK/native/OS and unknown-vulnerability coverage is not implied.
- Integration/visual review prompted a small UI correction: local portraits now show the original fallback while decode is pending. Tests explicitly wait for real decoding rather than mistaking a loading slot for an image.
- Native accessibility warnings and unverified platforms/performance gates remain recorded. No publication, domain, remote repository or CI workflow was created.

## Phase 5 authorisation and release inspection

The human authorised the final phase on 16 November 2026. Documentation, tested minimal examples, package-contained reference docs, pinned CI configuration and disposable publish dry-runs are authorised. Publication, remote repository creation, pushes and device deployment remain outside scope.

- Preserve `publish_to: none` in all source manifests. Only disposable candidate copies remove it for `publish --dry-run`.
- Keep exact http 1.6.0 and Dio 5.11.1 constraints: broader compatibility has not been proven. Their pub validation warnings are deliberate pending compatibility review, not silently waived.
- All four dry-runs reached archive validation and exited 65: missing repository/homepage metadata on all, plus exact transport constraints on the adapters. There were no uploads. Workspace resolution does not prove that an independent consumer can resolve an unpublished Core dependency; revalidate after explicitly authorised Core publication.
- Public name lookups returned 404 for all five proposed names. This supersedes the earlier failed-lookup evidence, without establishing ownership or guaranteed availability.
- The human subsequently supplied `ydesignz.co.za` and `apps@ydesignz.co.za`. Record the HTTPS site as the project homepage (not an invented source repository URL), and the email as the private security contact. Delivery/monitoring remain untested; no email was sent. The actual source repository URL remains unconfigured.
- CI definitions are locally linted, not remotely executed. 1.0 readiness still requires the platform, accessibility/performance, metadata and human approvals in `RELEASE.md`.

## ADR-012: Umbrella package and synchronised release tooling

Accepted by explicit user instruction on 16 November 2026. Add `gnu_clacks` as a
Flutter umbrella re-exporting all four existing public libraries, preserving their
independent dependency boundaries. All five versions match; the private example
tracks the same version. Release tooling updates internal constraints and publishes
standalone disposable copies in dependency order using normal interactive pub
validation. This authorises creating the tool, not executing uploads in this task.

## Release automation follow-up

The user authorised bounded local registry waits and a configurable publishing
workflow. Use exact-version visibility checks and independent resolution retries;
keep local prompts and require clean dry-runs for non-interactive CI uploads.
Package-specific tag pushes and a protected `pub.dev` environment scope OIDC
publishing. First publication and remote configuration remain manual.

## ADR-013: Clacks lamp relay of the memorial name

Accepted by explicit user instruction on 16 November 2026. The detail screen's
signal relays the display name: name on the left, each character crossing the
towers in a 2×3 lamp code, then printed on the right in order. The code is each
character's upper-cased ASCII code point reduced to its low six bits (`A` = 1,
space = 32), which is unique for space to `_`. A reference chart image of a
different Clacks alphabet was supplied, but that chart's lamp patterns are not
used; the user chose to keep the ASCII-based code and draw original artwork.
`ClacksLampCode` lives in Core as pure display data and is never used for
header values. Animation remains local, optional and reduced-motion aware.

Addendum (16 November 2026, user instruction): the detail relay sends
`GNU <display name>` followed by an END signal, and the detail screen omits
the portrait placeholder when a memorial has no image.

Superseded encoding (same day, user instruction): the 2×3 low-six-bit code is
replaced by a 3×3 grid. The eight outer lamps show the full 8-bit ASCII byte
(as in the clacks-messenger alphabet the user referenced), read clockwise
from the top-left, most significant bit first. The centre lamp is reserved:
characters never light it, and END is the centre lamp alone. At most eight
lamps are ever lit, every printable ASCII character is distinct (including
`?` and lowercase), and END cannot collide with a character.
