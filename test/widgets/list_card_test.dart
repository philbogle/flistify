import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/list.dart' as model;
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/list_card.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  testWidgets('ListCard checkbox triggers onCompleted without navigation', (tester) async {
    bool? completed;

    final list = model.ListModel(
      id: 'l1',
      title: 'Groceries',
      completed: false,
      subitems: [
        Subitem(id: 'a', title: 'Milk', completed: false),
        Subitem(id: 'b', title: 'Eggs', completed: true),
      ],
      createdAt: Timestamp.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListCard(
            list: list,
            onCompleted: (v) { completed = v; },
          ),
        ),
      ),
    );

    // Tap only the CircularCheckbox inside the ListTile to trigger onCompleted
    final tile = find.byType(ListTile).first;
    final checkbox = find.descendant(of: tile, matching: find.byType(CircularCheckbox));
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox);
    await tester.pump();
    // Wait for the card's completion animation to finish before callback fires
    await tester.pump(const Duration(milliseconds: 400));

    expect(completed, isTrue);
  });
}

