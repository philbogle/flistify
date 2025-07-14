
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManualAddList extends StatefulWidget {
  const ManualAddList({super.key});

  @override
  State<ManualAddList> createState() => _ManualAddListState();
}

class _ManualAddListState extends State<ManualAddList> {
  final TextEditingController _controller = TextEditingController();

  void _addList() async {
    if (_controller.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Hide the keyboard
    FocusScope.of(context).unfocus();

    // Add the new list to Firestore
    await FirebaseFirestore.instance.collection('tasks').add({
      'title': _controller.text,
      'subtasks': [],
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'completed': false,
    });

    // Close the bottom sheet
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'New list',
                filled: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addList,
          ),
        ],
      ),
    );
  }
}
