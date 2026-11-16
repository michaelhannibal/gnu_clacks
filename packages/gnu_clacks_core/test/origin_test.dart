import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'origin equality includes normalised scheme/host and effective port',
    () {
      final a = HttpsOrigin.tryParse('https://api.example.org')!;
      final b = HttpsOrigin.tryParse('HTTPS://API.EXAMPLE.ORG:443/')!;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), 'https://api.example.org:443');
      expect(a.hostname, 'api.example.org');
      expect(a.port, 443);
      expect(a, isNot(HttpsOrigin.tryParse('https://api.example.org:444')));
      expect(
        HttpsOrigin.forRequest('https://api.example.org/path?q=1#part'),
        a,
      );
    },
  );

  for (final value in [
    'https://example.org/path',
    'https://example.org/.',
    'https://example.org/a/..',
    'https://example.org/%2e',
    'https://example.org?',
    'https://example.org#',
    'https://example.org/?q=1',
  ]) {
    test('allowlist excludes non-origin components: $value', () {
      expect(HttpsOrigin.tryParse(value), isNull);
    });
  }

  for (final value in [
    '',
    '/relative',
    '//example.org',
    'http://example.org',
    'ftp://example.org',
    'https:example.org',
    'https:///example.org',
    ' https://example.org',
    'https://example.org\n',
    'https://example.org\\evil',
    'https://user@example.org',
    'https://@example.org',
    'https://example.org:',
    'https://example.org:0',
    'https://example.org:65536',
    'https://example.org:-1',
    'https://example.org:abc',
    'https://example.org:99999999999999999999999999999',
    'https://example.org.',
    'https://.example.org',
    'https://a..org',
    'https://-a.org',
    'https://a-.org',
    'https://a_b.org',
    'https://*.org',
    'https://%65xample.org',
    'https://éxample.org',
    'https://[::1]',
    'https://127.1',
    'https://2130706433',
    'https://0x7f000001',
    'https://0x',
    'https://a.0x',
    'https://0177.0.0.1',
    'https://127.00.0.1',
    'https://256.0.0.1',
    'https://a.123',
    'https://a.0xff',
    'https://${'a' * 64}.org',
    'https://${List.filled(5, 'a' * 60).join('.')}',
  ]) {
    test('rejects unsupported/ambiguous authority: $value', () {
      expect(HttpsOrigin.tryParse(value), isNull);
      expect(HttpsOrigin.forRequest(value), isNull);
    });
  }

  for (final value in [
    'https://127.0.0.1',
    'https://0.0.0.0:65535',
    'https://localhost:1',
    'https://xn--bcher-kva.example',
    'https://a-b.org',
  ]) {
    test('accepts supported explicit host profile: $value', () {
      expect(HttpsOrigin.tryParse(value), isNotNull);
    });
  }
}
