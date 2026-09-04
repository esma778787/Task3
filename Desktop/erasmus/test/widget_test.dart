import 'package:flutter_test/flutter_test.dart';

import 'package:erasmus_simulasyon/main.dart';

void main() {
  testWidgets('App shows information screen on start', (WidgetTester tester) async {
    await tester.pumpWidget(const ErasmusApp());

    // Allow frames to settle
    await tester.pumpAndSettle();

    // Information screen should contain the title
    expect(find.textContaining('Bilgi Merkezi'), findsOneWidget);
  });
}
