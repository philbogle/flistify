
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanListDialog extends StatelessWidget {
  const ScanListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan a List'),
      content: const Text('Scan a list from text, handwriting, or objects.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          child: const Text('Camera'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          child: const Text('Gallery'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Close the dialog
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
