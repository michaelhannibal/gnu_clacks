import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';

/// Override strings and date methods in a host-supplied localisation delegate.
/// Defaults are British English; no locale or translation is fetched remotely.
class ClacksLocalizations {
  const ClacksLocalizations();

  static ClacksLocalizations of(BuildContext context) =>
      Localizations.of<ClacksLocalizations>(context, ClacksLocalizations) ??
      const ClacksLocalizations();
  static const LocalizationsDelegate<ClacksLocalizations> delegate =
      _EnglishDelegate();

  String get title => 'In remembrance';
  String get introduction => 'Their names live on';
  String get introductionBody =>
      'A quiet place to remember the people who remain part of our lives.';
  String get emptyTitle => 'A place for remembrance';
  String get emptyBody => 'There are no memorials to display here yet.';
  String get unavailable => 'This memorial is not available.';
  String get dedication => 'Remembered with love';
  String get explanationTitle => 'About the Clacks';
  String get explanation =>
      'Inspired by the Clacks tradition in Terry Pratchett’s Going Postal, GNU is a symbolic tribute to keeping a name in remembrance. The towers send GNU and the name letter by letter, then the end signal, on a grid of nine lamps: each character’s 8-bit ASCII code is shown on the eight outer lamps, read clockwise from the top-left, and the centre lamp lights alone for the end. The animation runs only on this device; nothing is sent.';
  String get nonAffiliation =>
      'An independent community tribute. Not affiliated with Discworld or the Terry Pratchett estate.';
  String get symbolicSignal => 'Symbolic Clacks signal. Their names live on.';

  /// Shown after the relayed message for the end-of-message signal.
  String get endSignal => 'END';
  String relaySignal(String name) =>
      'Clacks towers sending $name letter by letter, then the end signal. Their names live on.';
  String get pause => 'Pause motion';
  String get resume => 'Resume motion';
  String get credits => 'Privacy and credits';
  String get assetCredits => 'Image attribution';
  String get creator => 'Creator';
  String get source => 'Source';
  String get licence => 'Licence or permission';
  String get modifications => 'Modifications';
  String get unknownDate => 'Date not recorded';
  String openMemorial(String name) => 'Remember $name';

  /// Precision-preserving ISO-style display; override for host locale conventions.
  String date(PartialDate value) => [
    value.year.toString().padLeft(4, '0'),
    if (value.month != null) value.month.toString().padLeft(2, '0'),
    if (value.day != null) value.day.toString().padLeft(2, '0'),
  ].join('-');

  String lifespan(PartialDate? birth, PartialDate? death) =>
      '${birth == null ? unknownDate : date(birth)} – ${death == null ? unknownDate : date(death)}';
}

class _EnglishDelegate extends LocalizationsDelegate<ClacksLocalizations> {
  const _EnglishDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<ClacksLocalizations> load(Locale locale) =>
      SynchronousFuture(const ClacksLocalizations());
  @override
  bool shouldReload(_EnglishDelegate old) => false;
}
