import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mymoney_ug/widgets/theme.dart';

void main() {
  testWidgets('theme builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: const Scaffold(body: Text('MyMoney UG'))),
    );
    expect(find.text('MyMoney UG'), findsOneWidget);
  });
}
