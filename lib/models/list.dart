import 'package:cloud_firestore/cloud_firestore.dart';
import 'subitem.dart';

/// A model that represents a list.
class ListModel {
  final String id;
  final String title;
  final bool completed;
  final List<Subitem> subitems;
  final Timestamp createdAt;
  final String? shareId;

  ListModel({
    required this.id,
    required this.title,
    required this.completed,
    required this.subitems,
    required this.createdAt,
    this.shareId,
  });

  /// Creates a [ListModel] from a map of data.
  factory ListModel.fromMap(String id, Map<String, dynamic> data) {
    return ListModel(
      id: id,
      title: data['title'] ?? 'Untitled',
      completed: data['completed'] ?? false,
      subitems: (data['subtasks'] as List<dynamic>? ?? [])
          .map((item) => Subitem.fromMap(item as Map<String, dynamic>))
          .toList(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      shareId: data['shareId'] as String?,
    );
  }
}