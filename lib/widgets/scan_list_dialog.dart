import 'package:flutter/material.dart';

class ScanListDialog extends StatelessWidget {
  const ScanListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan List'),
      content: const Text('Please use the camera to scan your list.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
