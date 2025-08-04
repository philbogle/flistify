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
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();

  List<Subitem> _subitems = [];
  String? _newlyAddedSubitemId;
  bool _isReturningFromPicker = false;

  @override
  /// Initializes the state of the widget.
  ///
  /// This method is called once when the widget is inserted into the widget tree.
  /// It initializes the [_titleController] and [_titleFocusNode], and adds a listener
  /// to the focus node to update the title when the focus is lost. It also checks
  /// if the list is empty and adds an initial blank subitem if needed.
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
  /// Disposes of the controllers when the widget is disposed.
  ///
  /// This method is called when the widget is removed from the widget tree.
  /// It saves any pending title edits, disposes of the [_titleController]
  /// and [_titleFocusNode] to prevent memory leaks.
  void dispose() {
    // Save any pending edits before the screen is destroyed
    if (_isEditing) {
      _updateTitle(silent: true);
    }
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  /// Updates the title of the list.
  ///
  /// If the title controller's text is not empty, it updates the 'title' field
  /// in Firestore for the current list. If `silent` is false, it also updates
  /// the widget's state to exit editing mode.
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

  /// Adds a new sub-item to the list.
  ///
  /// Creates a new [Subitem] with a unique ID and an empty title, adds it to the
  /// local [_subitems] list, and updates the Firestore document to reflect the change.
  void _addNewSubitem({bool isHeader = false}) {
    final newSubitem = Subitem(
      id: FirebaseFirestore.instance.collection('dummy').doc().id,
      title: '',
      completed: false,
      isHeader: isHeader,
    );

    setState(() {
      _subitems.add(newSubitem);
      _newlyAddedSubitemId = newSubitem.id;
    });

    FirebaseFirestore.instance.collection('tasks').doc(widget.listId).update({
      'subtasks': _subitems.map((s) => s.toMap()).toList(),
    });
  }

  /// Deletes a sub-item from the list.
  ///
  /// Removes the subitem with the given [subitemId] from the local list and
  /// updates the Firestore document. It also animates the removal from the UI.
  /// If the Firestore update fails, it re-inserts the item and shows an error.
  void _deleteSubitem(String subitemId) {
    final index = _subitems.indexWhere((s) => s.id == subitemId);
    if (index == -1) return;

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
  /// Builds the widget.
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
          drawer: widget.isShared ? const ShareDrawer() : null,
          appBar: AppBar(
            title: GestureDetector(
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
                      final googleTasksService = GoogleTasksService();
                      try {
                        await googleTasksService.exportTasks(list);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('List exported to Google Tasks successfully!')),
                        );
                      } catch (e) {
                        debugPrint('Export to Google Tasks error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to export to Google Tasks: $e')),
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
                    value: 'autosort_and_group',
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_motion),
                        SizedBox(width: 8),
                        Text('Autosort & Group'),
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
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ShareListDialog(list: list),
                  );
                },
                child: const Icon(Icons.share),
                heroTag: 'share',
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                onPressed: () => _scanAndAppendItems(list),
                child: const Icon(Icons.camera_alt_outlined),
                heroTag: 'scan',
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DictateListDialog(list: list),
                  );
                },
                child: const Icon(Icons.mic_none),
                heroTag: 'dictate',
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
                    onLongPress: () => _addNewSubitem(isHeader: true),
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
                onDelete: () => _deleteSubitem(subitem.id),
                onSubmitted: () {
                  if (isNew) {
                    _addNewSubitem();
                  }
                },
              );
            },
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
    } finally {
      if (mounted) {
        setState(() {
          _isReturningFromPicker = false;
        });
      }
    }
  }
}
