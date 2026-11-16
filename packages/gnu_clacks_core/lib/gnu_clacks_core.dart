/// Local memorial definitions and pure, default-off HTTP header decisions.
///
/// This library performs no I/O and provides no transport or global interception.
library;

export 'src/models.dart'
    show PartialDate, AssetAttribution, Memorial, MemorialRegistry;
export 'src/lamp_code.dart' show ClacksLampCode;
export 'src/origin.dart' show HttpsOrigin;
export 'src/header_policy.dart';
