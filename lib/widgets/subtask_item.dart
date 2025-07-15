
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/subitem.dart';

class SubtaskItem extends StatefulWidget {
  final Subitem subitem;
  final String listId;
  final bool startInEditMode;
  final VoidCallback? onSubmitted;

  const SubtaskItem({
    super.key,
    required this.subitem,
    required this.listId,
    this.onSubmitted,
    this.startInEditMode = false,
  });

  @override
  State<SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends State<SubtaskItem> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.subitem.title);
    _isEditing = widget.startInEditMode;

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _updateSubitem();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSubitem() {
    if (_controller.text == widget.subitem.title) {
        if (mounted) setState(() => _isEditing = false);
        return; // No change, no need to update
    }

    final listRef = FirebaseFirestore.instance.collection('tasks').doc(widget.listId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(listRef);
      if (!snapshot.exists) return;

      final List<dynamic> subtasks = List<dynamic>.from(snapshot.data()!['subtasks'] ?? []);
      final int index = subtasks.indexWhere((task) => task['id'] == widget.subitem.id);

      if (index != -1) {
        final Map<String, dynamic> subitemToUpdate = Map<String, dynamic>.from(subtasks[index]);
        subitemToUpdate['title'] = _controller.text;
        subtasks[index] = subitemToUpdate;
        transaction.update(listRef, {'subtasks': subtasks});
      }
    });

    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
    
    widget.onSubmitted?.call();
  }

  void _handleCheckboxChanged(bool? value) {
    if (value == null) return;
    final listRef = FirebaseFirestore.instance.collection('tasks').doc(widget.listId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(listRef);
      if (!snapshot.exists) return;
      final List<dynamic> subtasks = List<dynamic>.from(snapshot.data()!['subtasks'] ?? []);
      final int index = subtasks.indexWhere((task) => task['id'] == widget.subitem.id);
      if (index != -1) {
        final Map<String, dynamic> subitemToUpdate = Map<String, dynamic>.from(subtasks[index]);
        subitemToUpdate['completed'] = value;
        subtasks[index] = subitemToUpdate;
        transaction.update(listRef, {'subtasks': subtasks});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: widget.subitem.completed,
        onChanged: _handleCheckboxChanged,
      ),
      title: _isEditing
          ? TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(hintText: 'Add item'),
              onSubmitted: (_) => _updateSubitem(),
            )
          : GestureDetector(
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
                _focusNode.requestFocus();
              },
              child: Text(
                _controller.text, // Use the controller's text for optimistic updates
                style: TextStyle(
                  decoration: widget.subitem.completed ? TextDecoration.lineThrough : null,
                  color: widget.subitem.completed ? Colors.grey : null,
                ),
              ),
            ),
    );
  }
}
