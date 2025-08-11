import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/widgets/confirm_delete_dialog.dart';

void main() {
  testWidgets('ConfirmDeleteDialog returns true when Delete pressed', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ConfirmDeleteDialog(listName: 'Groceries'),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Open the dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap Delete
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('ConfirmDeleteDialog shows list name in message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConfirmDeleteDialog(listName: 'Weekend Trip'),
        ),
      ),
    );

    expect(
      find.textContaining('Weekend Trip'),
      findsOneWidget,
    );
  });
}

