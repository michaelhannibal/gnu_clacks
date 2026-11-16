import 'package:gnu_clacks_core/gnu_clacks_core.dart';

/// A pure policy demonstration. No transport, I/O or real memorials are involved.
void main() {
  final registry = MemorialRegistry([
    Memorial(
      id: 'fictional-alex',
      displayName: 'Alex Example',
      displayEnabled: true,
      networkApproved: true,
      networkName: 'Alex Example',
    ),
    Memorial(
      id: 'fictional-sam',
      displayName: 'Sam Example',
      displayEnabled: true,
    ),
  ]);
  final policy = HeaderPolicy(
    enabled: true,
    allowlistedOrigins: ['https://api.example.org'],
  );
  final decision = policy.evaluate(
    requestUrl: 'https://api.example.org/path',
    registry: registry,
  );
  // A URL/allowlist alone does not prove redirect safety. Adapters own that gate.
  if (decision.value != null ||
      !decision.diagnostics.contains(
        HeaderDiagnostic.unverifiedRedirectSafety,
      )) {
    throw StateError('Unverified transport must not generate a header.');
  }
}
