
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/constants.dart';

/// A dialog that displays a shareable link to a list.
class ShareListDialog extends StatefulWidget {
  final ListModel list;

  const ShareListDialog({super.key, required this.list});

  @override
  State<ShareListDialog> createState() => _ShareListDialogState();
}

class _ShareListDialogState extends State<ShareListDialog> {
  String? _shareId;

  @override
  void initState() {
    super.initState();
    _shareId = widget.list.shareId;
    if (_shareId == null) {
      _generateShareId();
    }
  }

  void _generateShareId() async {
    final newShareId = FirebaseFirestore.instance.collection('dummy').doc().id;
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.list.id)
        .update({'shareId': newShareId});
    setState(() {
      _shareId = newShareId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shareLink = _shareId == null
        ? 'Generating link...'
        : "$webClientBaseUrl/share/$_shareId";
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
