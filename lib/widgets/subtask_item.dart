
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/subitem_detail_screen.dart';

class SubtaskItem extends StatefulWidget {
  final Subitem subitem;
  final String listId;

  const SubtaskItem({super.key, required this.subitem, required this.listId});

  @override
  State<SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends State<SubtaskItem> {
  late bool _optimisticCompleted;

  @override
  void initState() {
    super.initState();
    _optimisticCompleted = widget.subitem.completed;
  }

  @override
  void didUpdateWidget(SubtaskItem oldWidget) {
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
      if (!snapshot.exists) {
        throw Exception("List does not exist!");
      }

      final List<dynamic> subtasks =
          List<dynamic>.from(snapshot.data()!['subtasks'] ?? []);

      final int index =
          subtasks.indexWhere((task) => task['id'] == widget.subitem.id);

      if (index != -1) {
        final Map<String, dynamic> subitemToUpdate =
            Map<String, dynamic>.from(subtasks[index]);
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
      leading: Checkbox(
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubitemDetailScreen(listId: widget.listId, subitemId: widget.subitem.id),
          ),
        );
      },
    );
  }
}

