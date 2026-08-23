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

/// 看板层状态：状态列投影（页面只渲染状态泳道）。
class BoardState {
  const BoardState({this.tasks = const BoardProjection({})});

  /// 当前清单的看板投影
  final BoardProjection tasks;
}

/// 看板层 Cubit：加载当前清单任务并投影、更新任务后重新投影。
///
/// 构造注入 [TaskRepository]——测试注入 [InMemoryTaskRepository]，不在此 new 仓储。
///
/// 数据流：TaskListCubit.switchList → 页面调用 [loadTasks]（清单切换跟随）；
/// 弹窗/拖拽操作 → [updateTask] → 仓储写入 → 重新投影。
class BoardCubit extends Cubit<BoardState> {
  BoardCubit(this._repository) : super(const BoardState());

  final TaskRepository _repository;
  String? _listId;

  /// 加载当前清单任务并投影为 状态列→任务 泳道。
  ///
  /// 传 [listId] 切换目标清单（清单切换跟随）；省略沿用上次清单。
  /// 尚未指定清单时抛 [StateError]。
  Future<void> loadTasks([String? listId]) async {
    if (listId != null) _listId = listId;
    final id = _listId;
    if (id == null) {
      throw StateError('尚未指定清单：先调用 loadTasks(listId)');
    }
    final tasks = await _repository.loadTasks(id);
    emit(BoardState(tasks: BoardProjection.fromTasks(tasks)));
  }

  /// 更新任务（弹窗/拖拽操作后）：写入仓储并重新投影。
  ///
  /// 任务直接归属清单（同 id 替换，不存在新增）；任务不在当前清单时
  /// 由仓储按 id 追加/替换，Cubit 不额外校验分组。
  Future<void> updateTask(Task task) async {
    final id = _listId;
    if (id == null) {
      throw StateError('尚未加载清单：先调用 loadTasks');
    }
    await _repository.updateTask(id, task);
    final tasks = await _repository.loadTasks(id);
    emit(BoardState(tasks: BoardProjection.fromTasks(tasks)));
  }
}
