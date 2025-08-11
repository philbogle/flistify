import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/subtask_item.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('SubtaskItem Firestore interactions', () {
    testWidgets('checkbox toggle updates Firestore when item exists', (tester) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('tasks').doc('listA').set({
        'subtasks': [
          {'id': 'i1', 'title': 'Task', 'completed': false, 'isHeader': false},
        ],
      });
      final item = Subitem(id: 'i1', title: 'Task', completed: false);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SubtaskItem(subitem: item, listId: 'listA', firestore: fake),
        ),
      ));

      CircularCheckbox cb = tester.widget(find.byType(CircularCheckbox));
      expect(cb.value, isFalse);

      await tester.tap(find.byType(CircularCheckbox));
      await tester.pump();

      cb = tester.widget(find.byType(CircularCheckbox));
      expect(cb.value, isTrue);

      final snap = await fake.collection('tasks').doc('listA').get();
      final subtasks = List<Map<String, dynamic>>.from(snap.data()!['subtasks'] as List);
      expect(subtasks.firstWhere((e) => e['id'] == 'i1')['completed'], true);
    });

    testWidgets('editing title updates Firestore when item exists', (tester) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('tasks').doc('listB').set({
        'subtasks': [
          {'id': 'i2', 'title': 'Old', 'completed': false, 'isHeader': false},
        ],
      });
      final item = Subitem(id: 'i2', title: 'Old', completed: false);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SubtaskItem(
            subitem: item,
            listId: 'listB',
            firestore: fake,
            startInEditMode: true,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'New Title');
      await tester.pump();
      // Remove focus to trigger _updateSubitem
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      final snap = await fake.collection('tasks').doc('listB').get();
      final subtasks = List<Map<String, dynamic>>.from(snap.data()!['subtasks'] as List);
      expect(subtasks.firstWhere((e) => e['id'] == 'i2')['title'], 'New Title');
    });
  });
}
