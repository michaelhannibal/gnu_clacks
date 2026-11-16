// Plain Dart entry point: no Flutter imports or UI runtime.
import 'dart:convert';
import 'dart:io';

import 'package:gnu_clacks_example/demo_network.dart';
import 'package:gnu_clacks_example/memorials.dart';

Future<void> main(List<String> args) async {
  final origin =
      args
          .where((s) => s.startsWith('--origin='))
          .firstOrNull
          ?.substring('--origin='.length) ??
      '';
  if (args.contains('--help') || origin.isEmpty) {
    stdout.writeln(
      'Local test only: dart run bin/header_only.dart --origin=https://localhost:8443 [--enable-header] [--dio]',
    );
    return;
  }
  final demo = DemoNetwork(registry: exampleRegistry, origin: origin);
  if (!demo.configured) {
    stderr.writeln('Only an explicit HTTPS localhost test origin is accepted.');
    exitCode = 64;
    return;
  }
  try {
    final enabled = args.contains('--enable-header');
    final result = args.contains('--dio')
        ? await demo.sendDio(enabled: enabled)
        : await demo.sendHttp(enabled: enabled);
    stdout.writeln(
      jsonEncode({
        'status': result.status,
        'receivedHeader': result.receivedHeader,
      }),
    );
  } catch (_) {
    stderr.writeln(
      'Local test failed. Check endpoint and certificate trust. No retry was made.',
    );
    exitCode = 1;
  }
}
