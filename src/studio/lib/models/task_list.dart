/// 职能分组：business / product / operation
///
/// 与 profile 档案结构同构（业务文件夹 → 职能文件）。
enum Group {
  /// 业务
  business('business', '业务'),

  /// 产品
  product('product', '产品'),

  /// 运营
  operation('operation', '运营');

  const Group(this.wire, this.label);

  /// JSON 序列化值
  final String wire;

  /// 展示文案
  final String label;

  /// 从 JSON 序列化值解析；未知值抛 [ArgumentError]
  static Group fromWire(String wire) => values.firstWhere(
    (g) => g.wire == wire,
    orElse: () => throw ArgumentError('未知职能分组：$wire'),
  );
}

/// 业务清单（实体）——一个业务一个清单
///
/// 任务唯一归属：一个 Task 属于 一个清单 × 一个分组。
class TaskList {
  const TaskList({
    required this.id,
    required this.name,
    required this.groups,
  });

  /// 从 JSON 解析；groups 为 wire 值列表
  factory TaskList.fromJson(Map<String, dynamic> json) => TaskList(
    id: json['id'] as String,
    name: json['name'] as String,
    groups: (json['groups'] as List<dynamic>)
        .map((e) => Group.fromWire(e as String))
        .toList(),
  );

  /// 业务标识（qtdata / qtclass / qtcloud…）
  final String id;

  /// 业务名称
  final String name;

  /// 清单内职能分组（组织单元）
  final List<Group> groups;

  /// JSON 序列化（元数据 + 分组定义）
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'groups': [for (final g in groups) g.wire],
  };

  /// 是否包含指定职能分组
  bool hasGroup(Group group) => groups.contains(group);
}
