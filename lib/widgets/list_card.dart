import 'package:flutter/material.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/widgets/circular_checkbox.dart';
import 'package:listify_mobile/widgets/list_detail_screen.dart';
import 'package:listify_mobile/widgets/read_only_subtask_item.dart';

class ListCard extends StatefulWidget {
  final ListModel list;
  final ValueChanged<bool?> onCompleted;

  const ListCard({super.key, required this.list, required this.onCompleted});

  @override
  State<ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<ListCard> with SingleTickerProviderStateMixin {
  late bool _optimisticCompleted;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
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
                }).toList(),
                const SizedBox(height: 8), // Add some padding at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}