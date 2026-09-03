import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';

void main() {
  group('Task JSON 序列化', () {
    test('toJson → fromJson 往返无损（全字段）', () {
      const task = Task(
        id: 't-1',
        title: '财务平台部署',
        description: '完成财务平台在云环境的部署、配置与验收。',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
      );

      final Map<String, dynamic> json = task.toJson();
      expect(json, {
        'id': 't-1',
        'title': '财务平台部署',
        'description': '完成财务平台在云环境的部署、配置与验收。',
        'status': 'inProgress',
        'priority': 'urgent',
      });

      final Task restored = Task.fromJson(json);
      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.status, task.status);
      expect(restored.priority, task.priority);
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

  group('Task 状态流转（moveTo 自由来回）', () {
    const task = Task(
      id: 't-1',
      title: '标题',
      description: '描述',
      status: TaskStatus.notStarted,
      priority: TaskPriority.medium,
    );

    test('合法推进：未开始 → 进行中 → 评审中 → 已完成', () {
      final Task inProgress = task.moveTo(TaskStatus.inProgress);
      expect(inProgress.status, TaskStatus.inProgress);
      // 其余字段不变
      expect(inProgress.id, task.id);
      expect(inProgress.title, task.title);
      expect(inProgress.priority, task.priority);

      final Task reviewing = inProgress.moveTo(TaskStatus.reviewing);
      expect(reviewing.status, TaskStatus.reviewing);

      final Task done = reviewing.moveTo(TaskStatus.done);
      expect(done.status, TaskStatus.done);
    });

    test('允许跳级前进：未开始 → 已完成', () {
      final Task done = task.moveTo(TaskStatus.done);
      expect(done.status, TaskStatus.done);
    });

    test('允许回退（真看板——任务可退回重做）', () {
      final Task inProgress = task.moveTo(TaskStatus.inProgress);
      // 进行中 → 未开始（回退合法）
      final Task back = inProgress.moveTo(TaskStatus.notStarted);
      expect(back.status, TaskStatus.notStarted);

      final Task done = task.moveTo(TaskStatus.done);
      final Task undone = done.moveTo(TaskStatus.reviewing);
      expect(undone.status, TaskStatus.reviewing);
    });

    test('移动到相同状态视为无操作，返回自身', () {
      expect(task.moveTo(TaskStatus.notStarted), same(task));
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
