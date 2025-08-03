import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A widget that displays a shimmer placeholder.
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerPlaceholder({super.key, this.width = double.infinity, required this.height});

  @override
  /// Builds the widget.
  ///
  /// This method constructs the shimmer effect using [Shimmer.fromColors]
  /// and a [Container] as the placeholder shape.
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }
}
