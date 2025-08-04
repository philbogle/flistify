
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/subtask_item.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';

void main() {
  testWidgets('SubtaskItem renders header correctly', (WidgetTester tester) async {
    // 1. Arrange
    final headerSubitem = Subitem(
      id: 'header1',
      title: 'This is a header',
      completed: false,
      isHeader: true,
    );

    // 2. Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubtaskItem(subitem: headerSubitem, listId: 'list1'),
        ),
      ),
    );

    // 3. Assert
    expect(find.text('THIS IS A HEADER'), findsOneWidget);
    expect(find.byType(CircularCheckbox), findsNothing);

    final textWidget = tester.widget<Text>(find.text('THIS IS A HEADER'));
    expect(textWidget.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('SubtaskItem renders normal item correctly', (WidgetTester tester) async {
    // 1. Arrange
    final normalSubitem = Subitem(
      id: 'item1',
      title: 'This is a normal item',
      completed: false,
      isHeader: false,
    );

    // 2. Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubtaskItem(subitem: normalSubitem, listId: 'list1'),
        ),
      ),
    );

    // 3. Assert
    expect(find.text('This is a normal item'), findsOneWidget);
    expect(find.byType(CircularCheckbox), findsOneWidget);

    final textWidget = tester.widget<Text>(find.text('This is a normal item'));
    expect(textWidget.style?.fontWeight, isNot(FontWeight.bold));
  });
}
