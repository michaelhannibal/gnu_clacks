import 'package:gnu_clacks_core/gnu_clacks_core.dart';

/// Fictional, developer-configured sample content. No end-user editing.
final exampleRegistry = MemorialRegistry([
  Memorial(
    id: 'alex-example',
    displayName: 'Alex Example',
    dedication: 'For the kindness shared, the paths explored and the stories that remain.',
    birthDate: PartialDate(1942),
    deathDate: PartialDate(2020),
    displayEnabled: true,
    networkApproved: true,
    networkName: 'Alex Example',
    sortOrder: 1,
    imageAsset: 'assets/river.png',
    imageAltText: 'An original abstract river landscape at dusk.',
    imageAttribution: AssetAttribution(
      creator: 'Ydesignz',
      source: 'Original example illustration',
      licence: 'MIT',
    ),
  ),
  Memorial(
    id: 'sam-example',
    displayName: 'Sam Example',
    dedication: 'Remembered for a curious mind, a generous spirit and a love of the everyday.',
    birthDate: PartialDate(1956),
    deathDate: PartialDate(2024),
    displayEnabled: true,
    networkName: 'Sam Example',
    sortOrder: 2,
    imageAsset: 'assets/lantern.png',
    imageAltText: 'An original geometric lantern beneath a night sky.',
    imageAttribution: AssetAttribution(
      creator: 'Ydesignz',
      source: 'Original example illustration',
      licence: 'MIT',
    ),
  ),
  Memorial(
    id: 'robin-example',
    displayName: 'Robin Example',
    dedication: 'The laughter and quiet moments stay with us.',
    displayEnabled: true,
    sortOrder: 3,
  ),
]);
