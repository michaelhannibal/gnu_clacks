import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

import 'demo_network.dart';
import 'memorials.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Roboto',
    ], await rootBundle.loadString('assets/fonts/Roboto_LICENSE.txt'));
  });
  runApp(const ClacksExampleApp());
}

enum DemoMode { visualOnly, headerOnly, fullTribute }

class ClacksExampleApp extends StatefulWidget {
  const ClacksExampleApp({super.key, this.network});
  final DemoNetwork? network;
  @override
  State<ClacksExampleApp> createState() => _ClacksExampleAppState();
}

class _ClacksExampleAppState extends State<ClacksExampleApp> {
  var _appearance = ClacksAppearance.classic;
  var _mode = DemoMode.visualOnly;
  var _animate = false;
  var _enabled = false;
  var _busy = false;
  DemoResponse? _result;
  String? _error;
  late final _network =
      widget.network ?? DemoNetwork(registry: exampleRegistry);

  @override
  Widget build(BuildContext context) {
    final tokens = ClacksTheme.appearance(_appearance, ThemeData());
    final scheme =
        ColorScheme.fromSeed(
          seedColor: tokens.accent,
          brightness: tokens.background.computeLuminance() < .5
              ? Brightness.dark
              : Brightness.light,
        ).copyWith(
          surface: tokens.background,
          onSurface: tokens.foreground,
          primary: tokens.accent,
          onPrimary: tokens.ink(tokens.accent),
          surfaceContainerLow: tokens.surface,
        );
    return MaterialApp(
      title: 'GNU Clacks · Local demonstration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        fontFamily: 'ExampleRoboto',
        extensions: [tokens],
        scaffoldBackgroundColor: tokens.background,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('GNU Clacks'),
            actions: [
              IconButton(
                tooltip: 'Privacy and credits',
                onPressed: () => _credits(context),
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1056),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A LIVING TRIBUTE',
                        style: TextStyle(letterSpacing: 4, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Their names live on.',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'An offline demonstration with fictional superhero memorials. Explore the tribute UI, inspect the header setup, or combine both.',
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final mode in DemoMode.values)
                            ChoiceChip(
                              label: Text(_modeName(mode)),
                              selected: _mode == mode,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() {
                                      _mode = mode;
                                      _result = null;
                                      _error = null;
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 240,
                            child: DropdownButtonFormField<ClacksAppearance>(
                              isExpanded: true,
                              initialValue: _appearance,
                              decoration: const InputDecoration(
                                labelText: 'Appearance',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final appearance
                                    in ClacksAppearance.values)
                                  DropdownMenuItem(
                                    value: appearance,
                                    child: Text(_appearanceName(appearance)),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _appearance = value);
                                }
                              },
                            ),
                          ),
                          if (_mode != DemoMode.headerOnly)
                            SizedBox(
                              width: 280,
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Allow symbolic motion'),
                                value: _animate,
                                onChanged: (value) =>
                                    setState(() => _animate = value),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_mode != DemoMode.headerOnly)
                        _panel(
                          context,
                          tokens,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A quiet place to remember',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Five superheroes who died on screen, original local illustrations, and a complete gallery and detail experience. Display eligibility is independent of network approval.',
                              ),
                              const SizedBox(height: 16),
                              ClacksSignal(animate: _animate),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => MemorialGallery(
                                      registry: exampleRegistry,
                                      appearance: _appearance,
                                      animate: _animate,
                                      onOpenCredits: () => _credits(context),
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.grid_view),
                                label: const Text('Open memorial gallery'),
                              ),
                              const SizedBox(height: 16),
                              MemorialBadge(
                                memorial: exampleRegistry.entries.first,
                              ),
                            ],
                          ),
                        ),
                      if (_mode != DemoMode.visualOnly) ...[
                        const SizedBox(height: 24),
                        _networkPanel(context, tokens),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Local content. No accounts, analytics or background requests.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        const ClacksLocalizations().nonAffiliation,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(
    BuildContext context,
    ClacksTheme tokens, {
    required Widget child,
  }) => Material(
    color: tokens.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: tokens.foreground.withValues(alpha: .2)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  Widget _networkPanel(BuildContext context, ClacksTheme tokens) => _panel(
    context,
    tokens,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A deliberate, local header test',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Only Tony Stark is developer-approved for transmission. The others remain visual-only. No request is made until you press a test button.',
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable the test header'),
          subtitle: const Text(
            'Starts off. This does not change memorial ownership or permissions.',
          ),
          value: _enabled,
          onChanged: _busy
              ? null
              : (value) => setState(() {
                  _enabled = value;
                  _result = null;
                }),
        ),
        const SizedBox(height: 12),
        Text(
          _network.configured ? 'Endpoint: ${_network.origin}/echo' : 'No test endpoint configured. This demonstration stays offline.',
        ),
        const SizedBox(height: 8),
        Text(
          kIsWeb
              ? 'Browser adapters omit generated headers. CORS errors remain visible; there is no bypass or hidden retry.'
              : 'The demonstration host explicitly uses no-follow requests. Adapters keep their normal redirect safeguards.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: !_network.configured || _busy
                  ? null
                  : () => _send(false),
              child: const Text('Send via HTTP'),
            ),
            OutlinedButton(
              onPressed: !_network.configured || _busy
                  ? null
                  : () => _send(true),
              child: const Text('Send via Dio'),
            ),
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Waiting for the local test endpoint…'),
          ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: SelectableText(
                'HTTP ${_result!.status}\nHeader observed by the test endpoint: ${_result!.receivedHeader ?? '(none)'}',
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(liveRegion: true, child: Text(_error!)),
          ),
        const SizedBox(height: 16),
        const Text(
          'Servers and proxies can log headers. GNU is a tribute, not a no-logging guarantee.',
        ),
      ],
    ),
  );

  Future<void> _send(bool dio) async {
    setState(() {
      _busy = true;
      _result = null;
      _error = null;
    });
    try {
      final response = dio
          ? await _network.sendDio(enabled: _enabled)
          : await _network.sendHttp(enabled: _enabled);
      if (mounted) setState(() => _result = response);
    } catch (_) {
      // Do not print transport errors, URLs or header values to host logs.
      if (mounted) {
        setState(
          () => _error = 'The local test failed. Check endpoint configuration, certificate trust and browser CORS. No retry was made.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _credits(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Privacy and credits'),
      content: const SingleChildScrollView(
        child: Text(
          'All names, dates and dedications in this app are fictional. Superhero names belong to their rights holders; this local demo is not affiliated with any studio or publisher. The forge, thread, dawn, pines and tower illustrations are original project artwork.\n\n'
          'MIT · Copyright 2026 Ydesignz. Roboto font notices are bundled in assets/fonts/Roboto_LICENSE.txt; Flutter dependency notices are available below.\n\n'
          'No analytics, accounts, remote image loading or automatic requests. Network tests require a developer-configured HTTPS localhost endpoint and a deliberate button press.\n\n'
          'Inspired by Terry Pratchett’s Going Postal. Not affiliated with Discworld or the Terry Pratchett estate.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'GNU Clacks example',
          ),
          child: const Text('Dependency licences'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

String _modeName(DemoMode mode) => switch (mode) {
  DemoMode.visualOnly => 'Visual-only',
  DemoMode.headerOnly => 'Header-only',
  DemoMode.fullTribute => 'Full tribute',
};
String _appearanceName(ClacksAppearance appearance) => switch (appearance) {
  ClacksAppearance.classic => 'Classic brass',
  ClacksAppearance.light => 'Soft light',
  ClacksAppearance.dark => 'Dark',
  ClacksAppearance.minimal => 'Minimal',
  ClacksAppearance.host => 'Host theme',
};
