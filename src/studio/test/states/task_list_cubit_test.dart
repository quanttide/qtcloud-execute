import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';
import 'package:qtcloud_execute_studio/states/task_list_cubit.dart';

/// 读取测试夹具（测试 cwd 为 src/studio）
Map<String, dynamic> readFixtureJson() =>
    jsonDecode(File('test/fixtures/tasks.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('TaskListCubit（注入内存仓储）', () {
    late InMemoryTaskRepository repository;
    late TaskListCubit cubit;

    setUp(() {
      repository = InMemoryTaskRepository.fromJson(readFixtureJson());
      cubit = TaskListCubit(repository);
    });

    tearDown(() => cubit.close());

    test('初始状态：清单为空、无当前清单', () {
      expect(cubit.state.lists, isEmpty);
      expect(cubit.state.currentListId, isNull);
    });

    test('loadLists 动态加载全部清单，默认选中第一个', () async {
      await cubit.loadLists();

      expect(cubit.state.lists.map((l) => l.id), [
        'qtdata',
        'qtclass',
        'qtcloud',
      ]);
      expect(cubit.state.lists.map((l) => l.name), ['量潮数据', '量潮课堂', '量潮云']);
      expect(cubit.state.currentListId, 'qtdata');
    });

    test('switchList 切换当前清单', () async {
      await cubit.loadLists();

      cubit.switchList('qtclass');
      expect(cubit.state.currentListId, 'qtclass');

      cubit.switchList('qtcloud');
      expect(cubit.state.currentListId, 'qtcloud');
    });

    test('清单切换后看板跟随：以新 currentListId 可加载任务', () async {
      await cubit.loadLists();

      cubit.switchList('qtclass');

      // 看板跟随——用当前清单 id 加载任务，得到 qtclass 的平铺任务
      final List<Task> tasks = await repository.loadTasks(
        cubit.state.currentListId!,
      );
      expect(tasks, hasLength(3));
      expect(tasks.map((t) => t.id), [
        'qtclass-recruitment',
        'qtclass-mechanism',
        'qtclass-innovation',
      ]);
    });

    test('switchList 未知清单抛 ArgumentError，状态不变', () async {
      await cubit.loadLists();
      final before = cubit.state.currentListId;

      expect(() => cubit.switchList('unknown'), throwsArgumentError);
      expect(cubit.state.currentListId, before);
      expect(cubit.state.lists, hasLength(3));
    });

    test('重复 loadLists 保持已有 currentListId', () async {
      await cubit.loadLists();
      cubit.switchList('qtclass');

      await cubit.loadLists();

      expect(cubit.state.lists, hasLength(3));
      expect(cubit.state.currentListId, 'qtclass');
    });
  });
}
