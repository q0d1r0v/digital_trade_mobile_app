import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_trade_mobile_app/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton renders label and fires onPressed',
      (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Submit',
            onPressed: () => tapped++,
          ),
        ),
      ),
    );

    expect(find.text('Submit'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(tapped, 1);
  });
}
