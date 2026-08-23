import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task_list.dart';

void main() {
  group('Group 枚举', () {
    test('固定三职能：business / product / operation', () {
      expect(Group.values, [Group.business, Group.product, Group.operation]);
      expect(Group.business.label, '业务');
      expect(Group.product.label, '产品');
      expect(Group.operation.label, '运营');
    });

    test('fromWire 解析与未知值拒绝', () {
      expect(Group.fromWire('business'), Group.business);
      expect(Group.fromWire('product'), Group.product);
      expect(Group.fromWire('operation'), Group.operation);
      expect(() => Group.fromWire('finance'), throwsArgumentError);
    });
  });

  group('TaskList JSON 序列化', () {
    test('toJson → fromJson 往返无损', () {
      const list = TaskList(
        id: 'qtdata',
        name: '量潮数据',
        groups: [Group.business, Group.product, Group.operation],
      );

      final Map<String, dynamic> json = list.toJson();
      expect(json, {
        'id': 'qtdata',
        'name': '量潮数据',
        'groups': ['business', 'product', 'operation'],
      });

      final TaskList restored = TaskList.fromJson(json);
      expect(restored.id, list.id);
      expect(restored.name, list.name);
      expect(restored.groups, list.groups);
    });

    test('分组定义可子集（业务清单不必覆盖全部职能）', () {
      const list = TaskList(id: 'qtcloud', name: '量潮云', groups: [Group.product]);
      expect(list.hasGroup(Group.product), isTrue);
      expect(list.hasGroup(Group.business), isFalse);
      expect(list.hasGroup(Group.operation), isFalse);
    });
  });
}
