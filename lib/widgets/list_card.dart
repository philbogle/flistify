import 'package:flutter/material.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/widgets/read_only_subtask_item.dart';
import 'package:listify_mobile/widgets/list_detail_screen.dart';
import 'package:listify_mobile/widgets/subtask_item.dart';

class ListCard extends StatelessWidget {
  final ListModel list;
  final ValueChanged<bool?> onCompleted;

  const ListCard({super.key, required this.list, required this.onCompleted});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListDetailScreen(listId: list.id),
            ),
          );
        },
        child: Column(
          children: [
            ListTile(
              leading: Checkbox(
                value: list.completed,
                onChanged: onCompleted,
              ),
              title: Text(
                list.title,
                style: TextStyle(
                  decoration: list.completed ? TextDecoration.lineThrough : null,
                  color: list.completed ? Colors.grey : null,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
            ...list.subitems.where((s) => s.title.isNotEmpty).map((subitem) {
              return Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: ReadOnlySubtaskItem(subitem: subitem, listId: list.id),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}