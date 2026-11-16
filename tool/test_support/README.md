# Test-only loopback fixtures

`localhost-cert.pem` and `localhost-key.pem` are public, self-signed loopback test data for native HTTPS integration tests. Never deploy them. Clients trust only the test certificate through their test configuration; adapter production code does not modify TLS trust.

The certificate covers localhost and 127.0.0.1 and was generated with OpenSSL for long-lived local test reproducibility. `loopback.dart` opens ephemeral loopback ports. `browser_server.dart` supplies hybrid test code for local browser CORS fixtures; it is not an application backend. No external service or user data is involved.

Run native/browser package tests from their package directory. Loopback binding may require sandbox approval. Browser tests require Chrome and keep certificate validation enabled.
