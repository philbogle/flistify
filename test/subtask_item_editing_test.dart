import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/subtask_item.dart';

void main() {
  group('SubtaskItem editing flows', () {
    testWidgets('onLocalTitleChanged called when server item not found', (tester) async {
      // We cannot mock Firestore here without additional dependencies.
      // This test focuses on verifying that when _updateSubitem runs and
      // the item is not found on the server, the onLocalTitleChanged callback
      // is invoked. We simulate this by providing an onLocalTitleChanged mock
      // and triggering an edit followed by focus loss (which calls _updateSubitem).

      String? lastLocalTitle;

      final item = Subitem(id: 'local-only', title: 'Original', completed: false);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SubtaskItem(
            subitem: item,
            listId: 'list-1',
            startInEditMode: true,
            onLocalTitleChanged: (t) => lastLocalTitle = t,
          ),
        ),
      ));

      // Change the text field value
      await tester.enterText(find.byType(TextField), 'Updated Title');
      await tester.pump();

      // Remove focus to trigger _updateSubitem
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Note: Without a fake Firestore snapshot, the transaction will no-op.
      // But since the server item is "not found", our widget should call the
      // provided onLocalTitleChanged callback.
      expect(lastLocalTitle, 'Updated Title');
    }, skip: true, // Enable after adding Firestore fakes/mocks to runTransaction and snapshot
    );
  });
}

