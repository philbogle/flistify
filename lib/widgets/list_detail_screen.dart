import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/add_subitem_dialog.dart';
import 'package:listify_mobile/widgets/subtask_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ListDetailScreen extends StatefulWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  bool _isEditing = false;
  late final TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();
  final GlobalKey _titleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    // Add a listener to save when focus is lost
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus && _isEditing) {
        _updateTitle();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _updateTitle() {
    if (_titleController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.listId)
          .update({'title': _titleController.text});
    }
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').doc(widget.listId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final list = ListModel.fromMap(snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);
        final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black);

        if (!_isEditing) {
          _titleController.text = list.title;
        }

        return Scaffold(
          appBar: AppBar(
            title: _isEditing
                ? TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    autofocus: true,
                    style: titleStyle,
                    cursorColor: Colors.black,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter list title',
                      hintStyle: TextStyle(color: Colors.black54),
                    ),
                    onSubmitted: (_) => _updateTitle(),
                  )
                : GestureDetector(
                    onTapDown: (details) {
                      final RenderBox renderBox = _titleKey.currentContext!.findRenderObject() as RenderBox;
                      final offset = renderBox.globalToLocal(details.globalPosition);
                      final textSpan = TextSpan(text: list.title, style: titleStyle);
                      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
                      final position = textPainter.getPositionForOffset(offset);

                      setState(() {
                        _isEditing = true;
                      });

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _titleFocusNode.requestFocus();
                        _titleController.selection = TextSelection.fromPosition(position);
                      });
                    },
                    child: Text(list.title, key: _titleKey, style: titleStyle),
                  ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (String result) {
                  switch (result) {
                    case 'delete':
                      Navigator.of(context).pop();
                      FirebaseFirestore.instance.collection('tasks').doc(list.id).delete();
                      break;
                    case 'autogenerate':
                      _autogenerateItems(list);
                      break;
                    case 'autosort':
                      _autosortItems(list);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'autogenerate',
                    child: Text('Autogenerate Items'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'autosort',
                    child: Text('Autosort Items'),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            children: [
              ...list.subitems.map((subitem) {
                return SubtaskItem(subitem: subitem, listId: list.id);
              }).toList(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddSubitemDialog(listId: list.id),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _autogenerateItems(ListModel list) async {
    // ... (autogenerate logic remains the same)
  }

  void _autosortItems(ListModel list) async {
    // ... (autosort logic remains the same)
  }
}