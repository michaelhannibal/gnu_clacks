import 'package:gnu_clacks_core/gnu_clacks_core.dart';

/// Superheroes who died on screen in recent films: developer-configured,
/// local demo content only. This app is never published. Names, original
/// dedications and original illustrations only (no character art, logos or
/// quotes). Only Tony Stark is network-approved, for the localhost header demo.
/// Dates are in-story years, so they can differ
/// from the film's release year in the dedication.
final exampleRegistry = MemorialRegistry([
  Memorial(
    id: 'tony-stark',
    displayName: 'Tony Stark',
    dedication: 'Iron Man. Avengers: Endgame (2019). Built a suit of armour, then gave everything to protect others.',
    birthDate: PartialDate(1970),
    deathDate: PartialDate(2023),
    displayEnabled: true,
    networkApproved: true,
    networkName: 'Tony Stark',
    sortOrder: 1,
    imageAsset: 'assets/forge.png',
    imageAltText:
        'An original geometric anvil with sparks rising over a city at dusk.',
    imageAttribution: AssetAttribution(
      creator: 'Ydesignz',
      source: 'Original example illustration',
      licence: 'MIT',
    ),
  ),
  Memorial(
    id: 'natasha-romanoff',
    displayName: 'Natasha Romanoff',
    dedication: 'Black Widow. Avengers: Endgame (2019). Chose her family, and let go so they could go on.',
    birthDate: PartialDate(1984),
    deathDate: PartialDate(2023),
    displayEnabled: true,
    networkName: 'Natasha Romanoff',
    sortOrder: 2,
    imageAsset: 'assets/thread.png',
    imageAltText:
        'An original geometric thread winding over hills to a lit house.',
    imageAttribution: AssetAttribution(
      creator: 'Ydesignz',
      source: 'Original example illustration',
      licence: 'MIT',
    ),
  ),
  Memorial(
    id: 'vision',
    displayName: 'Vision',
    dedication: 'Avengers: Infinity War (2018). Only a few years old, and already more human than most.',
    birthDate: PartialDate(2015),
    deathDate: PartialDate(2018),
    displayEnabled: true,
    networkName: 'Vision',
    sortOrder: 3,
    imageAsset: 'assets/dawn.png',
    imageAltText: 'An original geometric window with the sun rising beyond it.',
    imageAttribution: AssetAttribution(
      creator: 'Ydesignz',
      source: 'Original example illustration',
      licence: 'MIT',
    ),
  ),
  Memorial(
    id: 'logan',
    displayName: 'Logan',
    dedication: 'Wolverine. Logan (2017). Spent his last road trip getting a child to safety.',
    birthDate: PartialDate(1832),
    deathDate: PartialDate(2029),
    displayEnabled: true,
    networkName: 'Logan',
    sortOrder: 4,
    imageAsset: 'assets/pines.png',
    imageAltText: 'An original geometric road running between pine trees to a lake under the moon.',
    imageAttribution: AssetAttribution(
      creator: 'Ydesignz',
      source: 'Original example illustration',
      licence: 'MIT',
    ),
  ),
  // Name only: exercises the smallest valid entry (no dedication, dates,
  // image or network name).
  Memorial(
    id: 'gamora',
    displayName: 'Gamora',
    displayEnabled: true,
    sortOrder: 5,
  ),
]);
