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
}
