# AGENTS.md — GNU Clacks Project Instructions for Codex

## Mission

Create a high-quality, privacy-respecting Flutter/Dart open-source GNU Clacks memorial package suite that honours people through in-app tributes and opt-in, allowlisted HTTP overhead headers. This is a respectful remembrance project; prioritise trust, accessibility and correctness over novelty.

## Current stage

**Phases 0–5 authorised by the human; Phase 5 release preparation is prepared for human review; unresolved release gates are recorded in docs/RELEASE.md.** Complete documentation, CI configuration and non-publishing package inspection. Publication is not authorised. Android validation is build-only by explicit user choice: do not install or launch on the connected device without a new instruction. Keep README and `docs/` consistent. Do not publish, register domains, create remote repositories or push code without instruction. Dependency resolution needed for authorised work is permitted; avoid unrelated package installation.

## Immutable product decisions (change only on human instruction)

1. Flutter/Dart is the first ecosystem; preserve language-independent protocol/domain boundaries for future ports.
2. Memorial creation/ownership is **developer-configured only** in v1. No consumer accounts or user-generated memorial editing.
3. Ship the **full tribute UI**: memorial gallery, detail view, configurable visual treatments and Clacks animation.
4. HTTP overhead attaches **automatically only to expressly allowlisted HTTPS origins**, through opted-in adapters, using only memorials expressly network-approved.
5. MIT licence. No backend or telemetry requirement.
6. Aim to support Android, iOS, web, Windows, macOS and Linux. Platform claims depend on validation.
7. Use British English in source docs and copy.

## Proposed package boundaries

- Core: pure Dart, no Flutter imports and no network I/O; data types, safe formatting, policy decisions.
- Flutter: UI only and accessible animation; depends on Core, not on any transport adapter.
- HTTP: `package:http` adapter; depends on Core, not Flutter.
- Dio: interceptor adapter; depends on Core, not Flutter.
- Example: integrates optional components; never a source of business rules.

Keep public APIs minimal and stable. No platform channels or federated plugin layers unless a concrete native requirement emerges.

## Data and privacy invariants

- Keep **display consent/eligibility** independent of **network transmission approval**.
- No remote call, tracking, crash analytics, discovery, user identity or unexpected transmission.
- No outbound header unless the adapter is installed, its feature is enabled, the entry is transmission-approved and the destination matches a precisely configured, HTTPS-only origin.
- Treat redirects as a new destination: **strip or recompute** the header whenever the final origin is not approved. Never leak on automatic cross-origin redirects.
- Reject non-HTTPS endpoints by default; allow local development exceptions only behind explicit development-mode configuration and never shipped as production defaults.
- Never send dates, photos, dedications, personal IDs or other metadata in the HTTP header.
- Header names and values must be valid for HTTP; reject CR/LF and control characters, canonicalise Unicode or map to a voluntarily supplied ASCII-safe transmission alias, and impose strict byte limits.
- Never invent permission or consent from a displayed memorial entry. Provide no package-level global interception.
- Host logging and proxy logging are not controlled by the letter N: disclose that candidly.
- No runtime fetches of memorial assets by default; packaged local assets only. If remote images ever become a feature, opt in explicitly and secure them separately.

## Network policy

- Use the existing `X-Clacks-Overhead` convention, header value beginning `GNU `.
- Define deterministic ordering, deduplication, a conservative max-value byte limit, and a documented multi-name compatibility rule.
- Configured destination must match scheme, hostname and effective port; no suffix, substring or wildcard matching by default.
- Avoid repeated/stacked headers; preserve requests, response handling, cancellation and timeouts.
- On Flutter Web, explain that the custom header can cause a CORS preflight; never bypass browser restrictions or silently fall back to sending outside policy.
- Do not attach to unapproved third-party hosts, payment/authentication endpoints or external SDK calls merely because the process can see the network request.
- Test hosts, ports, redirections, case variations, encoding, oversized names, duplicate entries and multiple clients.

## UX and accessibility

- Treat memorials with dignity. No ads, gamification, scores or engagement prompts inside tribute surfaces.
- Full gallery with responsive cards and detail view; local image fallback; suitable keyboard navigation and screen-reader descriptions.
- Motion is optional and reduced-motion preferences override visual animation. Provide static semantics for all essential information.
- Original art and iconography only. No unattributed assets or implied official Discworld affiliation.
- Default styles must be themeable without exposing consumer data or requiring internet.

## Quality gates before release

- Unit tests for domain validation, header selection, encoding, origin allowlist, byte budget and deduplication.
- Integration tests for HTTP and Dio adapters including redirects and mocked servers.
- Golden/semantics/widget tests for gallery, cards, animations and accessible fallbacks.
- Build/test matrix for Android, iOS, web, Windows, macOS and Linux where supported by CI runners.
- `dart format`, `dart analyze`, `flutter test`, dependency/security review and publish dry-runs.
- Benchmarks: no material cold-start impact; no unnecessary background work or network requests.
- Documentation: setup, security model, CORS caveats, examples, migration/changelog and attribution.

## Workflow for every implementation task (once authorised)

1. Read this file and the full set of `docs/` first.
2. State scope, affected packages, acceptance criteria and risks.
3. Implement one small coherent vertical slice with tests; keep compatibility with approved architecture.
4. Validate using the available toolchain and report commands/outcomes. Never claim tests passed unless executed.
5. Update README, roadmap and design decisions when behaviour changes.
6. Stop for human review before any publishing or architecture-changing decision.

## Definition of done

All stated acceptance criteria are tested; privacy/redirect/CORS safeguards are documented; public APIs and examples are coherent; no unexpected telemetry or network access; no copyrighted artwork; no unsupported platform claims.

## Authorised Phase 5 scope

Prepare documentation, CI and publish dry-runs. Retain source publication guards and unresolved platform, accessibility, metadata and human-review release gates. Do not publish, push or deploy to the connected Android device.
