import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';
import 'package:qtcloud_execute_studio/states/board_bloc.dart';

/// 读取测试夹具（测试 cwd 为 src/studio）
Map<String, dynamic> readFixtureJson() =>
    jsonDecode(File('test/fixtures/tasks.json').readAsStringSync())
        as Map<String, dynamic>;

/// 等待事件处理完成（事件经多个微任务/定时器轮转）
Future<void> pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('BoardBloc（注入内存仓储）', () {
    late InMemoryTaskRepository repository;
    late BoardBloc bloc;

    setUp(() {
      repository = InMemoryTaskRepository.fromJson(readFixtureJson());
      bloc = BoardBloc(repository);
    });

    tearDown(() => bloc.close());

    test('初始状态：空投影、无错误', () {
      expect(bloc.state.tasks.columns, isEmpty);
      expect(bloc.state.writeToken, 0);
      expect(bloc.state.errorToken, 0);
    });

    test('LoadTasks 投影为状态列泳道（四列固定，任务按状态归列）', () async {
      bloc.add(const BoardLoadTasks('qtdata'));
      await pump();

      final projection = bloc.state.tasks;
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

    test('LoadTasks 未指定清单：错误信号（不抛异常）', () async {
      bloc.add(const BoardLoadTasks());
      await pump();

      expect(bloc.state.errorToken, 1);
      expect(bloc.state.errorMessage, contains('尚未指定项目'));
    });

    test('清单切换：LoadTasks 新清单，看板投影跟随', () async {
      bloc.add(const BoardLoadTasks('qtdata'));
      await pump();

      bloc.add(const BoardLoadTasks('qtclass'));
      await pump();

      final projection = bloc.state.tasks;
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

    test('UpdateTask 状态变更后重投影：任务跨列（自由来回）', () async {
      bloc.add(const BoardLoadTasks('qtdata'));
      await pump();

      final base = bloc.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      bloc.add(BoardUpdateTask(base.moveTo(TaskStatus.done)));
      await pump();

      final projection = bloc.state.tasks;
      expect(
        projection.tasksOf(TaskStatus.inProgress).map((t) => t.id),
        isNot(contains('qtdata-project-closeout')),
      );
      expect(
        projection.tasksOf(TaskStatus.done).map((t) => t.id),
        contains('qtdata-project-closeout'),
      );
      // 写成功信号：writeToken +1
      expect(bloc.state.writeToken, 1);
      // 仓储同步更新
      final stored = await repository.loadTasks('qtdata');
      expect(
        stored.firstWhere((t) => t.id == 'qtdata-project-closeout').status,
        TaskStatus.done,
      );
    });

    test('UpdateTask 允许回退（真看板——done 退回 reviewing）', () async {
      bloc.add(const BoardLoadTasks('qtdata'));
      await pump();

      final base = bloc.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-project-closeout');
      final moved = base.moveTo(TaskStatus.done);
      bloc.add(BoardUpdateTask(moved));
      await pump();

      // 回退：done → reviewing
      bloc.add(BoardUpdateTask(moved.moveTo(TaskStatus.reviewing)));
      await pump();

      expect(
        bloc.state.tasks.tasksOf(TaskStatus.reviewing).map((t) => t.id),
        contains('qtdata-project-closeout'),
      );
      expect(
        bloc.state.tasks.tasksOf(TaskStatus.done).map((t) => t.id),
        isNot(contains('qtdata-project-closeout')),
      );
    });

    test('UpdateTask 修改描述/优先级后重投影保留更新', () async {
      bloc.add(const BoardLoadTasks('qtdata'));
      await pump();

      final base = bloc.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      bloc.add(
        BoardUpdateTask(
          base.copyWith(
            description: '数据清洗完成，进入交付。',
            priority: TaskPriority.urgent,
          ),
        ),
      );
      await pump();

      final projected = bloc.state.tasks
          .tasksOf(TaskStatus.inProgress)
          .firstWhere((t) => t.id == 'qtdata-reproduction');
      expect(projected.description, '数据清洗完成，进入交付。');
      expect(projected.priority, TaskPriority.urgent);
    });

    test('DeleteTask 从仓储移除并重投影', () async {
      bloc.add(const BoardLoadTasks('qtdata'));
      await pump();

      bloc.add(const BoardDeleteTask('qtdata-project-closeout'));
      await pump();

      // 投影不再包含已删除任务
      expect(
        bloc.state.tasks.tasksOf(TaskStatus.inProgress).map((t) => t.id),
        isNot(contains('qtdata-project-closeout')),
      );
      // 仓储同步移除（4 → 3）
      final stored = await repository.loadTasks('qtdata');
      expect(stored, hasLength(3));
      expect(bloc.state.writeToken, 1);
    });

    test('DeleteTask 未知任务：错误信号，投影不变', () async {
      bloc.add(const BoardLoadTasks('qtdata'));
      await pump();

      bloc.add(const BoardDeleteTask('no-such-task'));
      await pump();

      expect(bloc.state.errorToken, 1);
      expect(bloc.state.errorMessage, isNotNull);
      // 投影保持删除前状态
      expect(bloc.state.tasks.tasksOf(TaskStatus.inProgress), hasLength(2));
    });

    test('CreateTask 生成 id 并追加到指定状态列', () async {
      bloc.add(const BoardLoadTasks('qtdata'));
      await pump();

      const draft = TaskDraft(
        title: '新建任务',
        description: '',
        priority: TaskPriority.high,
      );
      bloc.add(const BoardCreateTask(draft, status: TaskStatus.notStarted));
      await pump();

      // 投影含新任务（notStarted 列）
      expect(bloc.state.tasks.tasksOf(TaskStatus.notStarted), hasLength(1));
      // 仓储持久化：总数 +1
      final stored = await repository.loadTasks('qtdata');
      expect(stored, hasLength(5));
      expect(stored.last.title, '新建任务');
    });

    test('LoadTasks 未指定清单时错误信号而非抛异常（重复触发计次）', () async {
      bloc.add(const BoardLoadTasks());
      await pump();
      bloc.add(const BoardLoadTasks());
      await pump();

      expect(bloc.state.errorToken, 2);
    });
  });
}
