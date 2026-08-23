import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';

void main() {
  group('Task JSON 序列化', () {
    test('toJson → fromJson 往返无损（全字段，含 category）', () {
      const task = Task(
        id: 't-1',
        title: '财务平台部署',
        description: '完成财务平台在云环境的部署、配置与验收。',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        category: 'product',
      );

      final Map<String, dynamic> json = task.toJson();
      expect(json, {
        'id': 't-1',
        'title': '财务平台部署',
        'description': '完成财务平台在云环境的部署、配置与验收。',
        'status': 'inProgress',
        'priority': 'urgent',
        'category': 'product',
      });

      final Task restored = Task.fromJson(json);
      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.status, task.status);
      expect(restored.priority, task.priority);
      expect(restored.category, task.category);
    });

    test('category 可选：缺省/为 null 时解析为 null，序列化保留 null', () {
      final Task fromJson = Task.fromJson({
        'id': 'x',
        'title': '标题',
        'description': '描述',
        'status': 'notStarted',
        'priority': 'low',
      });
      expect(fromJson.category, isNull);

      final Task explicitNull = Task.fromJson({
        'id': 'x',
        'title': '标题',
        'description': '描述',
        'status': 'notStarted',
        'priority': 'low',
        'category': null,
      });
      expect(explicitNull.category, isNull);

      // 往返：null 序列化为 null（不丢字段）
      expect(fromJson.toJson()['category'], isNull);
    });

    test('category 业务自定义字符串（不枚举约束）', () {
      const custom = Task(
        id: 'x',
        title: '标题',
        description: '',
        status: TaskStatus.notStarted,
        priority: TaskPriority.low,
        category: '科研', // 任意自定义分类值
      );
      expect(custom.toJson()['category'], '科研');
      expect(Task.fromJson(custom.toJson()).category, '科研');
    });

    test('status/priority 覆盖全部枚举值的往返', () {
      for (final status in TaskStatus.values) {
        for (final priority in TaskPriority.values) {
          final Task task = Task.fromJson({
            'id': 'x',
            'title': '标题',
            'description': '描述',
            'status': status.wire,
            'priority': priority.wire,
          });
          expect(task.status, status);
          expect(task.priority, priority);
          expect(task.toJson()['status'], status.wire);
          expect(task.toJson()['priority'], priority.wire);
        }
      }
    });

    test('未知 status/priority 抛 ArgumentError', () {
      expect(
        () => Task.fromJson({
          'id': 'x',
          'title': '标题',
          'description': '描述',
          'status': 'archived',
          'priority': 'medium',
        }),
        throwsArgumentError,
      );
      expect(
        () => Task.fromJson({
          'id': 'x',
          'title': '标题',
          'description': '描述',
          'status': 'done',
          'priority': 'critical',
        }),
        throwsArgumentError,
      );
    });
  });

  group('Task 状态流转（只前进）', () {
    const task = Task(
      id: 't-1',
      title: '标题',
      description: '描述',
      status: TaskStatus.notStarted,
      priority: TaskPriority.medium,
    );

    test('合法推进：未开始 → 进行中 → 评审中 → 已完成', () {
      final Task inProgress = task.advanceTo(TaskStatus.inProgress);
      expect(inProgress.status, TaskStatus.inProgress);
      // 其余字段不变
      expect(inProgress.id, task.id);
      expect(inProgress.title, task.title);
      expect(inProgress.priority, task.priority);

      final Task reviewing = inProgress.advanceTo(TaskStatus.reviewing);
      expect(reviewing.status, TaskStatus.reviewing);

      final Task done = reviewing.advanceTo(TaskStatus.done);
      expect(done.status, TaskStatus.done);
    });

    test('允许跳级前进：未开始 → 已完成', () {
      final Task done = task.advanceTo(TaskStatus.done);
      expect(done.status, TaskStatus.done);
    });

    test('推进到相同状态视为无操作，返回自身', () {
      expect(task.advanceTo(TaskStatus.notStarted), same(task));
    });

    test('非法回退抛 StateError：进行中 → 未开始', () {
      final Task inProgress = task.advanceTo(TaskStatus.inProgress);
      expect(
        () => inProgress.advanceTo(TaskStatus.notStarted),
        throwsStateError,
      );
    });

    test('非法回退抛 StateError：已完成 → 评审中', () {
      final Task done = task.advanceTo(TaskStatus.done);
      expect(
        () => done.advanceTo(TaskStatus.reviewing),
        throwsStateError,
      );
    });

    test('copyWith 只改指定字段', () {
      final Task changed = task.copyWith(
        title: '新标题',
        priority: TaskPriority.high,
      );
      expect(changed.title, '新标题');
      expect(changed.priority, TaskPriority.high);
      expect(changed.id, task.id);
      expect(changed.description, task.description);
      expect(changed.status, task.status);
    });

    test('copyWith 设置/清空 category（哨兵区分未提供与置 null）', () {
      // 设置
      final Task withCategory = task.copyWith(category: 'product');
      expect(withCategory.category, 'product');
      // 未提供：保持原值
      final Task unchanged = withCategory.copyWith(title: '新标题');
      expect(unchanged.category, 'product');
      // 显式清空：置 null
      final Task cleared = withCategory.copyWith(category: null);
      expect(cleared.category, isNull);
      // 清空后未提供仍为 null
      expect(cleared.copyWith(priority: TaskPriority.high).category, isNull);
    });
  });

  group('枚举', () {
    test('TaskStatus 四态顺序与文案', () {
      expect(TaskStatus.values, [
        TaskStatus.notStarted,
        TaskStatus.inProgress,
        TaskStatus.reviewing,
        TaskStatus.done,
      ]);
      expect(TaskStatus.notStarted.label, '未开始');
      expect(TaskStatus.inProgress.label, '进行中');
      expect(TaskStatus.reviewing.label, '评审中');
      expect(TaskStatus.done.label, '已完成');
    });

    test('TaskPriority 四档顺序与文案', () {
      expect(TaskPriority.values, [
        TaskPriority.urgent,
        TaskPriority.high,
        TaskPriority.medium,
        TaskPriority.low,
      ]);
      expect(TaskPriority.urgent.label, '紧急');
      expect(TaskPriority.high.label, '高');
      expect(TaskPriority.medium.label, '中');
      expect(TaskPriority.low.label, '低');
    });
  });
}
