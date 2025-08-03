import 'package:flutter/material.dart';

/// A widget that allows the user to manually add a list.
class ManualAddList extends StatefulWidget {
  const ManualAddList({super.key});

  @override
  State<ManualAddList> createState() => _ManualAddListState();
}

/// State class for [ManualAddList].
class _ManualAddListState extends State<ManualAddList> {
  /// Controller for the text input field.
  final TextEditingController _controller = TextEditingController();

  /// Submits the new list.
  ///
  /// If the text field is not empty, it pops the current context with the
  /// text as the result.
  void _submit() {
    if (_controller.text.isNotEmpty) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  /// Builds the widget.
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
              onSubmitted: (_) => _submit(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}