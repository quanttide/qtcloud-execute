import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../repositories/task_repository.dart';

/// 看板投影：列=分组 × 行=状态 的二维矩阵。
///
/// 矩阵完整：每个分组含全部四状态行（空行返回空列表——页面渲染空占位）。
class BoardProjection {
  const BoardProjection(this.matrix);

  /// 从仓储分组数据投影为 分组×状态 矩阵。
  ///
  /// 只含该清单实际存在的分组列；行固定为 [TaskStatus.values] 全部状态。
  factory BoardProjection.fromGrouped(Map<Group, List<Task>> grouped) {
    return BoardProjection({
      for (final entry in grouped.entries)
        // 显式类型参数：Map.unmodifiable 的泛型无法向嵌套字面量传导
        entry.key: Map<TaskStatus, List<Task>>.unmodifiable({
          for (final status in TaskStatus.values)
            status: List<Task>.unmodifiable([
              for (final t in entry.value)
                if (t.status == status) t,
            ]),
        }),
    });
  }

  /// 分组 × 状态 → 任务列表
  final Map<Group, Map<TaskStatus, List<Task>>> matrix;

  /// 取某分组某状态下的任务；分组或状态不存在返回空列表。
  List<Task> tasksOf(Group group, TaskStatus status) =>
      matrix[group]?[status] ?? const [];

  /// 按任务 id 反查所属分组；不在当前投影中返回 null。
  Group? groupOf(String taskId) {
    for (final entry in matrix.entries) {
      if (entry.value.values.any((tasks) => tasks.any((t) => t.id == taskId))) {
        return entry.key;
      }
    }
    return null;
  }
}

/// 看板层状态：分组×状态 投影矩阵（页面只渲染矩阵）。
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

  /// 加载当前清单任务并投影为 分组×状态 矩阵。
  ///
  /// 传 [listId] 切换目标清单（清单切换跟随）；省略沿用上次清单。
  /// 尚未指定清单时抛 [StateError]。
  Future<void> loadTasks([String? listId]) async {
    if (listId != null) _listId = listId;
    final id = _listId;
    if (id == null) {
      throw StateError('尚未指定清单：先调用 loadTasks(listId)');
    }
    final grouped = await _repository.loadTasks(id);
    emit(BoardState(tasks: BoardProjection.fromGrouped(grouped)));
  }

  /// 更新任务（弹窗/拖拽操作后）：写入仓储并重新投影。
  ///
  /// 任务分组从当前投影按 id 反查（Task 模型不含分组字段）；
  /// 任务不在当前清单时抛 [StateError]。
  Future<void> updateTask(Task task) async {
    final id = _listId;
    if (id == null) {
      throw StateError('尚未加载清单：先调用 loadTasks');
    }
    final group = state.tasks.groupOf(task.id);
    if (group == null) {
      throw StateError('任务不在当前清单：${task.id}');
    }
    await _repository.updateTask(id, group, task);
    final grouped = await _repository.loadTasks(id);
    emit(BoardState(tasks: BoardProjection.fromGrouped(grouped)));
  }
}
