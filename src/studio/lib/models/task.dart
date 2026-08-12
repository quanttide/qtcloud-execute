/// 任务角色（RACI 分工）
class TaskRole {
  const TaskRole({required this.role, required this.desc});

  factory TaskRole.fromJson(Map<String, dynamic> json) =>
      TaskRole(role: json['role'] as String, desc: json['desc'] as String);

  final String role;
  final String desc;
}

/// 任务阶段
class TaskPhase {
  const TaskPhase({required this.phase, required this.content});

  factory TaskPhase.fromJson(Map<String, dynamic> json) => TaskPhase(
    phase: json['phase'] as String,
    content: json['content'] as String,
  );

  final String phase;
  final String content;
}

/// 执行任务（GTD 任务档案）
class Task {
  const Task({
    required this.id,
    required this.name,
    required this.doc,
    required this.dependsOn,
    required this.requirement,
    required this.goal,
    required this.acceptance,
    required this.roles,
    required this.phases,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    name: json['name'] as String,
    doc: json['doc'] as String,
    dependsOn: json['depends_on'] as String?,
    requirement: json['requirement'] as String,
    goal: json['goal'] as String,
    acceptance: (json['acceptance'] as List<dynamic>).cast<String>(),
    roles: (json['roles'] as List<dynamic>)
        .map((e) => TaskRole.fromJson(e as Map<String, dynamic>))
        .toList(),
    phases: (json['phases'] as List<dynamic>)
        .map((e) => TaskPhase.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final String name;
  final String doc;
  final String? dependsOn;
  final String requirement;
  final String goal;
  final List<String> acceptance;
  final List<TaskRole> roles;
  final List<TaskPhase> phases;
}

/// 任务清单
class TaskList {
  const TaskList({required this.tasks});

  factory TaskList.fromJson(Map<String, dynamic> json) => TaskList(
    tasks: (json['tasks'] as List<dynamic>)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final List<Task> tasks;
}
