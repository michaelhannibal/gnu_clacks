# GNU Clacks

One dependency for the complete GNU Clacks suite: developer-configured memorials,
accessible Flutter gallery/detail widgets and opt-in HTTP/Dio integrations.
Requires Flutter and includes both transport dependencies. Standalone packages
remain available for smaller compositions.

After publication, install with `flutter pub add gnu_clacks` and import
`package:gnu_clacks/gnu_clacks.dart`. Currently use the repository workspace.

Installing or importing this package sends nothing. Transmission requires an
explicit adapter, enabled policy, approved name and exact HTTPS origin. Automatic
redirects and browser transports omit generated headers. See [security](doc/SECURITY_MODEL.md),
[transport/CORS guidance](doc/HTTP_INTEGRATIONS.md) and [UI guidance](doc/FLUTTER_UI.md).
Local assets only; reduced motion overrides animation. Platform claims remain
limited to [recorded evidence](doc/PLATFORM_MATRIX.md).

MIT, Ydesignz. Inspired by Going Postal; no official Discworld or estate affiliation.

<!-- EXAMPLE_BEGIN -->
```dart
import 'package:flutter/material.dart';
import 'package:gnu_clacks/gnu_clacks.dart';

void main() {
  runApp(MaterialApp(home: MemorialGallery(registry: MemorialRegistry([]))));
}
```
<!-- EXAMPLE_END -->
