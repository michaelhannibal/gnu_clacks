# GNU Clacks — Tribute UI/UX specification

## Intent

Create a dignified full memorial experience inside host Flutter applications. Show reverence without forcing grief-themed interactions on other app users. No gamification, advertisements, attention loops or social pressure in memorial surfaces.

## Visual identity

- Classic Clacks palette: midnight slate, antique brass and warm cream; high contrast in both dark and light contexts.
- Alternative appearances: neutral/minimal, soft light, dark, colour-adaptive host-theme.
- Theme tokens: colours, typography, spacing, radii, elevation, motion durations and icon style.
- Artwork: original semaphore tower silhouettes and signalling shapes; no copied Discworld art or brand logos.

## Screen inventory

### 1. Full memorial gallery

- Optional intro: 'Their names live on' with concise GNU explanation and non-affiliation notice where suitable.
- Responsive grid/list; narrow mobile 1 column, tablets 2, larger desktop 3+ as space permits (layout adapts to actual width rather than hard device labels).
- Each tile: local photo or elegant placeholder, display name, optional life dates, short dedication teaser and a subtle GNU mark.
- Sorting: explicit developer order first; deterministic fallback; optional alphabetical display mode.
- Zero-state: graceful explanation when no displayable memorials are configured.

### 2. Memorial detail

- Name, optional portrait, dates, complete dedication, attribution whenever required by asset terms, discreet 'GNU {name}' visual inscription.
- Never conflate UI identity with ASCII-safe header alias. If an alias differs, reveal only when desired by host app.
- Optional animated tower sequence and button for a static explanation of Clacks tradition.
- Keyboard and back navigation; proper safe areas and text resizing. Direct navigation must not reveal display-disabled entries.

### 3. Clacks animation

- Original, simple semaphore tower visualisation with a gentle pulse/signal moving across towers.
- The detail screen relays the memorial's display name: `GNU` and the name on the left, each character travelling tower to tower in a documented nine-lamp code (8-bit ASCII on the outer ring, centre lamp for END only) (see `FLUTTER_UI.md`), then END, and the name respelled on the right as letters arrive. It is a local display only; never claim it transmits anything. Without a message, the signal shows a symbolic pulse.
- Animation should pause when offscreen and on reduced-motion preference, with an equivalent static view.
- No constant CPU/GPU work from invisible screens; no audio by default.

### 4. Compact widgets

- Minimal signature `GNU · name` (host app decides whether to display an individual name).
- Small Clacks tower, plaque or dedication badge as an About-screen entry point.
- Optional overlay/hero transition into gallery; never obstruct primary app tasks.

## States and components

- Loading: only if host app provides a deferred local registry; never fake network loading.
- Empty gallery; missing image; malformed optional date; very long name; accessibility text scaling; low-contrast theme fallback; right-to-left UI support.
- UI must never expose `networkApproved` flags as if they meant personal consent; developer is responsible for the permissions and rights to memorial material.

## Accessibility acceptance

- Text contrast target WCAG AA; touch targets consistent with platform guidance.
- Screen reader description includes the name and meaningful dedication; decorative signals are hidden from accessibility tree or have concise equivalent text.
- Full keyboard focus order and labels; reduced motion and animation pause respected.
- Support large text and responsive reflow, not truncation of essential memorial details.
- Locale-neutral date formatting and optional partial-date rendering; no assumed religion or culture.

## Developer customisation

- Swap typography, theme tokens, layout and compact/full variants.
- Use prebuilt gallery/detail screens or compose primitives.
- Pass local assets; no remote image fetching as default.
- Localisation-ready strings and callback to open host app's privacy/credits screen.

## Proposed design acceptance walkthrough

1. New developer adds two displayable names with local images, only one network-approved.
2. Both appear in gallery and detail with dedication and accessible labels.
3. Network policy changes neither gallery visibility nor the content of dedications.
4. On a narrow phone and desktop, content remains readable and attractive.
5. Device reduced motion disables movement but retains Clacks meaning.
6. Offline mode retains all content; animation remains local.
7. Hidden memorial never appears in UI; separate network approval still follows explicit config and must not be inferred from visibility.

## Asset policy (accepted at Phase 0 closure)

Keep a developer-maintained record for every bundled image, font and other asset: creator, provenance, licence or permission basis, required notice and any modifications. Ship required licence notices and make required attribution accessible offline in detail or credits views, according to the asset terms. Do not hide legally required attribution behind optional presentation settings. Use original project art; host memorial material remains the developer's responsibility. Core stores references and attribution data without opening files; Flutter or host tooling checks asset existence and supplies accessible fallbacks. No runtime asset fetching is introduced.

## Phase 3 implementation and review

The human explicitly authorised Phase 3 on 16 November 2026. Full screens and composable cards/portraits/badges now enforce display eligibility; the signal uses original Canvas artwork with a static semantics label. Host strings, dates, typography and appearance tokens are configurable. The implementation and host visibility responsibilities are documented in `FLUTTER_UI.md`.

Widget/accessibility tests and three visual golden snapshots are recorded in `VALIDATION.md`. The implementation has been visually inspected by the coding agent; human visual/accessibility sign-off and real assistive-technology/device validation are not implied. Phase 4 example/platform work remains separate.

## Phase 4 integration follow-up

The fictional example now integrates local river/lantern illustrations, full gallery/detail navigation, all three usage modes and an offline privacy/credits view. A pending local image decode uses the same original placeholder as missing assets. The example's two goldens and built web screenshot were visually inspected; this does not replace human or real assistive-technology review. Platform evidence and native warnings remain explicit in `PLATFORM_MATRIX.md`.
