/// 任务状态：未开始 / 进行中 / 评审中 / 已完成
///
/// 状态只前进不后退（notStarted → inProgress → reviewing → done）。
enum TaskStatus {
  /// 未开始
  notStarted('notStarted', '未开始'),

  /// 进行中
  inProgress('inProgress', '进行中'),

  /// 评审中
  reviewing('reviewing', '评审中'),

  /// 已完成
  done('done', '已完成');

  const TaskStatus(this.wire, this.label);

  /// JSON 序列化值
  final String wire;

  /// 展示文案
  final String label;

  /// 从 JSON 序列化值解析；未知值抛 [ArgumentError]
  static TaskStatus fromWire(String wire) => values.firstWhere(
    (s) => s.wire == wire,
    orElse: () => throw ArgumentError('未知任务状态：$wire'),
  );
}

/// 任务优先级：紧急 / 高 / 中 / 低
///
/// AI 建议 + 人确认——AI 不直接修改（判断不是事实）。
enum TaskPriority {
  /// 紧急
  urgent('urgent', '紧急'),

  /// 高
  high('high', '高'),

  /// 中
  medium('medium', '中'),

  /// 低
  low('low', '低');

  const TaskPriority(this.wire, this.label);

  /// JSON 序列化值
  final String wire;

  /// 展示文案
  final String label;

  /// 从 JSON 序列化值解析；未知值抛 [ArgumentError]
  static TaskPriority fromWire(String wire) => values.firstWhere(
    (p) => p.wire == wire,
    orElse: () => throw ArgumentError('未知任务优先级：$wire'),
  );
}

/// 执行云的最小领域单元——一个事项
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
  });

  /// 从 JSON 解析；status/priority 为 wire 值
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    status: TaskStatus.fromWire(json['status'] as String),
    priority: TaskPriority.fromWire(json['priority'] as String),
  );

  /// 唯一标识
  final String id;

  /// 标题——一句话概括
  final String title;

  /// 描述——展开细节
  final String description;

  /// 状态（只前进）
  final TaskStatus status;

  /// 优先级
  final TaskPriority priority;

  /// JSON 序列化（全字段）
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.wire,
    'priority': priority.wire,
  };

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
  }) => Task(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
  );

  /// 状态流转（只前进）：推进到 [next]。
  ///
  /// - 允许跳级前进（如 notStarted → done）；
  /// - 目标与当前相同视为无操作，返回自身；
  /// - 非法回退（目标状态早于当前状态）抛 [StateError]。
  Task advanceTo(TaskStatus next) {
    if (next.index < status.index) {
      throw StateError('状态只前进：$status 不能回退到 $next');
    }
    return next == status ? this : copyWith(status: next);
  }
}
