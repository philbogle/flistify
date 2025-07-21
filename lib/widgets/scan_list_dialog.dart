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
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}