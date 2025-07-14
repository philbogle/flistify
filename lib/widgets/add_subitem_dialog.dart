
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSubitemDialog extends StatefulWidget {
  final String listId;

  const AddSubitemDialog({super.key, required this.listId});

  @override
  State<AddSubitemDialog> createState() => _AddSubitemDialogState();
}

class _AddSubitemDialogState extends State<AddSubitemDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSubitem() async {
    if (_controller.text.isNotEmpty) {
      final navigator = Navigator.of(context);
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.listId)
          .update({
        'subtasks': FieldValue.arrayUnion([
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'title': _controller.text,
            'completed': false,
          }
        ])
      });
      if (mounted) navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Subitem'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Subitem Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addSubitem,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
