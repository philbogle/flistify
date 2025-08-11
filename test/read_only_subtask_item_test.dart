import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/read_only_subtask_item.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore that always throws on runTransaction to test rollback behavior
class ThrowingFirestore extends FakeFirebaseFirestore {
  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction, {
    int? maxAttempts,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return Future<T>.error(Exception('boom'));
  }
}

void main() {
  group('ReadOnlySubtaskItem', () {
    testWidgets('renders header vs normal appropriately', (tester) async {
      final header = Subitem(id: 'h1', title: 'Header Title', completed: false, isHeader: true);
      final normal = Subitem(id: 'n1', title: 'Normal Title', completed: false);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ReadOnlySubtaskItem(subitem: header, listId: 'list1', firestore: null),
              ReadOnlySubtaskItem(subitem: normal, listId: 'list1', firestore: null),
            ],
          ),
        ),
      ));

      // Header shows bold text and no checkbox
      final headerText = find.text('Header Title');
      expect(headerText, findsOneWidget);
      expect(find.descendant(of: headerText, matching: find.byType(CircularCheckbox)), findsNothing);

      final textWidget = tester.widget<Text>(headerText);
      expect(textWidget.style?.fontWeight, FontWeight.bold);

      // Normal shows checkbox and formatted title
      expect(find.text('Normal Title'), findsOneWidget);
      expect(find.byType(CircularCheckbox), findsOneWidget);
    });

    testWidgets('checkbox interaction updates optimistic state locally and persists to firestore', (tester) async {
      final normal = Subitem(id: 'n1', title: 'Normal Title', completed: false);
      final fake = FakeFirebaseFirestore();
      // Seed firestore with a tasks/list1 doc containing our subtask
      await fake.collection('tasks').doc('list1').set({
        'subtasks': [
          {'id': 'n1', 'title': 'Normal Title', 'completed': false, 'isHeader': false},
        ],
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReadOnlySubtaskItem(subitem: normal, listId: 'list1', firestore: fake),
        ),
      ));

      // Initially unchecked
      CircularCheckbox cb = tester.widget(find.byType(CircularCheckbox));
      expect(cb.value, isFalse);

      // Tap the checkbox to check it
      await tester.tap(find.byType(CircularCheckbox));
      await tester.pump();

      cb = tester.widget(find.byType(CircularCheckbox));
      expect(cb.value, isTrue);

      // Verify Firestore was updated
      final snap = await fake.collection('tasks').doc('list1').get();
      final subtasks = List<Map<String, dynamic>>.from(snap.data()!['subtasks'] as List);
      expect(subtasks.firstWhere((e) => e['id'] == 'n1')['completed'], true);
    });
    testWidgets('unchecking persists to firestore when initially completed', (tester) async {
      final item = Subitem(id: 'n2', title: 'Done Item', completed: true);
      final fake = FakeFirebaseFirestore();
      await fake.collection('tasks').doc('list1').set({
        'subtasks': [
          {'id': 'n2', 'title': 'Done Item', 'completed': true, 'isHeader': false},
        ],
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReadOnlySubtaskItem(subitem: item, listId: 'list1', firestore: fake),
        ),
      ));

      CircularCheckbox cb = tester.widget(find.byType(CircularCheckbox));
      expect(cb.value, isTrue);

      await tester.tap(find.byType(CircularCheckbox));
      await tester.pump();

      cb = tester.widget(find.byType(CircularCheckbox));
      expect(cb.value, isFalse);

      final snap = await fake.collection('tasks').doc('list1').get();
      final subtasks = List<Map<String, dynamic>>.from(snap.data()!['subtasks'] as List);
      expect(subtasks.firstWhere((e) => e['id'] == 'n2')['completed'], false);
    });

    testWidgets('rollback on Firestore error restores optimistic state', (tester) async {
      final throwing = ThrowingFirestore();
      // Seed data (not strictly necessary since runTransaction will throw)
      await throwing.collection('tasks').doc('list1').set({
        'subtasks': [
          {'id': 'n3', 'title': 'Item', 'completed': false, 'isHeader': false},
        ],
      });

      final item = Subitem(id: 'n3', title: 'Item', completed: false);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReadOnlySubtaskItem(subitem: item, listId: 'list1', firestore: throwing),
        ),
      ));

      // Start unchecked, tap to check -> should optimistically flip to true then rollback to false on error
      await tester.tap(find.byType(CircularCheckbox));
      await tester.pump();

      // After error catch, widget should revert to original false
      final cb = tester.widget<CircularCheckbox>(find.byType(CircularCheckbox));
      expect(cb.value, isFalse);

      // Optionally verify a SnackBar was shown
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

