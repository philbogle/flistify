import 'package:flutter/material.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';
import 'package:listify_mobile/widgets/list_detail_screen.dart';
import 'package:listify_mobile/widgets/read_only_subtask_item.dart';

/// A card that displays a preview of a list.
class ListCard extends StatefulWidget {
  final ListModel list;
  final ValueChanged<bool?> onCompleted;

  const ListCard({super.key, required this.list, required this.onCompleted});

  @override
  State<ListCard> createState() => _ListCardState();
}

/// State class for [ListCard].
class _ListCardState extends State<ListCard> with SingleTickerProviderStateMixin {
  late bool _optimisticCompleted;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  /// Initializes the state of the widget.
  ///
  /// This method is called once when the widget is inserted into the widget tree.
  /// It initializes the [_optimisticCompleted] state with the list's completed status,
  /// and sets up the [_animationController] and [_animation] for the card's animation.
  void initState() {
    super.initState();
    _optimisticCompleted = widget.list.completed;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  /// Disposes of the animation controller when the widget is disposed.
  ///
  /// This method is called when the widget is removed from the widget tree.
  /// It disposes of the [_animationController] to prevent memory leaks.
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  /// Called when the widget is re-built with new parameters.
  ///
  /// This method is called when the widget's configuration changes.
  /// It updates the [_optimisticCompleted] state if the list's completed
  /// status has changed.
  void didUpdateWidget(ListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.list.completed != oldWidget.list.completed) {
      _optimisticCompleted = widget.list.completed;
    }
  }

  void _handleCheckboxChanged(bool? value) {
    if (value == null) return;

    setState(() {
      _optimisticCompleted = value;
    });

    if (value) {
      _animationController.forward().then((_) {
        widget.onCompleted(value);
      });
    } else {
      widget.onCompleted(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation.drive(Tween(begin: 1.0, end: 0.0)),
      child: SizeTransition(
        sizeFactor: _animation.drive(Tween(begin: 1.0, end: 0.0)),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ListDetailScreen(listId: widget.list.id),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            child: Column(
              children: [
                ListTile(
                  leading: CircularCheckbox(
                    value: _optimisticCompleted,
                    onChanged: _handleCheckboxChanged,
                  ),
                  title: Text(
                    widget.list.title,
                    style: TextStyle(
                      decoration: _optimisticCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: _optimisticCompleted ? Colors.grey : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ...widget.list.subitems
                    .where((s) => s.title.isNotEmpty)
                    .map((subitem) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 32.0),
                        child: ReadOnlySubtaskItem(
                            subitem: subitem, listId: widget.list.id),
                      );
                    }),
                const SizedBox(height: 8), // Add some padding at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}