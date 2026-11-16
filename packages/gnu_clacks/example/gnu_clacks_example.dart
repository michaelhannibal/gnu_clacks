import 'package:flutter/material.dart';
import 'package:gnu_clacks/gnu_clacks.dart';

/// Fictional, display-only memorials. `networkApproved` stays false, so even
/// with an adapter installed no name would be sent in a header.
final exampleRegistry = MemorialRegistry([
  Memorial(
    id: 'alex-example',
    displayName: 'Alex Example',
    displayEnabled: true,
    sortOrder: 1,
    dedication: 'For the kindness shared and the stories that remain.',
  ),
  Memorial(
    id: 'sam-example',
    displayName: 'Sam Example',
    displayEnabled: true,
    sortOrder: 2,
    dedication: 'Remembered for a curious mind and a generous spirit.',
  ),
]);

Widget createTributeApp({bool animate = true}) => MaterialApp(
  title: 'GNU Clacks',
  home: MemorialGallery(registry: exampleRegistry, animate: animate),
);

void main() => runApp(createTributeApp());
