import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/models/task_list.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';

/// 读取测试夹具（测试 cwd 为 src/studio）
Map<String, dynamic> readFixtureJson() =>
    jsonDecode(File('test/fixtures/tasks.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('InMemoryTaskRepository（测试注入）', () {
    late InMemoryTaskRepository repository;

    setUp(() {
      repository = InMemoryTaskRepository.fromJson(readFixtureJson());
    });

    test('loadLists 返回全部 3 个清单（含任务，直接归属）', () async {
      final List<TaskList> lists = await repository.loadLists();
      expect(lists.map((l) => l.id), ['qtdata', 'qtclass', 'qtcloud']);
      expect(lists.map((l) => l.name), ['量潮数据', '量潮课堂', '量潮云']);
      // 任务平铺在清单下（无分组层级）
      expect(lists.firstWhere((l) => l.id == 'qtdata').tasks, hasLength(4));
      expect(lists.firstWhere((l) => l.id == 'qtclass').tasks, hasLength(3));
      expect(lists.firstWhere((l) => l.id == 'qtcloud').tasks, hasLength(4));
    });

    test('loadTasks 返回清单任务平铺列表（含 category）', () async {
      final List<Task> tasks = await repository.loadTasks('qtdata');
      expect(tasks, hasLength(4));
      expect(tasks.map((t) => t.id), [
        'qtdata-project-closeout',
        'qtdata-project-review',
        'qtdata-reproduction',
        'qtdata-product-research',
      ]);
      // category 用原分组名（business/product——业务自定义分类）
      expect(tasks.map((t) => t.category).toSet(), {'business', 'product'});
    });

    test('updateTask 替换同 id 任务', () async {
      final updated = Task(
        id: 'qtdata-reproduction',
        title: '客户项目复现（修订）',
        description: '数据清洗完成，进入交付。',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        category: 'product',
      );
      await repository.updateTask('qtdata', updated);

      final tasks = await repository.loadTasks('qtdata');
      expect(tasks, hasLength(4)); // 同 id 替换，数量不变
      expect(
        tasks.firstWhere((t) => t.id == 'qtdata-reproduction').title,
        '客户项目复现（修订）',
      );
    });

    test('updateTask 不存在则新增', () async {
      final created = Task(
        id: 'qtclass-new',
        title: '新任务',
        description: '新增描述',
        status: TaskStatus.notStarted,
        priority: TaskPriority.low,
        category: 'operation',
      );
      await repository.updateTask('qtclass', created);

      final tasks = await repository.loadTasks('qtclass');
      expect(tasks, hasLength(4)); // 3 已有 + 1 新增
      expect(tasks.last.id, 'qtclass-new');
    });

    test('未知清单抛 StateError；已知清单合法', () async {
      await expectLater(
        repository.loadTasks('unknown'),
        throwsStateError,
      );
      await expectLater(
        repository.updateTask(
          'qtdata',
          const Task(
            id: 'x',
            title: 'x',
            description: '',
            status: TaskStatus.notStarted,
            priority: TaskPriority.low,
          ),
        ),
        completes,
      );
    });

    test('save 为无操作，不抛错', () async {
      await expectLater(repository.save(), completes);
    });
  });
}
