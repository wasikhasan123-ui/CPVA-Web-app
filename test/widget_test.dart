import 'package:flutter_test/flutter_test.dart';

import 'package:cpva_app/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const CpvaApp());
  });
}
