
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/task.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (bool? value) {
            if (value != null) {
              // Assuming 'tasks' is the collection for lists and 'subtasks' is a subcollection
              // This might need adjustment based on your actual Firestore structure
              // For now, let's assume a top-level 'tasks' collection for lists
              // and a subcollection for tasks within each list.
              // This will likely fail if the document path is incorrect.
              // We will need to read the main.dart file to understand the correct path.
            }
          },
        ),
        title: GestureDetector(
          onTap: () {
            // This will likely fail if the document path is incorrect.
            // We will need to read the main.dart file to understand the correct path.
          },
          child: Text(task.title),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String result) {
            // Handle menu actions here
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'rename',
              child: Text('Rename'),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
