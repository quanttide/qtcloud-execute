import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task.dart';
import '../models/task_list.dart';

/// API 错误：服务端非 2xx（4xx/5xx）。
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  /// HTTP 状态码
  final int statusCode;

  /// 服务端返回的错误信息
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 任务仓储：清单与任务的读写边界（DDD——内存 / 服务端 API，可注入）。
///
/// Cubit/页面只依赖本接口——测试注入 [InMemoryTaskRepository]，
/// 运行时注入 [ApiTaskRepository]（接入 provider API，服务端持久化）。
abstract class TaskRepository {
  /// 加载全部业务清单（动态——不静态假设）
  Future<List<TaskList>> loadLists();

  /// 加载指定清单的任务（看板投影数据源）
  Future<List<Task>> loadTasks(String listId);

  /// 更新指定清单中的任务：同 id 替换，不存在则新增
  Future<void> updateTask(String listId, Task task);

  /// 持久化到存储（API 实现：服务端随 [updateTask] 落盘，此处为无操作）
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

/// 服务端 API 实现——运行时仓储：对接 provider（qtcloud-execute）REST API。
///
/// 数据源在服务端（OSS），读写经：
/// - `GET  /api/lists`                        → 全部清单（含任务）
/// - `GET  /api/lists/{id}/tasks`             → 指定清单的任务
/// - `PUT  /api/lists/{id}/tasks/{taskId}`    → 更新/新增任务（upsert）
/// - `save()` 为无操作（服务端随 updateTask 落盘）
class ApiTaskRepository implements TaskRepository {
  ApiTaskRepository({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
      _client = client ?? http.Client();

  /// API 基地址（不含末尾斜杠），如 `https://execute-api.quanttide.com`
  final String _baseUrl;

  /// 可注入的 HTTP 客户端（测试可 mock）
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  @override
  Future<List<TaskList>> loadLists() async {
    final json = await _getJson('/api/lists');
    return [
      for (final list in parseSeedJson(json)) list.toTaskList(),
    ];
  }

  @override
  Future<List<Task>> loadTasks(String listId) async {
    final json = await _getJson('/api/lists/$listId/tasks');
    return [
      for (final t in json['tasks'] as List<dynamic>)
        Task.fromJson(t as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> updateTask(String listId, Task task) async {
    final resp = await _client.put(
      _uri('/api/lists/$listId/tasks/${task.id}'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    );
    _ensureOk(resp);
  }

  @override
  Future<void> save() async {
    // 服务端随 updateTask 落盘，无需单独保存。
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final resp = await _client.get(_uri(path));
    _ensureOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  void _ensureOk(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, resp.body);
    }
  }
}
