import 'dart:convert';
import 'dart:io';

import '../models/task.dart';
import '../models/task_list.dart';

/// 任务仓储：清单与任务的读写边界（DDD——种子/本地文件，可注入）。
///
/// Cubit/页面只依赖本接口——测试注入 [InMemoryTaskRepository]，运行时用
/// [LocalFileTaskRepository]。
abstract class TaskRepository {
  /// 加载全部业务清单（动态——不静态假设）
  Future<List<TaskList>> loadLists();

  /// 加载指定清单的任务（看板投影数据源）
  Future<List<Task>> loadTasks(String listId);

  /// 更新指定清单中的任务：同 id 替换，不存在则新增
  Future<void> updateTask(String listId, Task task);

  /// 持久化到存储（本地文件原子写；内存实现为无操作）
  Future<void> save();
}

/// 清单聚合数据：清单元数据 + 任务（种子与保存共用的持久化形状）
class TaskListData {
  TaskListData({required this.id, required this.name, required this.tasks});

  /// 从 JSON 解析清单片段：
  /// ```json
  /// {"id": "qtdata", "name": "量潮数据", "tasks": [...]}
  /// ```
  factory TaskListData.fromJson(Map<String, dynamic> json) => TaskListData(
    id: json['id'] as String,
    name: json['name'] as String,
    tasks: [
      for (final t in json['tasks'] as List<dynamic>)
        Task.fromJson(t as Map<String, dynamic>),
    ],
  );

  /// 业务标识
  final String id;

  /// 业务名称
  final String name;

  /// 清单内任务（直接归属）
  final List<Task> tasks;

  /// JSON 序列化（保存/种子共用形状）
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tasks': [for (final t in tasks) t.toJson()],
  };

  TaskList toTaskList() => TaskList(id: id, name: name, tasks: tasks);
}

/// 种子/持久化文件的顶层形状：`{"lists": [...]}`
List<TaskListData> parseSeedJson(Map<String, dynamic> json) => [
  for (final e in json['lists'] as List<dynamic>)
    TaskListData.fromJson(e as Map<String, dynamic>),
];

/// 序列化回顶层形状（save 写回 / 种子构造）
Map<String, dynamic> seedToJson(List<TaskListData> lists) => {
  'lists': [for (final list in lists) list.toJson()],
};

/// 在聚合数据中更新任务：同 id 替换，不存在则新增。
///
/// 清单不存在时抛 [StateError]。
void updateTaskInData(
  Map<String, TaskListData> data,
  String listId,
  Task task,
) {
  final list = data[listId];
  if (list == null) {
    throw StateError('清单不存在：$listId');
  }
  final index = list.tasks.indexWhere((t) => t.id == task.id);
  if (index == -1) {
    list.tasks.add(task);
  } else {
    list.tasks[index] = task;
  }
}

/// 内存实现——测试注入（不碰文件/网络）
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository(this._lists);

  /// 从种子 JSON（顶层 `{"lists": [...]}`）构建
  factory InMemoryTaskRepository.fromJson(Map<String, dynamic> json) =>
      InMemoryTaskRepository({
        for (final list in parseSeedJson(json)) list.id: list,
      });

  final Map<String, TaskListData> _lists;

  @override
  Future<List<TaskList>> loadLists() async =>
      [for (final list in _lists.values) list.toTaskList()];

  @override
  Future<List<Task>> loadTasks(String listId) async {
    final list = _lists[listId];
    if (list == null) {
      throw StateError('清单不存在：$listId');
    }
    return List<Task>.unmodifiable(list.tasks);
  }

  @override
  Future<void> updateTask(String listId, Task task) async {
    updateTaskInData(_lists, listId, task);
  }

  @override
  Future<void> save() async {
    // 内存实现：无需持久化
  }
}

/// 本地 JSON 文件实现——运行时仓储。
///
/// 首次读取载入内存；[save] 原子写回（临时文件 + rename），避免写一半损坏。
class LocalFileTaskRepository implements TaskRepository {
  LocalFileTaskRepository(this.file);

  final File file;

  Map<String, TaskListData>? _data;

  Future<Map<String, TaskListData>> _load() async {
    final data = _data;
    if (data != null) return data;
    if (!await file.exists()) {
      throw FileSystemException('数据文件不存在：${file.path}');
    }
    final raw = await file.readAsString();
    final loaded = {
      for (final list in parseSeedJson(jsonDecode(raw) as Map<String, dynamic>))
        list.id: list,
    };
    _data = loaded;
    return loaded;
  }

  @override
  Future<List<TaskList>> loadLists() async {
    final data = await _load();
    return [for (final list in data.values) list.toTaskList()];
  }

  @override
  Future<List<Task>> loadTasks(String listId) async {
    final data = await _load();
    final list = data[listId];
    if (list == null) {
      throw StateError('清单不存在：$listId');
    }
    return List<Task>.unmodifiable(list.tasks);
  }

  @override
  Future<void> updateTask(String listId, Task task) async {
    final data = await _load();
    updateTaskInData(data, listId, task);
  }

  @override
  Future<void> save() async {
    final data = _data;
    if (data == null) {
      // 尚未加载，无内容可存
      return;
    }
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        seedToJson(data.values.toList()),
      ),
      flush: true,
    );
    await temp.rename(file.path);
  }
}