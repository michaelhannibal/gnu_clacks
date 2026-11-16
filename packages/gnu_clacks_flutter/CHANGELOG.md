# Changelog

## Unreleased

- The detail relay sends `GNU <name>` then an END signal; the detail portrait placeholder is omitted when a memorial has no image.
- The detail screen shows the memorial's own image as a blurred, heavily faded backdrop, only when an image is set.
- Fixed: the signal no longer stops when Android reports accessible navigation, which any accessibility service (for example a password manager) triggers. Reduced motion still stops it.
- `ClacksSignal` takes an optional `message`; the detail screen relays the display name tower to tower and respells it as letters arrive. Static and reduced-motion views show the whole name with one screen-reader label.

## 0.2.0

- Updated the Core dependency to `^0.2.0` for the synchronised suite release.

## 0.1.0-dev.1 — Unreleased

- Added responsive gallery, guarded detail routes, cards, compact badges and local portraits.
- Added original static/animated tower artwork with optional motion, pause/resume and reduced-motion/lifecycle/viewport safeguards.
- Added classic, light, dark, minimal and host themes, contrast fallbacks and host localisation infrastructure.
- Added offline attribution, partial dates, focus/keyboard semantics and large-text/RTL reflow.
- Added widget, accessibility, golden and browser smoke tests. No HTTP adapter dependency or runtime image/font fetching.

- Phase 4 integration: show the local placeholder while a packaged image is decoding; explicitly verify decoded assets in tests.

- Phase 5 adds a public executable example, bundled protocol/security/migration/platform docs and release inspection metadata; this version remains unpublished.
