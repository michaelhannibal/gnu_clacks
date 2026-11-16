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
