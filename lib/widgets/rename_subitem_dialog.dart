
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RenameSubitemDialog extends StatefulWidget {
  final String listId;
  final String subitemId;
  final String currentName;

  const RenameSubitemDialog({
    super.key,
    required this.listId,
    required this.subitemId,
    required this.currentName,
  });

  @override
  State<RenameSubitemDialog> createState() => _RenameSubitemDialogState();
}

class _RenameSubitemDialogState extends State<RenameSubitemDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _renameSubitem() async {
    if (_controller.text.isNotEmpty) {
      final navigator = Navigator.of(context);
      final listRef = FirebaseFirestore.instance.collection('tasks').doc(widget.listId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(listRef);
        if (!snapshot.exists) {
          throw Exception("List does not exist!");
        }

        final List<dynamic> subtasks =
            List<dynamic>.from(snapshot.data()!['subtasks'] ?? []);

        final int index =
            subtasks.indexWhere((task) => task['id'] == widget.subitemId);

        if (index != -1) {
          final Map<String, dynamic> subitemToUpdate =
              Map<String, dynamic>.from(subtasks[index]);
          subitemToUpdate['title'] = _controller.text;
          subtasks[index] = subitemToUpdate;
          transaction.update(listRef, {'subtasks': subtasks});
        }
      });

      if (mounted) navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Subitem'),
      content: TextField(
        controller: _controller,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _renameSubitem,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
