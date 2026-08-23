import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/models/task_list.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';

/// 读取种子文件（测试 cwd 为 src/studio）
Map<String, dynamic> readSeedJson() =>
    jsonDecode(File('assets/data/seed_tasks.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('InMemoryTaskRepository（测试注入）', () {
    late InMemoryTaskRepository repository;

    setUp(() {
      repository = InMemoryTaskRepository.fromJson(readSeedJson());
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

  group('LocalFileTaskRepository（临时目录读写）', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('qtcloud_repo_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('从种子文件加载：清单与平铺任务一致', () async {
      final File file = File('${tempDir.path}/seed.json')
        ..writeAsStringSync(jsonEncode(readSeedJson()));

      final repository = LocalFileTaskRepository(file);
      final List<TaskList> lists = await repository.loadLists();
      expect(lists, hasLength(3));

      final List<Task> tasks = await repository.loadTasks('qtcloud');
      expect(tasks.map((t) => t.id), [
        'qtcloud-finance-deploy',
        'qtcloud-agenda-iteration',
        'qtcloud-toolkit-refactor',
        'qtcloud-doc-center',
      ]);
      expect(tasks.every((t) => t.category == 'product'), isTrue);
    });

    test('updateTask + save 原子写回，重读可见', () async {
      final File file = File('${tempDir.path}/seed.json')
        ..writeAsStringSync(jsonEncode(readSeedJson()));

      final repository = LocalFileTaskRepository(file);
      await repository.updateTask(
        'qtcloud',
        Task(
          id: 'qtcloud-finance-deploy',
          title: '财务平台部署（已上线）',
          description: '部署完成并通过验收。',
          status: TaskStatus.done,
          priority: TaskPriority.urgent,
          category: 'product',
        ),
      );
      await repository.save();

      // 重读文件：更新已持久化
      final reopened = LocalFileTaskRepository(file);
      final List<Task> tasks = await reopened.loadTasks('qtcloud');
      final task = tasks.firstWhere((t) => t.id == 'qtcloud-finance-deploy');
      expect(task.title, '财务平台部署（已上线）');
      expect(task.status, TaskStatus.done);
      // 未修改的任务不受影响
      expect(tasks.map((t) => t.id), [
        'qtcloud-finance-deploy',
        'qtcloud-agenda-iteration',
        'qtcloud-toolkit-refactor',
        'qtcloud-doc-center',
      ]);

      // 文件仍是合法 JSON 且往返无损
      final Map<String, dynamic> raw =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final parsed = parseSeedJson(raw);
      expect(parsed, hasLength(3));
      final deployTask = parsed
          .firstWhere((l) => l.id == 'qtcloud')
          .tasks
          .firstWhere((t) => t.id == 'qtcloud-finance-deploy');
      expect(deployTask.toJson()['status'], 'done');
    });

    test('文件不存在时 loadLists 抛 FileSystemException', () async {
      final repository = LocalFileTaskRepository(
        File('${tempDir.path}/missing.json'),
      );
      await expectLater(
        repository.loadLists(),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('save 之前未加载则无操作', () async {
      final File file = File('${tempDir.path}/empty.json');
      final repository = LocalFileTaskRepository(file);
      await expectLater(repository.save(), completes);
      expect(await file.exists(), isFalse);
    });
  });
}
