import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/widgets/list_detail_screen.dart';
import 'package:listify_mobile/widgets/read_only_subtask_item.dart';
import 'package:listify_mobile/widgets/share_list_dialog.dart';

class ListCard extends StatefulWidget {
  final ListModel list;
  final ValueChanged<bool?> onCompleted;

  const ListCard({super.key, required this.list, required this.onCompleted});

  @override
  State<ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<ListCard> {
  late bool _optimisticCompleted;

  @override
  void initState() {
    super.initState();
    _optimisticCompleted = widget.list.completed;
  }

  @override
  void didUpdateWidget(ListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.list.completed != oldWidget.list.completed) {
      _optimisticCompleted = widget.list.completed;
    }
  }

  void _handleCheckboxChanged(bool? value) {
    if (value == null) return;

    setState(() {
      _optimisticCompleted = value;
    });

    widget.onCompleted(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ListDetailScreen(listId: widget.list.id),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
          );
        },
        child: Column(
          children: [
            ListTile(
              leading: Checkbox(
                value: _optimisticCompleted,
                onChanged: _handleCheckboxChanged,
              ),
              title: Text(
                widget.list.title,
                style: TextStyle(
                  decoration: _optimisticCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: _optimisticCompleted ? Colors.grey : null,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
            ...widget.list.subitems
                .where((s) => s.title.isNotEmpty)
                .map((subitem) {
              return Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: ReadOnlySubtaskItem(
                    subitem: subitem, listId: widget.list.id),
              );
            }).toList(),
            const SizedBox(height: 8), // Add some padding at the bottom
          ],
        ),
      ),
    );
  }
}