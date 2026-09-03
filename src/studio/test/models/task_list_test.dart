import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/models/task_list.dart';

void main() {
  group('TaskList JSON 序列化', () {
    test('toJson → fromJson 往返无损（含任务列表）', () {
      const list = TaskList(
        id: 'qtdata',
        name: '量潮数据',
        tasks: [
          Task(
            id: 't-1',
            title: '客户项目结项推进',
            description: '结项收尾沟通',
            status: TaskStatus.inProgress,
            priority: TaskPriority.high,
          ),
          Task(
            id: 't-2',
            title: '数据产品调研',
            description: '',
            status: TaskStatus.reviewing,
            priority: TaskPriority.medium,
          ),
        ],
      );

      final Map<String, dynamic> json = list.toJson();
      expect(json, {
        'id': 'qtdata',
        'name': '量潮数据',
        'tasks': [
          {
            'id': 't-1',
            'title': '客户项目结项推进',
            'description': '结项收尾沟通',
            'status': 'inProgress',
            'priority': 'high',
          },
          {
            'id': 't-2',
            'title': '数据产品调研',
            'description': '',
            'status': 'reviewing',
            'priority': 'medium',
          },
        ],
      });

      final TaskList restored = TaskList.fromJson(json);
      expect(restored.id, list.id);
      expect(restored.name, list.name);
      expect(restored.tasks, hasLength(2));
      expect(restored.tasks.map((t) => t.id), ['t-1', 't-2']);
    });

    test('任务直接属于清单（无分组层级）', () {
      const list = TaskList(
        id: 'qtcloud',
        name: '量潮云',
        tasks: [
          Task(
            id: 'c-1',
            title: '财务平台部署',
            description: '',
            status: TaskStatus.inProgress,
            priority: TaskPriority.urgent,
          ),
        ],
      );

      expect(list.tasks, hasLength(1));
      expect(list.tasks.single.title, '财务平台部署');
      // tasks 字段缺省时解析为空列表（旧数据兼容）
      final TaskList noTasks = TaskList.fromJson({
        'id': 'empty',
        'name': '空清单',
      });
      expect(noTasks.tasks, isEmpty);
    });
  });
}
