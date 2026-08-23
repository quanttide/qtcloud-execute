import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/models/task_list.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';
import 'package:qtcloud_execute_studio/states/board_cubit.dart';

/// 读取种子文件（测试 cwd 为 src/studio）
Map<String, dynamic> readSeedJson() =>
    jsonDecode(File('assets/data/seed_tasks.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('BoardCubit（注入内存仓储）', () {
    late InMemoryTaskRepository repository;
    late BoardCubit cubit;

    setUp(() {
      repository = InMemoryTaskRepository.fromJson(readSeedJson());
      cubit = BoardCubit(repository);
    });

    tearDown(() => cubit.close());

    test('初始状态：空投影', () {
      expect(cubit.state.tasks.matrix, isEmpty);
    });

    test('loadTasks 投影为 分组×状态 矩阵（列=分组，行=状态）', () async {
      await cubit.loadTasks('qtdata');

      final BoardProjection projection = cubit.state.tasks;
      // 列 = 该清单实际存在的分组
      expect(projection.matrix.keys.toSet(),
          {Group.business, Group.product});
      // 行 = 全部四状态（每个分组行完整）
      for (final group in projection.matrix.keys) {
        expect(projection.matrix[group]!.keys.toSet(),
            TaskStatus.values.toSet());
      }
      // qtdata：business 列 inProgress/reviewing 各 1 个任务
      expect(
          projection
              .tasksOf(Group.business, TaskStatus.inProgress)
              .map((t) => t.id),
          ['qtdata-project-closeout']);
      expect(
          projection
              .tasksOf(Group.business, TaskStatus.reviewing)
              .map((t) => t.id),
          ['qtdata-project-review']);
      expect(
          projection
              .tasksOf(Group.product, TaskStatus.inProgress)
              .map((t) => t.id),
          ['qtdata-reproduction']);
      // 未出现状态行为空
      expect(projection.tasksOf(Group.business, TaskStatus.notStarted),
          isEmpty);
    });

    test('清单切换：loadTasks 新清单，看板投影跟随', () async {
      await cubit.loadTasks('qtdata');
      expect(cubit.state.tasks.matrix.keys.toSet(),
          {Group.business, Group.product});

      await cubit.loadTasks('qtclass');

      final BoardProjection projection = cubit.state.tasks;
      expect(projection.matrix.keys.toSet(),
          {Group.operation, Group.product});
      expect(
          projection
              .tasksOf(Group.operation, TaskStatus.inProgress)
              .map((t) => t.id),
          ['qtclass-recruitment', 'qtclass-mechanism']);
      expect(
          projection.tasksOf(Group.product, TaskStatus.reviewing).map((t) => t.id),
          ['qtclass-innovation']);
      expect(projection.matrix.containsKey(Group.business), isFalse);
    });

    test('updateTask 状态推进后重投影：任务换行', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(Group.business, TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      final Task advanced = base.advanceTo(TaskStatus.done);

      await cubit.updateTask(advanced);

      final BoardProjection projection = cubit.state.tasks;
      expect(
          projection
              .tasksOf(Group.business, TaskStatus.inProgress)
              .map((t) => t.id),
          isNot(contains('qtdata-project-closeout')));
      expect(
          projection
              .tasksOf(Group.business, TaskStatus.done)
              .map((t) => t.id),
          contains('qtdata-project-closeout'));
      // 仓储同步更新
      final Map<Group, List<Task>> stored =
          await repository.loadTasks('qtdata');
      final Task storedTask = stored[Group.business]!
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      expect(storedTask.status, TaskStatus.done);
    });

    test('updateTask 修改描述/优先级后重投影保留更新', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(Group.product, TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      final Task updated = base.copyWith(
        description: '数据清洗完成，进入交付。',
        priority: TaskPriority.urgent,
      );

      await cubit.updateTask(updated);

      final Task projected = cubit.state.tasks
          .tasksOf(Group.product, TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      expect(projected.description, '数据清洗完成，进入交付。');
      expect(projected.priority, TaskPriority.urgent);
    });

    test('状态流转：只前进（允许跳级），回退抛 StateError', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(Group.business, TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      // 跳级前进：inProgress → done
      final Task jumped = base.advanceTo(TaskStatus.done);
      expect(jumped.status, TaskStatus.done);
      // 回退抛错
      expect(() => jumped.advanceTo(TaskStatus.notStarted), throwsStateError);
      expect(() => jumped.advanceTo(TaskStatus.inProgress), throwsStateError);
      // 原地前进视为无操作
      expect(jumped.advanceTo(TaskStatus.done), same(jumped));

      // 更新后重投影为 done 行
      await cubit.updateTask(jumped);
      expect(
          cubit.state.tasks.tasksOf(Group.business, TaskStatus.done),
          contains(jumped));
    });

    test('updateTask 更新后的任务可被再次加载并投影', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(Group.product, TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      final Task advanced = base.advanceTo(TaskStatus.reviewing);
      await cubit.updateTask(advanced);

      // 重新 loadTasks 后投影一致（仓储持久化）
      await cubit.loadTasks('qtdata');
      expect(
          cubit.state.tasks
              .tasksOf(Group.product, TaskStatus.reviewing)
              .map((t) => t.id),
          contains('qtdata-reproduction'));
    });

    test('updateTask 未知任务（不在当前清单）抛 StateError', () async {
      await cubit.loadTasks('qtdata');

      const Task alien = Task(
        id: 'qtclass-recruitment',
        title: '实训基地招聘运营',
        description: '',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
      );

      await expectLater(cubit.updateTask(alien), throwsStateError);
    });

    test('loadTasks 未指定清单时抛 StateError', () async {
      await expectLater(cubit.loadTasks(), throwsStateError);
    });
  });
}
