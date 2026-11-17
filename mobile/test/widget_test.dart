import 'package:flutter_test/flutter_test.dart';

import 'package:andon_app/main.dart';

void main() {
  testWidgets('ANDON app builds', (tester) async {
    await tester.pumpWidget(const AndonApp());
    expect(find.text('ANDON'), findsOneWidget);
  });
}
