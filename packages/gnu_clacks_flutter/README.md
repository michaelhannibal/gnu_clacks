# GNU Clacks Flutter

Offline memorial gallery, detail screen, compact badge, local portraits and a Clacks tower animation that relays the memorial's name letter by letter. Depends only on Flutter and GNU Clacks Core; no transport adapter or backend is required. MIT, copyright 2026 Ydesignz.

Import `package:gnu_clacks_flutter/gnu_clacks_flutter.dart`. Supply an immutable Core registry with explicit display eligibility. `MemorialGallery` provides responsive cards and detail navigation; `MemorialDetailScreen`, `MemorialCard`, `MemorialBadge`, `MemorialPortrait` and `ClacksSignal` can be used independently. Hidden definitions remain hidden in directly composed widgets. Network aliases and approval flags never become UI identities.

Choose classic, light, dark, minimal or host-derived appearances, or override the ClacksTheme extension. All strings and partial-date formatting are overridable through host localisation delegates. Motion is optional; reduced-motion preferences, lifecycle, visibility and TickerMode take precedence. Images use packaged AssetImage only, with a local drawn fallback and visible supplied attribution.

Read the [Flutter UI guide](doc/FLUTTER_UI.md) for API configuration, navigation, assets, accessibility, localisation, motion and visibility responsibilities. See the repository validation record and the repository golden snapshots.

Development uses Flutter 3.47.4/Dart 3.13.3. The minimum Flutter constraint matches the tested SDK; older versions and platform build support are unverified. Run `flutter pub get --offline` from the workspace when dependencies are cached; run `flutter test --no-pub` from this package. Golden tests use SDK fonts and require FLUTTER_ROOT to point at that SDK. Run the dedicated browser smoke file with `flutter test --no-pub --platform chrome test/web_smoke_test.dart`. Engine/browser tests need local sockets. Golden regeneration requires visual review before accepting changed baselines.

This is a non-publishable development package. A minimal composition example is included; the full showcase remains in the repository. An independent community tribute, without official Discworld or Terry Pratchett estate affiliation.

## Quick start

The suite is unpublished. Resolve the checked-out workspace with `flutter pub get`; do not assume a hosted package can be installed yet. The self-contained [public example](example/gnu_clacks_flutter_example.dart) is compiled and checked with the package source. It uses fictional content and makes no automatic external request.

Read the [security model](doc/SECURITY_MODEL.md), [protocol](doc/PROTOCOL.md), [migration policy](doc/MIGRATION.md) and [platform limits](doc/PLATFORM_MATRIX.md) before integration. Production use and publication still require the recorded release gates.

<!-- EXAMPLE_BEGIN -->
```dart
import 'package:flutter/material.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

/// Minimal visual-only composition; no transport package or network approval.
Widget createTributeApp() => MaterialApp(
  home: MemorialGallery(
    animate: false,
    registry: MemorialRegistry([
      Memorial(
        id: 'fictional-alex',
        displayName: 'Alex Example',
        displayEnabled: true,
        dedication: 'Remembered for the kindness shared.',
      ),
    ]),
  ),
);

void main() => runApp(createTributeApp());
```
<!-- EXAMPLE_END -->
