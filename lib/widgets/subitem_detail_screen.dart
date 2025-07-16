import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/subitem.dart';

class SubitemDetailScreen extends StatefulWidget {
  final String listId;
  final String subitemId;

  const SubitemDetailScreen({super.key, required this.listId, required this.subitemId});

  @override
  State<SubitemDetailScreen> createState() => _SubitemDetailScreenState();
}

class _SubitemDetailScreenState extends State<SubitemDetailScreen> {
  late TextEditingController _titleController;
  bool _isEditing = false;
  final FocusNode _titleFocusNode = FocusNode();
  final GlobalKey _titleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus && _isEditing) {
        _updateSubitem();
      }
    });
  }

  @override
  void dispose() {
    _updateSubitem(silent: true);
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _updateSubitem({bool silent = false}) {
    if (_titleController.text.isEmpty) return;

    final listRef = FirebaseFirestore.instance.collection('tasks').doc(widget.listId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(listRef);
      if (!snapshot.exists) {
        throw Exception("List does not exist!");
      }

      final List<dynamic> subtasks =
          List<dynamic>.from(snapshot.data()!['subtasks'] ?? []);

      final int index =
          subtasks.indexWhere((task) => task['id'] == widget.subitemId);

      if (index != -1) {
        final Map<String, dynamic> subitemToUpdate =
            Map<String, dynamic>.from(subtasks[index]);
        subitemToUpdate['title'] = _titleController.text;
        subtasks[index] = subitemToUpdate;
        transaction.update(listRef, {'subtasks': subtasks});
      }
    });

    if (mounted && !silent) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _deleteSubitem() {
    final listRef = FirebaseFirestore.instance.collection('tasks').doc(widget.listId);
    Navigator.of(context).pop(); // Go back first

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(listRef);
      if (!snapshot.exists) {
        throw Exception("List does not exist!");
      }

      final List<dynamic> subtasks =
          List<dynamic>.from(snapshot.data()!['subtasks'] ?? []);

      subtasks.removeWhere((task) => task['id'] == widget.subitemId);

      transaction.update(listRef, {'subtasks': subtasks});
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

        final subitems = (snapshot.data!.data() as Map<String, dynamic>)['subtasks'] as List<dynamic>? ?? [];
        final subitemData = subitems.firstWhere((s) => s['id'] == widget.subitemId, orElse: () => null);

        if (subitemData == null) {
          // This can happen if the subitem is deleted while the user is on this screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) Navigator.of(context).pop();
          });
          return const Scaffold(
            body: Center(child: Text('Subitem not found.')),
          );
        }

        final subitem = Subitem.fromMap(subitemData);
        final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black);

        if (!_isEditing) {
          _titleController.text = subitem.title;
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
                      hintText: 'Enter item title',
                      hintStyle: TextStyle(color: Colors.black54),
                    ),
                    onSubmitted: (_) => _updateSubitem(),
                  )
                : GestureDetector(
                    onTapDown: (details) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final RenderBox renderBox = _titleKey.currentContext!.findRenderObject() as RenderBox;
                        final offset = renderBox.globalToLocal(details.globalPosition);
                        final textSpan = TextSpan(text: subitem.title, style: titleStyle);
                        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
                        final position = textPainter.getPositionForOffset(offset);

                        setState(() {
                          _isEditing = true;
                        });

                        _titleFocusNode.requestFocus();
                        _titleController.selection = TextSelection.fromPosition(position);
                      });
                    },
                    child: Text(subitem.title, key: _titleKey, style: titleStyle),
                  ),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _deleteSubitem,
                  tooltip: 'Delete Item',
                ),
            ],
          ),
          body: Container(), // Body is no longer needed for editing
        );
      },
    );
  }
}