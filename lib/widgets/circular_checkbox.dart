
import 'package:flutter/material.dart';

/// A circular checkbox widget.
class CircularCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const CircularCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  /// Builds the widget.
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged?.call(!value);
      },
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: value ? Theme.of(context).primaryColor : Colors.grey,
            width: 2.0,
          ),
          color: value ? Theme.of(context).primaryColor : Colors.transparent,
        ),
        child: value
            ? const Icon(
                Icons.check,
                size: 20.0,
                color: Colors.white,
              )
            : const SizedBox(
                width: 20.0,
                height: 20.0,
              ),
      ),
    );
  }
}
