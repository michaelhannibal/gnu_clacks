import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_clacks_flutter/gnu_clacks_flutter.dart';

Widget host(Widget child, {bool reduce = false, bool ticker = true}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          disableAnimations: reduce,
        ),
        child: TickerMode(
          enabled: ticker,
          child: Scaffold(body: child),
        ),
      ),
    );

void main() {
  testWidgets(
    'reduced motion and explicit static mode schedule no ticking frames',
    (tester) async {
      for (final widget in [
        host(const ClacksSignal(), reduce: true),
        host(const ClacksSignal(animate: false)),
        host(const ClacksSignal(active: false)),
        host(const ClacksSignal(), ticker: false),
      ]) {
        await tester.pumpWidget(widget);
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);

        final semantics = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel('Symbolic Clacks signal. Their names live on.'),
          findsOneWidget,
        );
        semantics.dispose();
      }
    },
  );

  testWidgets('motion runs only when visible, and user pause/resume works', (
    tester,
  ) async {
    await tester.pumpWidget(host(const ClacksSignal()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.tap(find.text('Pause motion'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tap(find.text('Resume motion'));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'offscreen signals are static and resume on scroll into the viewport',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            controller: controller,
            child: const Column(
              children: [
                SizedBox(height: 900),
                ClacksSignal(),
                SizedBox(height: 900),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      controller.jumpTo(800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      controller.jumpTo(1200);
      await tester.pump();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'app lifecycle and reduced-motion changes override running animation',
    (tester) async {
      await tester.pumpWidget(host(const ClacksSignal()));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(host(const ClacksSignal(), reduce: true));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
  testWidgets(
    'Offstage and TickerMode changes stop frames and resume when revealed',
    (tester) async {
      late StateSetter update;
      var hidden = false;
      var ticker = true;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Offstage(
                offstage: hidden,
                child: TickerMode(enabled: ticker, child: const ClacksSignal()),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      update(() => hidden = true);
      await tester.pump();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      update(() => hidden = false);
      await tester.pump();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      update(() => ticker = false);
      await tester.pump();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  int laidOut(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('clacks-received')),
    );
    return (text.textSpan! as TextSpan).children!.length;
  }

  int visible(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('clacks-received')),
    );
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    return spans.where((span) => span.style?.color?.a != 0).length;
  }

  int? sending(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('clacks-source')),
    );
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    final index = spans.indexWhere(
      (span) => span.style?.fontWeight == FontWeight.bold,
    );
    return index < 0 ? null : index;
  }

  testWidgets('a message is relayed tower to tower and respelled in order', (
    tester,
  ) async {
    // Default period 4 s across 3 towers: one step every 1333 ms.
    const step = Duration(milliseconds: 1333);
    await tester.pumpWidget(host(const ClacksSignal(message: 'Ann')));
    await tester.pump();
    // Sample mid-step, clear of the boundaries.
    await tester.pump(const Duration(milliseconds: 600));
    // A, n, n, then the END signal.
    expect(laidOut(tester), 4);
    expect(visible(tester), 0);
    expect(sending(tester), 0);

    await tester.pump(step);
    expect(sending(tester), 1);
    expect(visible(tester), 0);

    // Step 2: the first letter reaches the third tower and is printed.
    await tester.pump(step);
    expect(sending(tester), 2);
    expect(visible(tester), 1);

    // Step 3: END enters the first tower.
    await tester.pump(step);
    expect(sending(tester), 3);
    expect(visible(tester), 2);

    await tester.pump(step);
    expect(sending(tester), isNull);
    expect(visible(tester), 3);

    // Step 5: END arrives and is printed last.
    await tester.pump(step);
    expect(visible(tester), 4);

    // After the hold, the cycle restarts with nothing printed.
    await tester.pump(step * 4);
    expect(visible(tester), 0);
    expect(sending(tester), 0);
  });

  testWidgets('static relay shows the whole name and one label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const ClacksSignal(message: 'Ann Smith', animate: false)),
    );
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    // Every character plus END.
    expect(visible(tester), 'Ann Smith'.length + 1);
    final received = tester.widget<Text>(
      find.byKey(const ValueKey('clacks-received')),
    );
    expect(received.textSpan!.toPlainText(), 'Ann Smith\u00a0END');
    expect(sending(tester), isNull);
    expect(
      find.bySemanticsLabel(
        'Clacks towers sending Ann Smith letter by letter, '
        'then the end signal. Their names live on.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('relay stacks on narrow layouts without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClacksSignal(
            message: 'Bartholomew Montgomery-Featherstonehaugh',
            animate: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final source = tester.getRect(find.byKey(const ValueKey('clacks-source')));
    final received = tester.getRect(
      find.byKey(const ValueKey('clacks-received')),
    );
    expect(received.top, greaterThan(source.bottom));
  });

  testWidgets('accessibility services alone do not stop motion', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            accessibleNavigation: true,
          ),
          child: const Scaffold(body: ClacksSignal(message: 'Ann')),
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(find.text('Pause motion'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Clacks towers sending Ann letter by letter, then the end signal. '
        'Their names live on.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
