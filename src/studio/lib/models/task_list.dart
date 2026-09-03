import 'task.dart';

/// 业务清单（实体）——一个业务一个清单
///
/// 任务直接属于清单（无分组层级）。
class TaskList {
  const TaskList({required this.id, required this.name, required this.tasks});

  /// 从 JSON 解析；tasks 平铺在清单下
  factory TaskList.fromJson(Map<String, dynamic> json) => TaskList(
    id: json['id'] as String,
    name: json['name'] as String,
    tasks: [
      for (final t in json['tasks'] as List<dynamic>? ?? const [])
        Task.fromJson(t as Map<String, dynamic>),
    ],
  );

  /// 业务标识（qtdata / qtclass / qtcloud…）
  final String id;

  /// 业务名称
  final String name;

  /// 清单内任务（直接归属，无分组层级）
  final List<Task> tasks;

  /// JSON 序列化（元数据 + 任务列表）
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tasks': [for (final t in tasks) t.toJson()],
  };
}
