import 'dart:async';

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
import 'package:listify_mobile/services/google_tasks_service.dart';
import 'package:listify_mobile/widgets/take_picture_screen.dart';
import 'package:listify_mobile/widgets/help_dialog.dart';
import 'package:listify_mobile/widgets/share_drawer.dart';

/// A screen that displays the details of a list.
class ListDetailScreen extends StatefulWidget {
  final String listId;
  final bool isShared;

  const ListDetailScreen({super.key, required this.listId, this.isShared = false});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

/// State class for [ListDetailScreen].
class _ListDetailScreenState extends State<ListDetailScreen> {
  late TextEditingController _titleController;
  bool _isEditing = false;
  final FocusNode _titleFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isExportingTasks = false;
  String? _newlyAddedSubitemId;
  // Optimistic additions rendered immediately before Firestore roundtrip completes
  final List<Subitem> _pendingSubitems = <Subitem>[];

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
    if (_isEditing) {
      _updateTitle(silent: true);
    }
    _titleController.dispose();
    _titleFocusNode.dispose();
    _scrollController.dispose();
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

  void _addNewSubitem({bool isHeader = false}) async {
    final newSubitem = Subitem(
      id: FirebaseFirestore.instance.collection('dummy').doc().id,
      title: '',
      completed: false,
      isHeader: isHeader,
    );

    // Optimistically render immediately
    setState(() {
      _pendingSubitems.add(newSubitem);
      _newlyAddedSubitemId = newSubitem.id;
    });
    // Ensure the new item is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(widget.listId).update({
        'subtasks': FieldValue.arrayUnion([newSubitem.toMap()]),
      });
      // When the snapshot reflects this item, it will be pruned from _pendingSubitems in build
    } catch (e) {
      // Rollback optimistic addition on error
      if (mounted) {
        setState(() {
          _pendingSubitems.removeWhere((s) => s.id == newSubitem.id);
          if (_newlyAddedSubitemId == newSubitem.id) {
            _newlyAddedSubitemId = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  void _deleteSubitem(String subitemId) {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(FirebaseFirestore.instance.collection('tasks').doc(widget.listId));
      final subtasks = List<Map<String, dynamic>>.from(doc.data()!['subtasks']);
      subtasks.removeWhere((subtask) => subtask['id'] == subitemId);
      transaction.update(doc.reference, {'subtasks': subtasks});
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
        final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold);

        if (!_isEditing) {
          _titleController.text = list.title;
        }

        // Merge server subitems with any optimistic pending ones
        final Set<String> serverIds = list.subitems.map((s) => s.id).toSet();
        final List<Subitem> visibleSubitems = [
          ...list.subitems,
          ..._pendingSubitems.where((s) => !serverIds.contains(s.id)),
        ];

        // Prune pending items that have arrived from server
        final hasPendingToPrune = _pendingSubitems.any((s) => serverIds.contains(s.id));
        if (hasPendingToPrune) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _pendingSubitems.removeWhere((s) => serverIds.contains(s.id));
            });
          });
        }

        final child = Scaffold(
          drawer: widget.isShared ? const ShareDrawer() : null,
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _isEditing = true;
                          _titleController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _titleController.text.length,
                          );
                        });
                      }
                    },
                    child: _isEditing
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
                        : Text(widget.isShared ? 'Shared list: ${list.title}' : list.title, style: titleStyle),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ShareListDialog(list: list),
                  );
                },
              ),
              
              
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
                    case 'autosort_and_group':
                      _autosortAndGroupItems(list);
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
                    case 'export_to_google_tasks':
                      setState(() { _isExportingTasks = true; });
                      final googleTasksService = GoogleTasksService();
                      try {
                        await googleTasksService.exportTasks(list);
                        if (!mounted) break;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('List exported to Google Tasks successfully!')),
                        );
                      } catch (e) {
                        debugPrint('Export to Google Tasks error: $e');
                        if (!mounted) break;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to export to Google Tasks: $e')),
                        );
                      } finally {
                        if (mounted) setState(() { _isExportingTasks = false; });
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
                    case 'help':
                      showDialog(
                        context: context,
                        builder: (context) => const HelpDialog(),
                      );
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'scan_more',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt),
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
                    value: 'autosort_and_group',
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_motion),
                        SizedBox(width: 8),
                        Text('Autosort & Group'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'export_to_google_tasks',
                    child: Row(
                      children: [
                        Icon(Icons.task_outlined),
                        SizedBox(width: 8),
                        Text('Export to Google Tasks'),
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
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'help',
                    child: Row(
                      children: [
                        Icon(Icons.help_outline),
                        SizedBox(width: 8),
                        Text('Help'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          body: Stack(
            children: [
              ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 160.0), // Added padding to prevent FAB overlap
                children: [
                  ...visibleSubitems.map((subitem) {
                    final bool isNew = subitem.id == _newlyAddedSubitemId;
                    return SubtaskItem(
                      key: ValueKey(subitem.id),
                      subitem: subitem,
                      listId: list.id,
                      startInEditMode: isNew,
                      onDelete: () => _deleteSubitem(subitem.id),
                      onLocalTitleChanged: (newTitle) {
                        // Update pending model immediately for not-yet-synced items
                        final idx = _pendingSubitems.indexWhere((s) => s.id == subitem.id);
                        if (idx != -1) {
                          setState(() {
                            _pendingSubitems[idx] = Subitem(
                              id: _pendingSubitems[idx].id,
                              title: newTitle,
                              completed: _pendingSubitems[idx].completed,
                              isHeader: _pendingSubitems[idx].isHeader,
                            );
                          });
                        }
                      },
                      onSubmitted: () {
                        if (isNew) {
                          _addNewSubitem();
                        }
                      },
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                    child: TextButton.icon(
                      onPressed: _addNewSubitem,
                      onLongPress: () => _addNewSubitem(isHeader: true),
                      icon: const Icon(Icons.add),
                      label: const Text('Add list item'),
                    ),
                  ),
                ],
              ),
              if (_isExportingTasks)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Exporting to Google Tasks...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: child,
          ),
        );
      },
    );
  }

  /// Autogenerates items for the list.
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

  /// Autosorts and groups the items in the list.
  void _autosortAndGroupItems(ListModel list) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🤖 Autosorting and grouping items...')),
    );

    final requestBody = {
      'listTitle': list.title,
      'subitems': list.subitems
          .where((s) => !s.isHeader) // Exclude existing headers from the request
          .map((s) => {'id': s.id, 'title': s.title, 'completed': s.completed, 'isHeader': s.isHeader})
          .toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/autosortAndGroupListItems'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sortedSubitems = (data['sortedSubitems'] as List<dynamic>? ?? [])
            .map((item) => {
                  'id': item['isHeader'] 
                      ? FirebaseFirestore.instance.collection('dummy').doc().id 
                      : list.subitems.firstWhere((s) => s.id == item['id'], orElse: () => Subitem(id: FirebaseFirestore.instance.collection('dummy').doc().id, title: item['title'], completed: item['completed'], isHeader: item['isHeader'])).id,
                  'title': item['title'] ?? '',
                  'completed': item['completed'] ?? false,
                  'isHeader': item['isHeader'] ?? false,
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

  /// Scans an image and appends the items to the list.
  void _scanAndAppendItems(ListModel list) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cameras found.')),
      );
      return;
    }
    // Find the rear camera
    final rearCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first, // Fallback to the first camera if no rear camera is found
    );

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
    }
  }
}