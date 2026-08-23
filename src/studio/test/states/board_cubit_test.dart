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

    test('初始状态：空投影、无分类、无过滤', () {
      expect(cubit.state.tasks.columns, isEmpty);
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.selectedCategory, isNull);
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

    test('loadTasks 提取当前项目分类集合（去重保序）', () async {
      await cubit.loadTasks('qtdata');
      // qtdata 任务 category：business/product
      expect(cubit.state.categories, ['business', 'product']);

      await cubit.loadTasks('qtclass');
      // qtclass 任务 category：operation/product
      expect(cubit.state.categories, ['operation', 'product']);
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

    test('setCategory 过滤：只显示该分类任务（列投影收窄）', () async {
      await cubit.loadTasks('qtdata');

      cubit.setCategory('business');

      expect(cubit.state.selectedCategory, 'business');
      // business 分类任务：closeout（inProgress）+ review（reviewing）
      final BoardProjection projection = cubit.state.tasks;
      expect(
        projection.tasksOf(TaskStatus.inProgress).map((t) => t.id),
        ['qtdata-project-closeout'],
      );
      expect(
        projection.tasksOf(TaskStatus.reviewing).map((t) => t.id),
        ['qtdata-project-review'],
      );
      // 非 business（product）任务被过滤
      expect(
        projection.tasksOf(TaskStatus.inProgress),
        isNot(contains('qtdata-reproduction')),
      );
    });

    test('setCategory 切回全部（null）恢复完整投影', () async {
      await cubit.loadTasks('qtdata');
      cubit.setCategory('business');
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.inProgress),
        hasLength(1),
      );

      cubit.setCategory(null);

      expect(cubit.state.selectedCategory, isNull);
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.inProgress),
        hasLength(2),
      );
    });

    test('setCategory 未加载项目抛 StateError', () {
      expect(() => cubit.setCategory('business'), throwsStateError);
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

    test('createTask 生成 id 并追加到指定状态列', () async {
      await cubit.loadTasks('qtdata');

      const draft = TaskDraft(
        title: '新建任务',
        description: '',
        priority: TaskPriority.high,
        category: 'business',
      );
      await cubit.createTask(draft, status: TaskStatus.notStarted);

      // 投影含新任务（notStarted 列，category=business）
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.notStarted).map((t) => t.id),
        hasLength(1),
      );
      expect(
        cubit.state.tasks.tasksOf(TaskStatus.notStarted).single.category,
        'business',
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
