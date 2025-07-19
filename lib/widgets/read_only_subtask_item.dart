import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/subitem.dart';

import 'package:listify_mobile/widgets/circular_checkbox.dart';

class ReadOnlySubtaskItem extends StatefulWidget {
  final Subitem subitem;
  final String listId;

  const ReadOnlySubtaskItem({super.key, required this.subitem, required this.listId});

  @override
  State<ReadOnlySubtaskItem> createState() => _ReadOnlySubtaskItemState();
}

class _ReadOnlySubtaskItemState extends State<ReadOnlySubtaskItem> {
  late bool _optimisticCompleted;

  @override
  void initState() {
    super.initState();
    _optimisticCompleted = widget.subitem.completed;
  }

  @override
  void didUpdateWidget(ReadOnlySubtaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subitem.completed != oldWidget.subitem.completed) {
      _optimisticCompleted = widget.subitem.completed;
    }
  }

  void _handleCheckboxChanged(bool? value) {
    if (value == null) return;

    final originalValue = _optimisticCompleted;
    setState(() {
      _optimisticCompleted = value;
    });

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
    }).catchError((error) {
      setState(() {
        _optimisticCompleted = originalValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't update item. Please try again."),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircularCheckbox(
        value: _optimisticCompleted,
        onChanged: _handleCheckboxChanged,
      ),
      title: Text(
        widget.subitem.title,
        style: TextStyle(
          decoration: _optimisticCompleted ? TextDecoration.lineThrough : null,
          color: _optimisticCompleted ? Colors.grey : null,
        ),
      ),
    );
  }
}