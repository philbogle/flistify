class Subitem {
  final String id;
  final String title;
  final bool completed;

  Subitem({required this.id, required this.title, required this.completed});

  factory Subitem.fromMap(Map<String, dynamic> data) {
    return Subitem(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Untitled',
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }
}
