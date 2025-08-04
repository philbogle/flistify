
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/models/list.dart';
import 'package:listify_mobile/models/subitem.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('ListModel should correctly parse subitems with and without isHeader', () {
    // 1. Arrange
    final listId = 'testList1';
    final listData = {
      'title': 'My Test List',
      'completed': false,
      'createdAt': Timestamp.now(),
      'shareId': 'share123',
      'subtasks': [
        {'id': '1', 'title': 'Normal Item 1', 'completed': false},
        {'id': '2', 'title': 'Header Item', 'completed': false, 'isHeader': true},
        {'id': '3', 'title': 'Normal Item 2', 'completed': true, 'isHeader': false},
        {'id': '4', 'title': 'Another Normal Item', 'completed': false}, // Missing isHeader
      ],
    };

    // 2. Act
    final listModel = ListModel.fromMap(listId, listData);

    // 3. Assert
    expect(listModel.id, listId);
    expect(listModel.title, 'My Test List');
    expect(listModel.subitems.length, 4);

    final normalItem1 = listModel.subitems.firstWhere((s) => s.id == '1');
    expect(normalItem1.isHeader, isFalse);
    expect(normalItem1.title, 'Normal Item 1');

    final headerItem = listModel.subitems.firstWhere((s) => s.id == '2');
    expect(headerItem.isHeader, isTrue);
    expect(headerItem.title, 'Header Item');

    final normalItem2 = listModel.subitems.firstWhere((s) => s.id == '3');
    expect(normalItem2.isHeader, isFalse);
    expect(normalItem2.completed, isTrue);
    
    final normalItem3 = listModel.subitems.firstWhere((s) => s.id == '4');
    expect(normalItem3.isHeader, isFalse, reason: "isHeader should default to false if missing");
  });
}
