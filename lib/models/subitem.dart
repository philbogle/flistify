class Subitem {
  final String id;
  final String title;
  final bool completed;
  final bool isHeader;

  Subitem({required this.id, required this.title, required this.completed, this.isHeader = false});

  factory Subitem.fromMap(Map<String, dynamic> data) {
    return Subitem(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Untitled',
      completed: data['completed'] ?? false,
      isHeader: data['isHeader'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'isHeader': isHeader,
    };
  }
}
