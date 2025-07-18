
import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String listName;

  const ConfirmDeleteDialog({super.key, required this.listName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete List?'),
      content: Text('Are you sure you want to delete the list "$listName"? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
