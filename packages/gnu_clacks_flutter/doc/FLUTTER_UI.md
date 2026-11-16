# Flutter tribute UI — Phase 3

`gnu_clacks_flutter` depends on Flutter and Core only. It imports no HTTP/Dio adapters, fetches no images or fonts, and installs no telemetry, account, storage or network hooks. All content comes from the host's immutable, developer-owned registry. It is an unpublished development package.

## Components

| API | Behaviour |
|---|---|
| `MemorialGallery` | Responsive screen, optional introduction, display-filtered cards, empty state, credits callback and default detail navigation |
| `MemorialDetailScreen` | Registry/ID lookup, full dedication, partial dates, local portrait, required supplied attribution, GNU inscription and Clacks relay of the display name |
| `MemorialCard` | Composable, keyboard-activatable card with visible focus outline; empty for a display-disabled entry |
| `MemorialBadge` | Compact signature, optionally tappable; never overlays the host app |
| `MemorialPortrait` | AssetImage only, with meaningful supplied alt text or decorative semantics; original static tower fallback on missing/failed assets |
| `ClacksSignal` | Original local tower animation, static equivalent, pause/resume control and viewport/lifecycle guards |
| `ClacksTheme` / `ClacksAppearance` | Colours, host typography, spacing, radii and signal period; classic, light, dark, minimal and host-derived appearances |
| `ClacksLocalizations` | British English defaults and overridable strings/date formatting through host localisation delegates |

Import `package:gnu_clacks_flutter/gnu_clacks_flutter.dart` and supply Core definitions from `gnu_clacks_core`. Configure the package in a host Material application with bounded layout constraints. Flutter's ordinary Material navigation/control icons are used; the tribute tower artwork is original Canvas geometry, without copied Discworld art, logos or characters. The relay's lamp code is plain ASCII arithmetic (`ClacksLampCode` in Core), not a copied Clacks alphabet chart.

## Content and navigation

Set `displayEnabled` explicitly on entries intended for UI. Gallery, direct detail lookup, standalone cards, badges and portraits independently enforce this flag. Direct access to a hidden or missing ID shows an unavailable state without exposing names, images or motion. Network approval never enables display. Transmission aliases and approval flags are never rendered as tribute identities or claims of personal consent.

The default gallery order follows Core's configured ordinal and deterministic name/ID fallback. A host `displayComparator` can supply alphabetical or other visual ordering after eligibility filtering; it cannot expose hidden entries or change network selection. The gallery uses width and text scale rather than device labels: typically one column on a narrow phone, two on a tablet and three or more at larger widths. Cards expand vertically, preserving the full visible name. A short dedication teaser leads to the complete detail text.

Gallery navigation opens a detail route by default. `onOpenMemorial` lets the host integrate its own router instead. Detail uses ordinary Navigator/back behaviour; credits callbacks let hosts open their existing offline privacy/credits UI. The package creates no outbound links, overlays, accounts or editing flows. The About dialog describes the literary tradition and explains the nine-lamp code and explicitly says the animation runs only on the device and sends nothing. Non-affiliation copy is included on the full surfaces.

Dates display only developer-supplied precision using ISO-style year/month/day text by default. If one endpoint is absent it is marked as not recorded; no complete lifespan is invented. Invalid dates are rejected by Core before rendering. Host localisation can override the date and lifespan methods without changing memorial data.

## Local assets and attribution

`imageAsset` is a packaged relative asset key, including a `packages/...` key where appropriate. Register host assets in the host's Flutter configuration. No NetworkImage or runtime asset loader is accepted by these widgets. Pending, missing or undecodable assets render a static original tower placeholder. Meaningful portraits need developer-supplied `imageAltText`; absent/empty alt text marks the image decorative so the name is not duplicated by an invented image description.

Supplied `imageAttribution` is always rendered in detail: creator, provenance, licence/permission, required notice and modifications. No option hides it. Host credits must also satisfy any licence terms for fonts or other host assets; the package cannot verify rights, asset existence before decode or compliance with particular terms. Source strings are plain text and do not trigger a network request.

No custom portrait or font files are shipped by this package; standard Material UI assets remain supplied by Flutter under its normal notices. The test harness loads Roboto and MaterialIcons from the installed Flutter SDK solely for stable goldens; those files remain in the SDK with their existing notices. The small synthetic portrait fixture is generated in the test asset bundle.

## Themes and accessibility

Choose `appearance` on full screens, or provide a `ClacksTheme` ThemeExtension through host ThemeData. With no appearance override, the extension takes precedence over the classic default. Host typography is respected; the package forces no remote font or font family. Theme tokens expose spacing, radius and signal-period customisation. Invalid spacing/radius fall back to safe defaults, and signal periods below one second fall back to four seconds.

Theme background/surface fills are made opaque. Text and accent foregrounds fall back to readable black or white if the supplied pair does not meet a 4.5:1 contrast target. Buttons have minimum 48 logical-pixel dimensions, cards expose Material activation semantics and a focus outline, and essential detail text can reflow and be selected. Large text reduces the column count; no fixed card height truncates memorial names or full detail copy. Directionality and keyboard traversal follow the host. Decorative towers are excluded from the accessibility tree; the signal has one static descriptive label rather than announcements on every animation frame.

Defaults are British English even without installing a delegate. Hosts can subclass `ClacksLocalizations`, override strings/formatters, and provide a LocalizationsDelegate of that type plus their normal Material/Widgets localisation delegates and supported locales. No translation service or runtime locale discovery is used.

## Detail backdrop

The detail screen shows the portrait only when a memorial has an `imageAsset`; without one there is no placeholder (gallery cards keep theirs for an even grid). When a memorial has an `imageAsset`, the detail screen also shows that image behind the whole page: blurred and washed with the theme background so only 10% shows through. It stays fixed while the page scrolls, is excluded from semantics and pointer input, and shows nothing if the asset is missing or fails to load. Memorials without an image get no backdrop. A test checks that body and accent text still meet 4.5:1 contrast in every appearance over a pure black or pure white backdrop.

## Motion and lifecycle

`animate=false` supplies static towers. On the gallery it also disables the package-created route transition; on direct detail routes the host still owns its own navigation transition. Platform/MediaQuery reduced motion always overrides animation and the package-created route transition. Accessible navigation does not suppress the signal: Android reports it whenever any accessibility service, such as a password manager, reads the screen, and screen readers already receive one static label. A user can pause and resume motion when animation is otherwise permitted.

The signal lazily allocates its controller only after visible layout. It stops for inactive/paused app states, TickerMode, Offstage, zero opacity, rectangular viewport clipping and scrolling outside the viewport. All scroll ancestors are observed, so ordinary nested scrolling can resume a stopped signal. Resuming the app schedules one visibility check frame; static widgets do not run a polling timer. Disposal removes listeners/observers and disposes any controller.

For custom retained render trees, non-rectangular clipping, unusual hidden containers or host tab systems that do not use normal paint/TickerMode lifecycles, set `active=false` while hidden. This is a host visibility input, not a way to override reduced motion. The relay is a local display and never a claim of actual transmission.

## Clacks relay

`ClacksSignal(message: ...)` relays a message across three towers; the detail screen passes `GNU <displayName>`. Every relayed message ends with an END signal (the centre lamp alone), shown as a small letter-spaced `END` that never wraps alone; hosts can translate it through `ClacksLocalizations.endSignal`. The name sits on the left. Each character enters the first tower and moves one tower per step, so several characters are in flight at once, with a small pulse running along each link. When a character reaches the last tower it is printed on the right, respelling the name in order. The full name holds for three steps, then the cycle repeats. Narrow layouts stack name, towers and respelled name vertically.

Lamp code: each tower has a three-by-three lamp panel. A character's 8-bit ASCII code is shown on the eight outer lamps, read clockwise from the top-left, most significant bit first (`A` = `01000001` lights top-middle and middle-left). The centre lamp never carries character data: it lights alone for END, so at most eight lamps are ever lit and END cannot be confused with a character. Its rim is drawn fainter to mark it as reserved. Characters outside printable ASCII (space to `~`), such as accented letters, travel with every lamp dark but are still printed, so the name is always respelled exactly. `signalPeriod` is the time a character takes to cross all three towers (one step is a third of it, at least 400 ms).

Static and reduced-motion views show the whole name on both sides with the towers at rest. Screen readers get one label, "Clacks towers spelling NAME, letter by letter", with no per-frame announcements. Without a `message`, `ClacksSignal` keeps the original symbolic pulse.

## Validation and limits

See `VALIDATION.md` for executed commands, counts and environment details. The Flutter engine tests cover navigation, visibility guards, semantics and accessibility guidelines, keyboard activation, local image fallback/decode, zero HTTP-client creation, localisation, contrast, large text and RTL. Golden PNGs cover classic desktop, light phone and static detail; they were rendered and inspected, then compared in a normal test run.

Browser smoke tests compile and render the gallery/detail in Chrome. They are not a Flutter build matrix or a complete assistive-technology audit. Native OS builds, real screen-reader review, real-device performance and large-registry profiling remain later validation. The current gallery eagerly builds a Wrap for the configured memorials; no claim is made about virtualising thousands of entries. The Phase 4 example app and available-host platform matrix are now documented in the example guide and `PLATFORM_MATRIX.md`; they do not imply full real-device validation.
