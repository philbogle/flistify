import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:listify_mobile/constants.dart';

import 'package:listify_mobile/models/list.dart';

/// A dialog that allows the user to dictate or paste a list.
class DictateListDialog extends StatefulWidget {
  final ListModel list;

  const DictateListDialog({super.key, required this.list});

  @override
  State<DictateListDialog> createState() => _DictateListDialogState();
}

/// State class for [DictateListDialog].
class _DictateListDialogState extends State<DictateListDialog> {
  /// Controller for the text input field.
  final TextEditingController _controller = TextEditingController();
  /// Indicates whether a loading operation is in progress.
  bool _isLoading = false;

  /// Creates a list from the dictated or pasted text.
  ///
  /// This method sends the dictated text to a backend API for extraction
  /// of list items and then updates the Firestore document with the new subitems.
  /// It handles loading states and error reporting.
  void _createList() async {
    if (_controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/extractFromText'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dictatedText': _controller.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['parentListTitle'] ?? 'Pasted List';
        final newSubitems = (data['extractedSubitems'] as List<dynamic>? ?? [])
            .map((item) => {
                  'id': DateTime.now().millisecondsSinceEpoch.toString() +
                      (item['title'] ?? ''),
                  'title': item['title'] ?? '',
                  'completed': false,
                })
            .toList();

        await FirebaseFirestore.instance.collection('tasks').doc(widget.list.id).update({
          'subtasks': FieldValue.arrayUnion(newSubitems),
        });

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to create list: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create list: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  /// Builds the widget.
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dictate or Paste List'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 10,
        decoration: const InputDecoration(
          hintText: 'Paste your list here, or use your keyboard\'s dictation feature.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createList,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create List'),
        ),
      ],
    );
  }
}