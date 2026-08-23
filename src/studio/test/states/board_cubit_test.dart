import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
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
      expect(cubit.state.tasks.columns, isEmpty);
    });

    test('loadTasks 投影为状态列泳道（四列固定，任务按状态归列）', () async {
      await cubit.loadTasks('qtdata');

      final BoardProjection projection = cubit.state.tasks;
      // 四列固定（推进阶梯完整）
      expect(projection.columns.keys.toSet(), TaskStatus.values.toSet());
      // qtdata：inProgress 列 2 个任务、reviewing 列 2 个、其余为空
      expect(
        projection.tasksOf(TaskStatus.inProgress).map((t) => t.id),
        ['qtdata-project-closeout', 'qtdata-reproduction'],
      );
      expect(
        projection.tasksOf(TaskStatus.reviewing).map((t) => t.id),
        ['qtdata-project-review', 'qtdata-product-research'],
      );
      expect(projection.tasksOf(TaskStatus.notStarted), isEmpty);
      expect(projection.tasksOf(TaskStatus.done), isEmpty);
    });

    test('清单切换：loadTasks 新清单，看板投影跟随', () async {
      await cubit.loadTasks('qtdata');
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.inProgress),
        hasLength(2),
      );

      await cubit.loadTasks('qtclass');

      final BoardProjection projection = cubit.state.tasks;
      expect(projection.columns.keys.toSet(), TaskStatus.values.toSet());
      expect(
        projection.tasksOf(TaskStatus.inProgress).map((t) => t.id),
        ['qtclass-recruitment', 'qtclass-mechanism'],
      );
      expect(
        projection.tasksOf(TaskStatus.reviewing).map((t) => t.id),
        ['qtclass-innovation'],
      );
      // qtclass 无已完成任务
      expect(projection.tasksOf(TaskStatus.done), isEmpty);
    });

    test('updateTask 状态推进后重投影：任务换列', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      final Task advanced = base.advanceTo(TaskStatus.done);

      await cubit.updateTask(advanced);

      final BoardProjection projection = cubit.state.tasks;
      expect(
        projection.tasksOf(TaskStatus.inProgress).map((t) => t.id),
        isNot(contains('qtdata-project-closeout')),
      );
      expect(
        projection.tasksOf(TaskStatus.done).map((t) => t.id),
        contains('qtdata-project-closeout'),
      );
      // 仓储同步更新
      final List<Task> stored = await repository.loadTasks('qtdata');
      final Task storedTask = stored.firstWhere(
        (t) => t.id == 'qtdata-project-closeout',
      );
      expect(storedTask.status, TaskStatus.done);
    });

    test('updateTask 修改描述/优先级/category 后重投影保留更新', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      final Task updated = base.copyWith(
        description: '数据清洗完成，进入交付。',
        priority: TaskPriority.urgent,
        category: '数据产品',
      );

      await cubit.updateTask(updated);

      final Task projected = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      expect(projected.description, '数据清洗完成，进入交付。');
      expect(projected.priority, TaskPriority.urgent);
      expect(projected.category, '数据产品');
    });

    test('状态流转：只前进（允许跳级），回退抛 StateError', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      // 跳级前进：inProgress → done
      final Task jumped = base.advanceTo(TaskStatus.done);
      expect(jumped.status, TaskStatus.done);
      // 回退抛错
      expect(() => jumped.advanceTo(TaskStatus.notStarted), throwsStateError);
      expect(() => jumped.advanceTo(TaskStatus.inProgress), throwsStateError);
      // 原地前进视为无操作
      expect(jumped.advanceTo(TaskStatus.done), same(jumped));

      // 更新后重投影为 done 列
      await cubit.updateTask(jumped);
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.done),
        contains(jumped),
      );
    });

    test('updateTask 更新后的任务可被再次加载并投影', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      final Task advanced = base.advanceTo(TaskStatus.reviewing);
      await cubit.updateTask(advanced);

      // 重新 loadTasks 后投影一致（仓储持久化）
      await cubit.loadTasks('qtdata');
      expect(
        cubit.state.tasks
            .tasksOf(TaskStatus.reviewing)
            .map((t) => t.id),
        contains('qtdata-reproduction'),
      );
    });

    test('updateTask 新增任务（id 不存在）→ 追加到清单并投影', () async {
      await cubit.loadTasks('qtdata');

      const Task created = Task(
        id: 'qtdata-new',
        title: '新增任务',
        description: '',
        status: TaskStatus.notStarted,
        priority: TaskPriority.low,
        category: 'business',
      );

      await cubit.updateTask(created);

      // 投影含新任务（notStarted 列）
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.notStarted).map((t) => t.id),
        contains('qtdata-new'),
      );
      // 仓储持久化
      final List<Task> stored = await repository.loadTasks('qtdata');
      expect(stored, hasLength(5)); // 4 已有 + 1 新增
    });

    test('loadTasks 未指定清单时抛 StateError', () async {
      await expectLater(cubit.loadTasks(), throwsStateError);
    });
  });
}
