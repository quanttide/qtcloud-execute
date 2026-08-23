import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';

/// 看板投影：状态列 → 任务流。
///
/// 四列固定为 [TaskStatus.values]（列完整——空列返回空列表——页面渲染空占位）。
class BoardProjection {
  const BoardProjection(this.columns);

  /// 从任务列表投影为 状态列→任务 映射。
  ///
  /// 只含 [TaskStatus.values] 四列；任务按状态归入对应列。
  factory BoardProjection.fromTasks(List<Task> tasks) {
    return BoardProjection({
      // 显式类型参数：Map.unmodifiable 的泛型无法向嵌套字面量传导
      for (final status in TaskStatus.values)
        status: List<Task>.unmodifiable([
          for (final t in tasks)
            if (t.status == status) t,
        ]),
    });
  }

  /// 状态列 → 任务列表
  final Map<TaskStatus, List<Task>> columns;

  /// 取某状态列下的任务；状态不存在返回空列表。
  List<Task> tasksOf(TaskStatus status) => columns[status] ?? const [];
}

/// 看板层状态：当前项目的全量任务 + 分类过滤器 + 状态列投影。
///
/// - [tasks]：过滤后的状态列泳道投影（页面只渲染泳道）
/// - [categories]：当前项目任务中去重后的分类集合（顶部过滤器数据源）
/// - [selectedCategory]：当前选中的分类（null = 全部）；过滤后任务仅含该分类
class BoardState {
  const BoardState({
    this.tasks = const BoardProjection({}),
    this.categories = const [],
    this.selectedCategory,
  });

  /// 当前清单的看板投影（已按 selectedCategory 过滤）
  final BoardProjection tasks;

  /// 当前项目所有任务中出现的分类（去重、保持首现顺序）
  final List<String> categories;

  /// 当前选中的分类；null 表示不过滤（显示全部）
  final String? selectedCategory;
}

/// 看板层 Cubit：加载当前项目（清单）任务、按分类过滤、投影为状态泳道。
///
/// 构造注入 [TaskRepository]——测试注入 [InMemoryTaskRepository]，不在此 new 仓储。
///
/// 数据流：项目切换 → [loadTasks]（一次一个项目全量任务）；
/// 分类过滤 → [setCategory]（过滤后重投影）；
/// 拖拽/弹窗 → [updateTask]（[Task.moveTo] 自由来回——真看板）；
/// 列头新增 → [createTask]（追加到当前项目）。
class BoardCubit extends Cubit<BoardState> {
  BoardCubit(this._repository) : super(const BoardState());

  final TaskRepository _repository;
  String? _listId;

  /// 当前项目全量任务（单一事实源——分类过滤/投影都在其上重算）
  List<Task> _tasks = const [];

  /// 当前选中的分类（null = 全部）——独立于状态流，切换不重载任务
  String? _selectedCategory;

  /// 从任务列表提取去重分类（保持首现顺序）
  static List<String> extractCategories(List<Task> tasks) {
    final seen = <String>{};
    return [
      for (final t in tasks)
        if (t.category != null && seen.add(t.category!)) t.category!,
    ];
  }

  /// 加载当前项目任务并按状态投影（可选过滤分类）。
  ///
  /// 传 [listId] 切换目标项目（项目切换跟随）；省略沿用上次项目。
  /// 尚未指定项目时抛 [StateError]。重载保留[selectedCategory]，
  /// 分类集合按新项目任务刷新。
  Future<void> loadTasks([String? listId]) async {
    if (listId != null) _listId = listId;
    final id = _listId;
    if (id == null) {
      throw StateError('尚未指定项目：先调用 loadTasks(listId)');
    }
    _tasks = await _repository.loadTasks(id);
    _emit();
  }

  /// 设置分类过滤器（null = 全部）；按当前项目任务重投影。
  void setCategory(String? category) {
    if (_listId == null) {
      throw StateError('尚未加载项目：先调用 loadTasks');
    }
    _selectedCategory = category;
    _emit();
  }

  /// 更新任务（拖拽/弹窗后）：写入仓储并重载任务、重投影。
  ///
  /// 任务直接归属当前项目（同 id 替换，不存在新增）；不计方向约束——
  /// 真看板允许任务在任意状态列间自由来回、任意分类变更。
  Future<void> updateTask(Task task) async {
    final id = _listId;
    if (id == null) {
      throw StateError('尚未加载项目：先调用 loadTasks');
    }
    await _repository.updateTask(id, task);
    _tasks = await _repository.loadTasks(id);
    _emit();
  }

  /// 新增任务到当前项目（列头「+」）：生成 id 后写仓储并重投影。
  Future<void> createTask(TaskDraft draft, {required TaskStatus status}) async {
    final id = _listId;
    if (id == null) {
      throw StateError('尚未加载项目：先调用 loadTasks');
    }
    final created = Task(
      id: '$id-${DateTime.now().microsecondsSinceEpoch}',
      title: draft.title,
      description: draft.description,
      status: status,
      priority: draft.priority,
      category: draft.category,
    );
    await _repository.updateTask(id, created);
    _tasks = await _repository.loadTasks(id);
    _emit();
  }

  /// 以当前全量任务 + [_selectedCategory] 重投影并 emit。
  void _emit() {
    emit(
      BoardState(
        tasks: _project(_tasks, _selectedCategory),
        categories: extractCategories(_tasks),
        selectedCategory: _selectedCategory,
      ),
    );
  }

  /// 按状态列投影任务（可选按分类过滤）。
  static BoardProjection _project(List<Task> tasks, String? category) {
    final filtered = category == null
        ? tasks
        : [
            for (final t in tasks)
              if (t.category == category) t,
          ];
    return BoardProjection.fromTasks(filtered);
  }
}

/// 新建任务草稿（列头「+」表单输入；无 id/status——由 Cubit 生成/指定）。
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.category,
  });

  final String title;
  final String description;
  final TaskPriority priority;
  final String? category;
}
