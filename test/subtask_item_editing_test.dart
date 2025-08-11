import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/subtask_item.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('SubtaskItem editing flows', () {
    testWidgets('onLocalTitleChanged called when server item not found', (tester) async {
      String? lastLocalTitle;
      final fake = FakeFirebaseFirestore();
      // Seed a tasks/list-1 doc WITHOUT our item's id so index == -1 path triggers
      await fake.collection('tasks').doc('list-1').set({
        'subtasks': [
          {'id': 'other', 'title': 'Other', 'completed': false, 'isHeader': false},
        ],
      });

      final item = Subitem(id: 'local-only', title: 'Original', completed: false);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SubtaskItem(
            subitem: item,
            listId: 'list-1',
            startInEditMode: true,
            onLocalTitleChanged: (t) => lastLocalTitle = t,
            firestore: fake,
          ),
        ),
      ));

      // Change the text field value
      await tester.enterText(find.byType(TextField), 'Updated Title');
      await tester.pump();

      // Remove focus to trigger _updateSubitem
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(lastLocalTitle, 'Updated Title');

      // Also assert Firestore did not update any existing subtask's title
      final snap = await fake.collection('tasks').doc('list-1').get();
      final subtasks = List<Map<String, dynamic>>.from(snap.data()!['subtasks'] as List);
      expect(subtasks.any((e) => e['id'] == 'local-only'), isFalse);
    });
  });
}

