import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';

void main() {
  testWidgets('CircularCheckbox toggles value and calls onChanged', (tester) async {
    bool? changedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CircularCheckbox(
            value: false,
            onChanged: (v) => changedValue = v,
          ),
        ),
      ),
    );

    // Tap the circular area
    await tester.tap(find.byType(CircularCheckbox));
    await tester.pump();

    expect(changedValue, isTrue);
  });

  testWidgets('CircularCheckbox shows check icon when value is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CircularCheckbox(
            value: true,
            onChanged: null, // disabled callback is fine for rendering
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}

