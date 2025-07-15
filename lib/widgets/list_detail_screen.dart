import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/models/subitem.dart';
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
  late TextEditingController _titleController;
  bool _isEditing = false;
  final FocusNode _titleFocusNode = FocusNode();
  final GlobalKey _titleKey = GlobalKey();

  List<Subitem> _subitems = [];
  String? _newlyAddedSubitemId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
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

  void _addNewSubitem() {
    final newSubitem = Subitem(
      id: FirebaseFirestore.instance.collection('dummy').doc().id,
      title: '',
      completed: false,
    );

    setState(() {
      _subitems.add(newSubitem);
      _newlyAddedSubitemId = newSubitem.id;
    });

    _updateFirestoreSubitems();
  }

  void _updateFirestoreSubitems() {
    FirebaseFirestore.instance.collection('tasks').doc(widget.listId).update({
      'subtasks': _subitems.map((s) => s.toMap()).toList(),
    });
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
        _subitems = list.subitems;
        final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black);

        if (!_isEditing) {
          _titleController.text = list.title;
        }

        if (_subitems.where((s) => s.title.isEmpty).isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _addNewSubitem());
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
          body: ListView.builder(
            itemCount: _subitems.length,
            itemBuilder: (context, index) {
              final subitem = _subitems[index];
              bool isNew = subitem.id == _newlyAddedSubitemId;
              return SubtaskItem(
                key: ValueKey(subitem.id),
                subitem: subitem,
                listId: list.id,
                startInEditMode: isNew,
                onSubmitted: () {
                  if (isNew) {
                    _addNewSubitem();
                  }
                },
              );
            },
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