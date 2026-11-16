import 'dart:convert';

import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:test/test.dart';

const approved = 'https://api.example.org';
Memorial name(
  String alias, {
  String? id,
  int? order,
  bool display = false,
  bool network = true,
}) => Memorial(
  id: id ?? alias,
  displayName: 'Display only',
  networkName: alias,
  sortOrder: order,
  displayEnabled: display,
  networkApproved: network,
);
MemorialRegistry registry(Iterable<Memorial> entries) =>
    MemorialRegistry(entries);
HeaderPolicy policy({
  int budget = 512,
  Iterable<String> origins = const [approved],
}) => HeaderPolicy(
  enabled: true,
  allowlistedOrigins: origins,
  maxHeaderValueBytes: budget,
);
HeaderDecision decide(
  HeaderPolicy policy,
  Iterable<Memorial> entries, {
  String url = approved,
}) => policy.evaluate(
  requestUrl: url,
  registry: registry(entries),
  redirectSafetyVerified: true,
);

void main() {
  test('policy and transport controls default off independently', () {
    final entries = registry([name('Alex')]);
    expect(
      HeaderPolicy().evaluate(requestUrl: approved, registry: entries).value,
      isNull,
    );
    expect(
      decide(HeaderPolicy(allowlistedOrigins: [approved]), [
        name('Alex'),
      ]).diagnostics,
      contains(HeaderDiagnostic.disabled),
    );
    expect(decide(HeaderPolicy(enabled: true), [name('Alex')]).value, isNull);
    final unproven = policy().evaluate(requestUrl: approved, registry: entries);
    expect(unproven.value, isNull);
    expect(unproven.diagnostics, {HeaderDiagnostic.unverifiedRedirectSafety});
  });

  test(
    'visibility never approves transmission; hidden approved names can qualify',
    () {
      final decision = decide(policy(), [
        name('Visible Private', display: true, network: false),
        name('Hidden Approved'),
        Memorial(
          id: 'missing',
          displayName: '山田',
          displayEnabled: true,
          networkApproved: true,
        ),
      ]);
      expect(decision.value, 'GNU Hidden Approved');
      expect(
        decision.diagnostics,
        contains(HeaderDiagnostic.invalidNetworkName),
      );
      expect(decision.value, isNot(contains('山田')));
      expect(decision.value, isNot(contains('Visible')));
    },
  );

  test(
    'no display metadata is included and explicit punctuation is retained',
    () {
      final entry = Memorial(
        id: 'PRIVATE-ID',
        displayName: 'Private Display',
        networkName: "O'Neil-Smith Jr.",
        networkApproved: true,
        dedication: 'PRIVATE-DEDICATION',
        birthDate: PartialDate(1900),
        imageAsset: 'private/image.png',
        imageAltText: 'PRIVATE-ALT',
        imageAttribution: AssetAttribution(
          creator: 'PRIVATE',
          source: 'PRIVATE',
          licence: 'PRIVATE',
        ),
      );
      expect(decide(policy(), [entry]).value, "GNU O'Neil-Smith Jr.");
    },
  );

  test('sorts independent of input order, deduplicates normalised aliases case-sensitively', () {
    final entries = [
      name('Sam Example'),
      name(' Alex  Example ', id: 'a'),
      name('Alex Example', id: 'duplicate'),
      name('alex', id: 'lower'),
      name('Alex', id: 'upper'),
    ];
    const expected = 'GNU Alex, GNU Alex Example, GNU Sam Example, GNU alex';
    expect(decide(policy(), entries).value, expected);
    expect(decide(policy(), entries.reversed).value, expected);
    expect(
      decide(policy(), [
        name('Alex Example', order: 2),
        name('Sam Example', order: 1),
      ]).value,
      'GNU Sam Example, GNU Alex Example',
    );
    expect(
      decide(policy(), [
        name('Z', order: -1),
        name('A'),
        name('B', order: 0),
      ]).value,
      'GNU Z, GNU B, GNU A',
    );
  });

  test('wire values honour exact byte boundaries and continue after oversized entries', () {
    final entries = [name('Alex Example'), name('Sam Example')];
    expect(
      decide(policy(), entries).value,
      'GNU Alex Example, GNU Sam Example',
    );
    expect(ascii.encode(decide(policy(), entries).value!), hasLength(33));
    expect(decide(policy(budget: 15), [entries.first]).value, isNull);
    expect(
      decide(policy(budget: 16), [entries.first]).value,
      'GNU Alex Example',
    );
    expect(decide(policy(budget: 32), entries).value, 'GNU Alex Example');
    expect(
      decide(policy(budget: 33), entries).value,
      'GNU Alex Example, GNU Sam Example',
    );
    final skip = decide(policy(budget: 5), [
      name('AAAA', order: 1),
      name('B', order: 2),
    ]);
    expect(skip.value, 'GNU B');
    expect(skip.diagnostics, contains(HeaderDiagnostic.byteBudgetExceeded));
    expect(decide(policy(budget: 1), [name('A')]).value, isNull);
    expect(
      decide(policy(budget: 1024), [name('A' * 1020)]).value!.length,
      1024,
    );
    expect(decide(policy(), [name('A' * 509)]).value, isNull);
  });

  test('every byte budget respects the limit without truncating or splitting names', () {
    final entries = [
      name('Alex Example'),
      name('Sam Example'),
      name('B', order: 3),
    ];
    for (var budget = 1; budget <= 1024; budget++) {
      final decision = decide(policy(budget: budget), entries);
      if (decision.value != null) {
        expect(ascii.encode(decision.value!).length, lessThanOrEqualTo(budget));
        expect(
          decision.value!.split(', ').toSet(),
          everyElement(isIn(['GNU Alex Example', 'GNU Sam Example', 'GNU B'])),
        );
      }
    }
  });

  test('invalid configurations fail closed rather than allowing partial allowlists', () {
    for (final budget in [-1, 0, 1025]) {
      expect(decide(policy(budget: budget), [name('Alex')]).diagnostics, {
        HeaderDiagnostic.invalidConfiguration,
      });
    }
    expect(
      decide(policy(origins: [approved, 'http://other.org']), [
        name('Alex'),
      ]).value,
      isNull,
    );
    final source = [approved];
    final independent = policy(origins: source);
    source.clear();
    expect(decide(independent, [name('Alex')]).value, 'GNU Alex');
    expect(
      () => independent.allowlistedOrigins.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'exact origin matching and re-evaluation on every simulated redirect hop',
    () {
      final p = policy();
      final entries = [name('Alex')];
      expect(
        decide(p, entries, url: 'https://API.EXAMPLE.ORG:443/path?q=1').value,
        'GNU Alex',
      );
      for (final target in [
        'http://api.example.org',
        'https://api.example.org:444',
        'https://sub.api.example.org',
        'https://api.example.org.evil.tld',
        'https://other.org',
      ]) {
        expect(decide(p, entries, url: target).value, isNull);
      }
      final relative = Uri.parse('$approved/start')
          .resolve('../next')
          .toString();
      expect(decide(p, entries, url: relative).value, 'GNU Alex');
      expect(decide(p, entries, url: 'https://other.org').value, isNull);
      expect(
        decide(
          policy(origins: [approved, 'https://other.org']),
          entries,
          url: 'https://other.org',
        ).value,
        'GNU Alex',
      );
      // The adapter must remove its previous generated value before re-evaluation.
      expect(decide(p, entries).value, 'GNU Alex');
    },
  );

  test('host field detection is case-insensitive and avoids inspecting or mutating values', () {
    final headers = {
      'x-cLaCkS-oVeRhEaD': 'host value\r\nnot ours',
      'Authorization': 'secret',
    };
    final before = Map<String, String>.of(headers);
    final p = policy();
    final entryRegistry = registry([name('Alex')]);
    for (final url in [approved, 'https://unapproved.org']) {
      final result = p.evaluate(
        requestUrl: url,
        registry: entryRegistry,
        existingHeaderNames: headers.keys,
        redirectSafetyVerified: true,
      );
      expect(result.value, isNull);
      expect(result.diagnostics, {HeaderDiagnostic.existingHeader});
      expect(headers, before);
    }
    final generated = decide(p, [name('Alex')]).value!;
    headers.clear();
    headers[HeaderPolicy.headerName] = generated;
    expect(
      p
          .evaluate(
            requestUrl: approved,
            registry: entryRegistry,
            existingHeaderNames: headers.keys,
            redirectSafetyVerified: true,
          )
          .value,
      isNull,
    );
    expect(headers.values.single, generated);
  });

  test(
    'multiple policies remain independent and diagnostics contain only codes',
    () {
      final a = policy();
      final b = policy(origins: ['https://other.org']);
      expect(decide(a, [name('SECRET')]).value, 'GNU SECRET');
      expect(decide(b, [name('SECRET')]).value, isNull);
      final result = decide(a, [name('SECRET\nINJECTION', id: 'safe-id')]);
      expect(result.value, isNull);
      expect(result.diagnostics.toString(), isNot(contains('SECRET')));
      expect(() => result.diagnostics.clear(), throwsUnsupportedError);
      expect(decide(a, []).diagnostics, {HeaderDiagnostic.noEligibleNames});
    },
  );

  test(
    'rejects every control/non-ASCII byte before whitespace normalisation',
    () {
      for (var c = 0; c <= 255; c++) {
        if (c < 32 || c >= 127) {
          final alias = '${String.fromCharCode(c)}Alex';
          expect(normaliseNetworkName(alias), isNull, reason: 'Code $c');
          expect(decide(policy(), [name(alias, id: 'entry')]).value, isNull);
        }
      }
      for (final alias in [
        '',
        ' ',
        "'.-",
        'A,B',
        'A"B',
        'A\\B',
        'A:B',
        'A;B',
        'A_B',
        'Renée',
        '山田',
        'A😀',
      ]) {
        expect(normaliseNetworkName(alias), isNull);
      }
      expect(normaliseNetworkName(' Alex  Example '), 'Alex Example');
      expect(normaliseNetworkName("O'Neil-Smith Jr."), "O'Neil-Smith Jr.");
    },
  );
}
