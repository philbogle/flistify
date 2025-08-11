import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('ListModel edge cases', () {
    test('defaults when fields are missing or empty', () {
      final data = <String, dynamic>{};
      final model = ListModel.fromMap('id1', data);
      expect(model.id, 'id1');
      expect(model.title, 'Untitled');
      expect(model.completed, isFalse);
      expect(model.subitems, isEmpty);
      expect(model.createdAt, isA<Timestamp>());
      expect(model.shareId, isNull);
    });

    test('createdAt defaults to now when missing', () {
      final nowBefore = Timestamp.now();
      final model = ListModel.fromMap('id2', {
        'title': 'T',
        'subtasks': [],
      });
      final nowAfter = Timestamp.now();
      expect(model.createdAt.compareTo(nowBefore) >= 0, isTrue);
      expect(model.createdAt.compareTo(nowAfter) <= 0, isTrue);
    });

    test('parses provided fields correctly', () {
      final ts = Timestamp.fromMillisecondsSinceEpoch(1234567890);
      final model = ListModel.fromMap('id3', {
        'title': 'Hello',
        'completed': true,
        'createdAt': ts,
        'subtasks': [],
        'shareId': 's1',
      });
      expect(model.title, 'Hello');
      expect(model.completed, isTrue);
      expect(model.createdAt, ts);
      expect(model.shareId, 's1');
    });
  });
}

