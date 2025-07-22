import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:listify_mobile/widgets/subtask_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:listify_mobile/widgets/confirm_delete_dialog.dart';
import 'package:camera/camera.dart';
import 'package:listify_mobile/widgets/dictate_list_dialog.dart';
import 'package:listify_mobile/constants.dart';
import 'package:listify_mobile/widgets/share_list_dialog.dart';
import 'package:listify_mobile/widgets/take_picture_screen.dart';

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
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();

  List<Subitem> _subitems = [];
  String? _newlyAddedSubitemId;
  bool _isReturningFromPicker = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus && _isEditing) {
        _updateTitle();
      }
    });

    // Add an initial blank item if the list is empty
    FirebaseFirestore.instance.collection('tasks').doc(widget.listId).get().then((doc) {
      if (doc.exists) {
        final list = ListModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        if (list.subitems.where((s) => s.title.isNotEmpty).isEmpty && list.subitems.where((s) => s.title.isEmpty).isEmpty) {
          _addNewSubitem();
        }
      }
    });
  }

  @override
  void dispose() {
    // Save any pending edits before the screen is destroyed
    if (_isEditing) {
      _updateTitle(silent: true);
    }
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _updateTitle({bool silent = false}) {
    if (_titleController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.listId)
          .update({'title': _titleController.text});
    }
    if (mounted && !silent) {
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

    FirebaseFirestore.instance.collection('tasks').doc(widget.listId).update({
      'subtasks': _subitems.map((s) => s.toMap()).toList(),
    });
  }

  void _deleteSubitem(int index) {
    final removedItem = _subitems.removeAt(index);
    final listRef = FirebaseFirestore.instance.collection('tasks').doc(widget.listId);

    // Animate the removal
    _animatedListKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: SubtaskItem(
          subitem: removedItem,
          listId: widget.listId,
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );

    // Update Firestore in the background
    listRef.update({
      'subtasks': _subitems.map((s) => s.toMap()).toList(),
    }).catchError((error) {
      // If the update fails, re-insert the item and show an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete item: $error")),
      );
      setState(() {
        _subitems.insert(index, removedItem);
        _animatedListKey.currentState?.insertItem(index);
      });
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
        final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold);

        if (!_isEditing) {
          _titleController.text = list.title;
        }

        final child = Scaffold(
          appBar: AppBar(
            title: _isEditing
                ? TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    autofocus: true,
                    style: titleStyle,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter title',
                    ),
                    onSubmitted: (_) => _updateTitle(),
                  )
                : GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
                    child: Text(list.title, style: titleStyle),
                  ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (String result) async {
                  switch (result) {
                    case 'delete':
                      final bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => ConfirmDeleteDialog(listName: list.title),
                      );
                      if (confirmed == true) {
                        Navigator.of(context).pop();
                        FirebaseFirestore.instance.collection('tasks').doc(list.id).delete();
                      }
                      break;
                    case 'autogenerate':
                      _autogenerateItems(list);
                      break;
                    case 'autosort':
                      _autosortItems(list);
                      break;
                    case 'scan_more':
                      _scanAndAppendItems(list);
                      break;
                    case 'dictate_or_paste':
                      showDialog(
                        context: context,
                        builder: (context) => DictateListDialog(list: list),
                      );
                      break;
                    case 'share':
                      if (list.shareId == null) {
                        final newShareId = FirebaseFirestore.instance.collection('dummy').doc().id;
                        FirebaseFirestore.instance.collection('tasks').doc(list.id).update({
                          'shareId': newShareId,
                        }).then((_) {
                          final newList = ListModel(
                            id: list.id,
                            title: list.title,
                            completed: list.completed,
                            subitems: list.subitems,
                            createdAt: list.createdAt,
                            shareId: newShareId,
                          );
                          showDialog(
                            context: context,
                            builder: (context) => ShareListDialog(list: newList),
                          );
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => ShareListDialog(list: list),
                        );
                      }
                      break;
                    case 'delete_completed':
                      final updatedSubitems = list.subitems.where((s) => !s.completed).toList();
                      FirebaseFirestore.instance.collection('tasks').doc(list.id).update({
                        'subtasks': updatedSubitems.map((s) => s.toMap()).toList(),
                      });
                      break;
                    case 'mark_complete':
                      FirebaseFirestore.instance.collection('tasks').doc(list.id).update({
                        'completed': true,
                      });
                      Navigator.of(context).pop();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'mark_complete',
                    child: Row(
                      children: [
                        Icon(Icons.check),
                        SizedBox(width: 8),
                        Text('Mark Complete'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'autogenerate',
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_outlined),
                        SizedBox(width: 8),
                        Text('Autogenerate Items'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'autosort',
                    child: Row(
                      children: [
                        Icon(Icons.sort),
                        SizedBox(width: 8),
                        Text('Autosort Items'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'scan_more',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt_outlined),
                        SizedBox(width: 8),
                        Text('Scan More Items'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'dictate_or_paste',
                    child: Row(
                      children: [
                        Icon(Icons.mic_none),
                        SizedBox(width: 8),
                        Text('Dictate or Paste'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share List'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'delete_completed',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 8),
                        Text('Delete Completed Items'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 8),
                        Text('Delete List'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80.0), // Added padding to prevent FAB overlap
            key: _animatedListKey,
            itemCount: _subitems.length + 1, // Add one for the button
            itemBuilder: (context, index) {
              if (index == _subitems.length) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: TextButton.icon(
                    onPressed: _addNewSubitem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add list item'),
                  ),
                );
              }

              final subitem = _subitems[index];
              bool isNew = subitem.id == _newlyAddedSubitemId;
              return SubtaskItem(
                key: ValueKey(subitem.id),
                subitem: subitem,
                listId: list.id,
                startInEditMode: isNew,
                onDelete: () => _deleteSubitem(index),
                onSubmitted: () {
                  if (isNew) {
                    _addNewSubitem();
                  }
                },
              );
            },
          ),
        );

        if (_isReturningFromPicker) {
          return child;
        }

        return child;
      },
    );
  }

  void _autogenerateItems(ListModel list) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🤖 Autogenerating items...')),
    );

    final requestBody = {
      'listTitle': list.title,
      'existingSubitems': list.subitems.map((s) => s.title).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/generateSubitems'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSubitemTitles = (data['newSubitemTitles'] as List<dynamic>? ?? [])
            .map((item) => item as String)
            .toList();

        final newSubitems = newSubitemTitles.map((title) {
          final newSubitemRef = FirebaseFirestore.instance
              .collection('tasks')
              .doc(list.id)
              .collection('subtasks')
              .doc();

          return {
            'id': newSubitemRef.id,
            'title': title,
            'completed': false,
          };
        }).toList();

        await FirebaseFirestore.instance.collection('tasks').doc(list.id).update({
          'subtasks': FieldValue.arrayUnion(newSubitems),
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating items: $e")),
        );
      }
    }
  }

  void _autosortItems(ListModel list) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🤖 Autosorting items...')),
    );

    final requestBody = {
      'listTitle': list.title,
      'subitems': list.subitems.map((s) => {'id': s.id, 'title': s.title, 'completed': s.completed}).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/autosortListItems'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sortedSubitems = (data['sortedSubitems'] as List<dynamic>? ?? [])
            .map((item) => {
                  'id': list.subitems.firstWhere((s) => s.title == item['title'], orElse: () => Subitem(id: DateTime.now().millisecondsSinceEpoch.toString(), title: item['title'], completed: item['completed'])).id,
                  'title': item['title'] ?? '',
                  'completed': item['completed'] ?? false,
                })
            .toList();

        await FirebaseFirestore.instance.collection('tasks').doc(list.id).update({
          'subtasks': sortedSubitems,
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sorting items: $e")),
        );
      }
    }
  }

  void _scanAndAppendItems(ListModel list) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cameras found.')),
      );
      return;
    }
    final firstCamera = cameras.first;

    final XFile? image = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(),
      ),
    );

    if (image == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recognizing list...')),
    );

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageDataUri = 'data:image/jpeg;base64,$base64Image';

      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/extractFromImage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageDataUri': imageDataUri}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSubitemTitles = (data['extractedSubitems'] as List<dynamic>? ?? [])
            .map((item) => item['title'] as String)
            .toList();

        final newSubitems = newSubitemTitles.map((title) {
          final newSubitemRef = FirebaseFirestore.instance
              .collection('tasks')
              .doc(list.id)
              .collection('subtasks')
              .doc();
          return {
            'id': newSubitemRef.id,
            'title': title,
            'completed': false,
          };
        }).toList();

        // Find the index of the blank item, if it exists
        final blankItemIndex = list.subitems.indexWhere((s) => s.title.isEmpty);

        if (blankItemIndex != -1) {
          // If a blank item exists, insert the new items before it
          final updatedSubtasks = List.from(list.subitems)..insertAll(blankItemIndex, newSubitems);
          await FirebaseFirestore.instance.collection('tasks').doc(list.id).update({
            'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
          });
        } else {
          // Otherwise, just append the new items
          await FirebaseFirestore.instance.collection('tasks').doc(list.id).update({
            'subtasks': FieldValue.arrayUnion(newSubitems),
          });
        }
      } else {
        throw Exception('Failed to scan items: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error scanning items: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReturningFromPicker = false;
        });
      }
    }
  }
}