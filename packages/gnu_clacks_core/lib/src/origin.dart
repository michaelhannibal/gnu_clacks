/// An exact HTTPS origin under the conservative v1 ASCII host profile.
///
/// Parsing returns null for unsupported or ambiguous forms. It never resolves
/// DNS or converts Unicode hostnames to IDNA. Punycode must be validated by the
/// host before configuration. IPv6 is deliberately outside the v1 profile.
final class HttpsOrigin {
  const HttpsOrigin._(this.hostname, this.port);

  final String hostname;
  final int port;

  /// An allowlist entry may contain only an origin and an optional root slash.
  static HttpsOrigin? tryParse(String value) => _parse(value, originOnly: true);

  /// Paths and queries on requests do not affect origin identity.
  static HttpsOrigin? forRequest(String value) =>
      _parse(value, originOnly: false);

  static HttpsOrigin? _parse(String value, {required bool originOnly}) {
    // Inspect the raw authority before Uri can normalise escapes or empty ports.
    if (value.runes.any((c) => c <= 32 || c == 127) || value.contains('\\')) {
      return null;
    }
    final match = RegExp(
      r'^https://([^/?#]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    if (originOnly) {
      final suffix = value.substring(match.end);
      if (suffix.isNotEmpty && suffix != '/') return null;
    }
    final authority = match.group(1)!;
    final hostPort = RegExp(r'^([A-Za-z0-9.-]+)(?::([0-9]+))?$')
        .firstMatch(authority);
    if (hostPort == null) return null;
    final host = hostPort.group(1)!.toLowerCase();
    if (!_validHost(host)) return null;
    final rawPort = hostPort.group(2);
    final port = rawPort == null ? 443 : int.tryParse(rawPort);
    if (port == null || port < 1 || port > 65535) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || uri.userInfo.isNotEmpty) {
      return null;
    }
    if (originOnly &&
        (uri.hasQuery ||
            uri.hasFragment ||
            (uri.path.isNotEmpty && uri.path != '/'))) {
      return null;
    }
    return HttpsOrigin._(host, port);
  }

  static bool _validHost(String host) {
    if (host.length > 253) return false;
    final labels = host.split('.');
    // Numeric-ending forms can be interpreted as IPv4 by browser URL parsers.
    final numericEnd = RegExp(r'^(?:[0-9]+|0x[0-9a-f]*)$')
        .hasMatch(labels.last);
    if (numericEnd) {
      return labels.length == 4 &&
          labels.every((part) {
            if (!RegExp(r'^(?:0|[1-9][0-9]{0,2})$').hasMatch(part)) {
              return false;
            }
            return int.parse(part) <= 255;
          });
    }
    return labels.every(
      (part) =>
          part.length <= 63 &&
          RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$').hasMatch(part),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HttpsOrigin && hostname == other.hostname && port == other.port;

  @override
  int get hashCode => Object.hash(hostname, port);

  @override
  String toString() => 'https://$hostname:$port';
}
