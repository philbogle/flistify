import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/subtask_item.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';

void main() {
  group('SubtaskItem', () {
    testWidgets('starts in edit mode when startInEditMode=true and updates Firestore on submit', (tester) async {
      final firestore = FakeFirebaseFirestore();
      // Seed a list document with one subtask entry
      final listRef = firestore.collection('tasks').doc('list1');
      await listRef.set({
        'title': 'Test List',
        'subtasks': [
          {
            'id': 's1',
            'title': '',
            'completed': false,
            'isHeader': false,
          }
        ],
      });

      final subitem = Subitem(id: 's1', title: '', completed: false, isHeader: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskItem(
              subitem: subitem,
              listId: 'list1',
              startInEditMode: true,
              firestore: firestore,
            ),
          ),
        ),
      );

      // Should render a TextField initially
      expect(find.byType(TextField), findsOneWidget);

      // Enter text and submit
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Firestore should now have the updated title
      final snap = await listRef.get();
      final subtasks = List.from(snap.data()!['subtasks']);
      expect(subtasks.firstWhere((m) => m['id'] == 's1')['title'], 'Milk');

      // Widget should exit edit mode
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('tapping checkbox updates completed state optimistically and in Firestore', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final listRef = firestore.collection('tasks').doc('list2');
      await listRef.set({
        'title': 'Test List',
        'subtasks': [
          {'id': 's2', 'title': 'Eggs', 'completed': false, 'isHeader': false}
        ],
      });

      final subitem = Subitem(id: 's2', title: 'Eggs', completed: false, isHeader: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskItem(
              subitem: subitem,
              listId: 'list2',
              firestore: firestore,
            ),
          ),
        ),
      );

      // Tap the custom CircularCheckbox
      await tester.tap(find.byType(CircularCheckbox));
      await tester.pump();

      final snap = await listRef.get();
      final subtasks = List.from(snap.data()!['subtasks']);
      expect(subtasks.firstWhere((m) => m['id'] == 's2')['completed'], true);
    });

    testWidgets('empty input triggers onDelete callback', (tester) async {
      bool deleted = false;
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('tasks').doc('list3').set({
        'title': 'Test List',
        'subtasks': [
          {'id': 's3', 'title': 'Temp', 'completed': false, 'isHeader': false}
        ],
      });

      final subitem = Subitem(id: 's3', title: 'Temp', completed: false, isHeader: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskItem(
              subitem: subitem,
              listId: 'list3',
              firestore: firestore,
              startInEditMode: true,
              onDelete: () { deleted = true; },
            ),
          ),
        ),
      );

      // Clear text and submit
      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}

