import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';
import 'package:qtcloud_execute_studio/states/board_cubit.dart';

/// 读取测试夹具（测试 cwd 为 src/studio）
Map<String, dynamic> readFixtureJson() =>
    jsonDecode(File('test/fixtures/tasks.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('BoardCubit（注入内存仓储）', () {
    late InMemoryTaskRepository repository;
    late BoardCubit cubit;

    setUp(() {
      repository = InMemoryTaskRepository.fromJson(readFixtureJson());
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
      expect(projection.tasksOf(TaskStatus.inProgress).map((t) => t.id), [
        'qtdata-project-closeout',
        'qtdata-reproduction',
      ]);
      expect(projection.tasksOf(TaskStatus.reviewing).map((t) => t.id), [
        'qtdata-project-review',
        'qtdata-product-research',
      ]);
      expect(projection.tasksOf(TaskStatus.notStarted), isEmpty);
      expect(projection.tasksOf(TaskStatus.done), isEmpty);
    });

    test('清单切换：loadTasks 新清单，看板投影跟随', () async {
      await cubit.loadTasks('qtdata');
      expect(cubit.state.tasks.tasksOf(TaskStatus.inProgress), hasLength(2));

      await cubit.loadTasks('qtclass');

      final BoardProjection projection = cubit.state.tasks;
      expect(projection.columns.keys.toSet(), TaskStatus.values.toSet());
      expect(projection.tasksOf(TaskStatus.inProgress).map((t) => t.id), [
        'qtclass-recruitment',
        'qtclass-mechanism',
      ]);
      expect(projection.tasksOf(TaskStatus.reviewing).map((t) => t.id), [
        'qtclass-innovation',
      ]);
      // qtclass 无已完成任务
      expect(projection.tasksOf(TaskStatus.done), isEmpty);
    });

    test('updateTask 状态变更后重投影：任务跨列（自由来回）', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      final Task moved = base.moveTo(TaskStatus.done);

      await cubit.updateTask(moved);

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

    test('updateTask 允许回退（真看板——done 退回 reviewing）', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      final Task moved = base.moveTo(TaskStatus.done);
      await cubit.updateTask(moved);

      // 回退：done → reviewing
      final Task undone = moved.moveTo(TaskStatus.reviewing);
      await cubit.updateTask(undone);

      expect(
        cubit.state.tasks.tasksOf(TaskStatus.reviewing).map((t) => t.id),
        contains('qtdata-project-closeout'),
      );
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.done).map((t) => t.id),
        isNot(contains('qtdata-project-closeout')),
      );
    });

    test('updateTask 修改描述/优先级后重投影保留更新', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      final Task updated = base.copyWith(
        description: '数据清洗完成，进入交付。',
        priority: TaskPriority.urgent,
      );

      await cubit.updateTask(updated);

      final Task projected = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      expect(projected.description, '数据清洗完成，进入交付。');
      expect(projected.priority, TaskPriority.urgent);
    });

    test('updateTask 更新后的任务可被再次加载并投影', () async {
      await cubit.loadTasks('qtdata');

      final Task base = cubit.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      final Task advanced = base.moveTo(TaskStatus.reviewing);
      await cubit.updateTask(advanced);

      // 重新 loadTasks 后投影一致（仓储持久化）
      await cubit.loadTasks('qtdata');
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.reviewing).map((t) => t.id),
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

    test('deleteTask 从仓储移除并重投影', () async {
      await cubit.loadTasks('qtdata');

      await cubit.deleteTask('qtdata-project-closeout');

      // 投影不再包含已删除任务
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.inProgress).map((t) => t.id),
        isNot(contains('qtdata-project-closeout')),
      );
      // 仓储同步移除（4 → 3）
      final List<Task> stored = await repository.loadTasks('qtdata');
      expect(stored, hasLength(3));
    });

    test('createTask 生成 id 并追加到指定状态列', () async {
      await cubit.loadTasks('qtdata');

      const draft = TaskDraft(
        title: '新建任务',
        description: '',
        priority: TaskPriority.high,
      );
      await cubit.createTask(draft, status: TaskStatus.notStarted);

      // 投影含新任务（notStarted 列）
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.notStarted).map((t) => t.id),
        hasLength(1),
      );
      // 仓储持久化：总数 +1
      final List<Task> stored = await repository.loadTasks('qtdata');
      expect(stored, hasLength(5));
      expect(stored.last.title, '新建任务');
    });

    test('loadTasks 未指定清单时抛 StateError', () async {
      await expectLater(cubit.loadTasks(), throwsStateError);
    });
  });
}
