import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:listify_mobile/widgets/link_utils.dart';
import 'package:listify_mobile/widgets/shimmer_placeholder.dart';

/// An editable sub-item that is displayed in a list.
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

/// State class for [SubtaskItem].
class _SubtaskItemState extends State<SubtaskItem> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;
  late bool _optimisticCompleted;
  Map<String, String>? _linkPreview;
  bool _isLoadingPreview = false;

  @override
  /// Initializes the state of the widget.
  ///
  /// This method is called once when the widget is inserted into the widget tree.
  /// It initializes the [_controller] with the subitem's title, sets the editing
  /// mode based on [startInEditMode], and sets up a listener for the [_focusNode]
  /// to update the subitem when focus is lost. It also fetches the link preview.
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
  /// Called when the widget is re-built with new parameters.
  ///
  /// This method is called when the widget's configuration changes.
  /// It updates the [_controller]'s text and refetches the link preview
  /// if the subitem's title has changed.
  void didUpdateWidget(SubtaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subitem.title != oldWidget.subitem.title) {
      _controller.text = widget.subitem.title;
      _fetchLinkPreview();
    }
  }

  /// Fetches the link preview for the subitem's title if it contains a URL.
  ///
  /// This method extracts a URL from the subitem's title, makes an HTTP request
  /// to fetch the content of the URL, parses the HTML to extract the title,
  /// description, and image URL, and then updates the [_linkPreview] state.
  /// It also manages the [_isLoadingPreview] state.
  Future<void> _fetchLinkPreview() async {
    final url = LinkUtils.extractUrl(widget.subitem.title);
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

  @override
  /// Disposes of the controllers when the widget is disposed.
  ///
  /// This method is called when the widget is removed from the widget tree.
  /// It disposes of the [_controller] and [_focusNode] to prevent memory leaks.
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Updates the subitem in Firestore.
  ///
  /// If the controller's text is empty, it calls the [onDelete] callback.
  /// If the text has not changed, it does nothing. Otherwise, it updates the
  /// subitem's title in Firestore and sets [_isEditing] to false.
  void _updateSubitem() {
    if (_controller.text.isEmpty) {
      widget.onDelete?.call();
      return;
    }

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

  /// Handles the change in the checkbox value.
  ///
  /// Updates the optimistic completed state and then updates the subitem's
  /// 'completed' status in Firestore using a transaction.
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

  @override
  Widget build(BuildContext context) {
    if (widget.subitem.isHeader) {
      return ListTile(
        title: _isEditing
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Add header'),
                onSubmitted: (_) => _updateSubitem(),
              )
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                child: Text(
                  widget.subitem.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
        trailing: _isEditing
            ? IconButton(
                icon: const Icon(Icons.delete),
                onPressed: widget.onDelete,
              )
            : null,
      );
    }
    return ListTile(
      leading: CircularCheckbox(
        value: _optimisticCompleted,
        onChanged: _handleCheckboxChanged,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingPreview)
            const ShimmerPlaceholder(height: 100)
          else if (_linkPreview != null) ...[
            GestureDetector(
              onTap: () {
                final url = LinkUtils.extractUrl(widget.subitem.title);
                if (url != null) {
                  launchUrl(Uri.parse(url));
                }
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_linkPreview!['imageUrl']!.isNotEmpty)
                        Image.network(
                          _linkPreview!['imageUrl']!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_linkPreview!['title']!.isNotEmpty)
                              Text(
                                _linkPreview!['title']!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (_linkPreview!['description']!.isNotEmpty)
                              Text(
                                _linkPreview!['description']!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  onTapDown: (details) {
                    setState(() {
                      _isEditing = true;
                      _focusNode.requestFocus();
                      _controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _controller.text.length,
                      );
                    });
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      LinkUtils.formatTitle(_controller.text),
                      style: LinkUtils.getTextStyle(_controller.text, completed: _optimisticCompleted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
        ],
      ),
      subtitle: _isLoadingPreview ? const LinearProgressIndicator() : null,
      trailing: _isEditing
          ? IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.onDelete,
            )
          : null,
    );
  }
}