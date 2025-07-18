
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/constants.dart';

class ShareListDialog extends StatelessWidget {
  final ListModel list;

  const ShareListDialog({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final shareLink = '$baseUrl/share/${list.shareId}';
    return AlertDialog(
      title: const Text('Share List'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Anyone with this link can view and edit this list. Do not share it with anyone you do not trust.'),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: shareLink),
            readOnly: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Share Link',
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: shareLink));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
          icon: const Icon(Icons.content_copy),
          label: const Text('Copy Link'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
