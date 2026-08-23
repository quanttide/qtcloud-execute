import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task_list.dart';
import '../repositories/task_repository.dart';

/// 清单层状态：清单列表 + 当前清单。
class TaskListState {
  const TaskListState({this.lists = const [], this.currentListId});

  /// 全部业务清单（动态加载——不静态假设）
  final List<TaskList> lists;

  /// 当前清单 id；看板跟随此值加载任务
  final String? currentListId;
}

/// 清单层 Cubit：加载清单（动态）与切换当前清单。
///
/// 构造注入 [TaskRepository]——测试注入 [InMemoryTaskRepository]，
/// 运行时可注入 [ApiTaskRepository] 或其他实现，不在此 new 仓储。
class TaskListCubit extends Cubit<TaskListState> {
  TaskListCubit(this._repository) : super(const TaskListState());

  final TaskRepository _repository;

  /// 加载全部清单；若当前清单失效或尚未选中，默认选中第一个清单。
  ///
  /// 动态加载——不清零已有 currentListId（若仍存在）。
  Future<void> loadLists() async {
    final lists = await _repository.loadLists();
    var current = state.currentListId;
    if (current == null || !lists.any((l) => l.id == current)) {
      current = lists.isEmpty ? null : lists.first.id;
    }
    emit(TaskListState(lists: lists, currentListId: current));
  }

  /// 切换当前清单（看板跟随：页面随后以新 id 加载看板）。
  ///
  /// 未知清单抛 [ArgumentError]，状态保持不变。
  void switchList(String id) {
    if (!state.lists.any((l) => l.id == id)) {
      throw ArgumentError('清单不存在：$id');
    }
    emit(TaskListState(lists: state.lists, currentListId: id));
  }
}
