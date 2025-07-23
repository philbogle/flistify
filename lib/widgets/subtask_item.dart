import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/subitem.dart';

import 'package:listify_mobile/widgets/circular_checkbox.dart';
import 'package:listify_mobile/widgets/rename_subitem_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class SubtaskItem extends StatefulWidget {
  final Subitem subitem;
  final String listId;
  final bool startInEditMode;
  final VoidCallback? onSubmitted;
  final VoidCallback? onDelete;

  const SubtaskItem({
    super.key,
    required this.subitem,
    required this.listId,
    this.onSubmitted,
    this.onDelete,
    this.startInEditMode = false,
  });

  @override
  State<SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends State<SubtaskItem> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;
  late bool _optimisticCompleted;
  Map<String, String>? _linkPreview;
  bool _isLoadingPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.subitem.title);
    _isEditing = widget.startInEditMode;
    _optimisticCompleted = widget.subitem.completed;

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
    _fetchLinkPreview();
  }

  @override
  void didUpdateWidget(SubtaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subitem.title != oldWidget.subitem.title) {
      _controller.text = widget.subitem.title;
      _fetchLinkPreview();
    }
  }

  Future<void> _fetchLinkPreview() async {
    final url = _extractUrl(widget.subitem.title);
    if (url != null) {
      setState(() {
        _isLoadingPreview = true;
      });
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          final title = document.querySelector('title')?.text ?? '';
          final description = document.querySelector('meta[name="description"]')?.attributes['content'] ?? '';
          final imageUrl = document.querySelector('meta[property="og:image"]')?.attributes['content'] ?? '';
          setState(() {
            _linkPreview = {
              'title': title,
              'description': description,
              'imageUrl': imageUrl,
            };
          });
        }
      } catch (e) {
        // Ignore
      }
      setState(() {
        _isLoadingPreview = false;
      });
    }
  }

  String? _extractUrl(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
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
    });
  }

  void _showMenu(BuildContext context) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox itemBox = context.findRenderObject() as RenderBox;
    final Offset position = itemBox.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + itemBox.size.width, position.dy + itemBox.size.height),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        setState(() {
          _isEditing = true;
          _focusNode.requestFocus();
        });
      } else if (value == 'delete') {
        widget.onDelete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onLongPress: () => _showMenu(context),
      leading: CircularCheckbox(
        value: _optimisticCompleted,
        onChanged: _handleCheckboxChanged,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_linkPreview != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_linkPreview!['imageUrl']!.isNotEmpty)
                      Image.network(_linkPreview!['imageUrl']!),
                    if (_linkPreview!['title']!.isNotEmpty)
                      Text(_linkPreview!['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_linkPreview!['description']!.isNotEmpty)
                      Text(_linkPreview!['description']!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _isEditing
              ? TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(hintText: 'Add item'),
                  onSubmitted: (_) => _updateSubitem(),
                )
              : GestureDetector(
                  onTap: () => _handleCheckboxChanged(!_optimisticCompleted),
                  child: GestureDetector(
                    onTap: () {
                      final url = _extractUrl(widget.subitem.title);
                      if (url != null) {
                        launchUrl(Uri.parse(url));
                      } else {
                        setState(() {
                          _isEditing = true;
                          _focusNode.requestFocus();
                        });
                      }
                    },
                    child: Text(
                      _controller.text,
                      style: TextStyle(
                        decoration: _optimisticCompleted ? TextDecoration.lineThrough : null,
                        color: _optimisticCompleted ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      subtitle: _isLoadingPreview ? const LinearProgressIndicator() : null,
      trailing: _isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _updateSubitem,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _controller.text = widget.subitem.title; // Revert changes
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onDelete,
                ),
              ],
            )
          : null,
    );
  }
}
