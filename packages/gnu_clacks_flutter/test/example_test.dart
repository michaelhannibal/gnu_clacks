import 'package:flutter_test/flutter_test.dart';

import '../example/gnu_clacks_flutter_example.dart' as example;

void main() {
  testWidgets(
    'public visual-only example renders with no active signal ticker',
    (tester) async {
      await tester.pumpWidget(example.createTributeApp());
      await tester.pumpAndSettle();
      expect(find.text('Alex Example'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
