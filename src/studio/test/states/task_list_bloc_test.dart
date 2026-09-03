import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';
import 'package:qtcloud_execute_studio/states/task_list_bloc.dart';

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
  group('TaskListBloc（注入内存仓储）', () {
    late InMemoryTaskRepository repository;
    late TaskListBloc bloc;

    setUp(() {
      repository = InMemoryTaskRepository.fromJson(readFixtureJson());
      bloc = TaskListBloc(repository);
    });

    tearDown(() => bloc.close());

    test('初始状态：清单为空、无当前清单', () {
      expect(bloc.state.lists, isEmpty);
      expect(bloc.state.currentListId, isNull);
    });

    test('LoadLists 动态加载全部清单，默认选中第一个', () async {
      bloc.add(const TaskListLoadLists());
      await pump();

      expect(bloc.state.lists.map((l) => l.id), [
        'qtdata',
        'qtclass',
        'qtcloud',
      ]);
      expect(bloc.state.lists.map((l) => l.name), ['量潮数据', '量潮课堂', '量潮云']);
      expect(bloc.state.currentListId, 'qtdata');
    });

    test('SwitchList 切换当前清单', () async {
      bloc.add(const TaskListLoadLists());
      await pump();

      bloc.add(const TaskListSwitchList('qtclass'));
      await pump();
      expect(bloc.state.currentListId, 'qtclass');

      bloc.add(const TaskListSwitchList('qtcloud'));
      await pump();
      expect(bloc.state.currentListId, 'qtcloud');
    });

    test('清单切换后看板跟随：以新 currentListId 可加载任务', () async {
      bloc.add(const TaskListLoadLists());
      await pump();

      bloc.add(const TaskListSwitchList('qtclass'));
      await pump();

      // 看板跟随——用当前清单 id 加载任务，得到 qtclass 的平铺任务
      final List<Task> tasks = await repository.loadTasks(
        bloc.state.currentListId!,
      );
      expect(tasks, hasLength(3));
      expect(tasks.map((t) => t.id), [
        'qtclass-recruitment',
        'qtclass-mechanism',
        'qtclass-innovation',
      ]);
    });

    test('SwitchList 未知清单：状态不变（忽略，经 onError 记录）', () async {
      bloc.add(const TaskListLoadLists());
      await pump();

      bloc.add(const TaskListSwitchList('unknown'));
      await pump();

      expect(bloc.state.currentListId, 'qtdata');
      expect(bloc.state.lists, hasLength(3));
    });

    test('重复 LoadLists 保持已有 currentListId', () async {
      bloc.add(const TaskListLoadLists());
      await pump();
      bloc.add(const TaskListSwitchList('qtclass'));
      await pump();

      bloc.add(const TaskListLoadLists());
      await pump();

      expect(bloc.state.lists, hasLength(3));
      expect(bloc.state.currentListId, 'qtclass');
    });
  });
}
