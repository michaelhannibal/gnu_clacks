import 'models.dart';
import 'origin.dart';

/// Fixed codes only: no memorial IDs, names, origins or header values.
enum HeaderDiagnostic {
  disabled,
  existingHeader,
  invalidConfiguration,
  unverifiedRedirectSafety,
  unapprovedOrigin,
  invalidNetworkName,
  byteBudgetExceeded,
  noEligibleNames,
}

/// A generated value to add, or null meaning leave the host request unchanged.
///
/// Never log [value]. Only [diagnostics] are suitable for non-sensitive logging.
final class HeaderDecision {
  HeaderDecision._(this.value, Iterable<HeaderDiagnostic> diagnostics)
    : diagnostics = Set<HeaderDiagnostic>.unmodifiable(diagnostics);

  final String? value;
  final Set<HeaderDiagnostic> diagnostics;
}

/// Pure, default-off policy. This object never sends or mutates a request.
///
/// Any invalid allowlist entry disables all generated transmission. Adapters
/// must preserve host headers, track/remove stale generated headers on redirects,
/// and re-evaluate each destination. No adapter is implemented by this package.
final class HeaderPolicy {
  factory HeaderPolicy({
    bool enabled = false,
    Iterable<String> allowlistedOrigins = const [],
    int maxHeaderValueBytes = 512,
  }) {
    final origins = <HttpsOrigin>{};
    var valid = maxHeaderValueBytes >= 1 && maxHeaderValueBytes <= 1024;
    for (final entry in allowlistedOrigins) {
      final origin = HttpsOrigin.tryParse(entry);
      if (origin == null) {
        valid = false;
      } else {
        origins.add(origin);
      }
    }
    return HeaderPolicy._(
      enabled,
      maxHeaderValueBytes,
      Set<HttpsOrigin>.unmodifiable(origins),
      valid,
    );
  }

  const HeaderPolicy._(
    this.enabled,
    this.maxHeaderValueBytes,
    this.allowlistedOrigins,
    this.isValid,
  );

  static const headerName = 'X-Clacks-Overhead';
  final bool enabled;
  final int maxHeaderValueBytes;
  final Set<HttpsOrigin> allowlistedOrigins;
  final bool isValid;

  /// [redirectSafetyVerified] is an assertion by a proven transport integration,
  /// not permission to trust a server promise or skip redirect checks. It defaults
  /// off. Existing field names are sufficient; Core never needs host values.
  HeaderDecision evaluate({
    required String requestUrl,
    required MemorialRegistry registry,
    bool redirectSafetyVerified = false,
    Iterable<String> existingHeaderNames = const [],
  }) {
    HeaderDecision omit(HeaderDiagnostic code) =>
        HeaderDecision._(null, [code]);
    if (existingHeaderNames.any(
      (name) => name.toLowerCase() == headerName.toLowerCase(),
    )) {
      return omit(HeaderDiagnostic.existingHeader);
    }
    if (!enabled) return omit(HeaderDiagnostic.disabled);
    if (!isValid) return omit(HeaderDiagnostic.invalidConfiguration);
    if (!redirectSafetyVerified) {
      return omit(HeaderDiagnostic.unverifiedRedirectSafety);
    }
    final origin = HttpsOrigin.forRequest(requestUrl);
    if (origin == null || !allowlistedOrigins.contains(origin)) {
      return omit(HeaderDiagnostic.unapprovedOrigin);
    }
    final diagnostics = <HeaderDiagnostic>{};
    final candidates = <({Memorial entry, String alias})>[];
    for (final entry in registry.entries) {
      if (!entry.networkApproved) continue;
      final alias = normaliseNetworkName(entry.networkName);
      if (alias == null) {
        diagnostics.add(HeaderDiagnostic.invalidNetworkName);
      } else {
        candidates.add((entry: entry, alias: alias));
      }
    }
    candidates.sort((a, b) {
      final order = compareOrder(a.entry.sortOrder, b.entry.sortOrder);
      if (order != 0) return order;
      final alias = compareScalars(a.alias, b.alias);
      return alias != 0 ? alias : compareScalars(a.entry.id, b.entry.id);
    });
    final seen = <String>{};
    final segments = <String>[];
    var bytes = 0;
    for (final candidate in candidates) {
      if (!seen.add(candidate.alias)) continue;
      final segment = 'GNU ${candidate.alias}';
      final cost = segment.length + (segments.isEmpty ? 0 : 2);
      if (bytes + cost > maxHeaderValueBytes) {
        diagnostics.add(HeaderDiagnostic.byteBudgetExceeded);
        continue;
      }
      segments.add(segment);
      bytes += cost;
    }
    if (segments.isEmpty) diagnostics.add(HeaderDiagnostic.noEligibleNames);
    return HeaderDecision._(
      segments.isEmpty ? null : segments.join(', '),
      diagnostics,
    );
  }
}

/// Validates before collapsing ASCII spaces; never transliterates display names.
/// Returns null for an absent, unsafe or empty alias.
String? normaliseNetworkName(String? value) {
  if (value == null || value.codeUnits.any((c) => c < 32 || c >= 127)) {
    return null;
  }
  if (!RegExp(r"^[A-Za-z0-9 '.-]*$").hasMatch(value)) return null;
  final normalised = value.trim().replaceAll(RegExp(' +'), ' ');
  return RegExp('[A-Za-z0-9]').hasMatch(normalised) ? normalised : null;
}
