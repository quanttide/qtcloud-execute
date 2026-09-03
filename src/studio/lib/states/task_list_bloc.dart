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

/// 清单层事件
sealed class TaskListEvent {
  const TaskListEvent();
}

/// 加载全部清单（启动 / 写操作后刷新快照）
class TaskListLoadLists extends TaskListEvent {
  const TaskListLoadLists();
}

/// 切换当前清单（看板跟随）
class TaskListSwitchList extends TaskListEvent {
  const TaskListSwitchList(this.listId);

  final String listId;
}

/// 清单层 Bloc：加载清单（动态）与切换当前清单。
///
/// 构造注入 [TaskRepository]——测试注入 [InMemoryTaskRepository]，不在此 new 仓储。
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc(this._repository) : super(const TaskListState()) {
    on<TaskListLoadLists>(_onLoadLists);
    on<TaskListSwitchList>(_onSwitchList);
  }

  final TaskRepository _repository;

  /// 加载全部清单；若当前清单失效或尚未选中，默认选中第一个清单。
  ///
  /// 动态加载——不清零已有 currentListId（若仍存在）。
  Future<void> _onLoadLists(
    TaskListLoadLists event,
    Emitter<TaskListState> emit,
  ) async {
    final lists = await _repository.loadLists();
    var current = state.currentListId;
    if (current == null || !lists.any((l) => l.id == current)) {
      current = lists.isEmpty ? null : lists.first.id;
    }
    emit(TaskListState(lists: lists, currentListId: current));
  }

  /// 切换当前清单（未知清单忽略——状态不变，经 onError 记录）。
  void _onSwitchList(TaskListSwitchList event, Emitter<TaskListState> emit) {
    if (!state.lists.any((l) => l.id == event.listId)) {
      addError(ArgumentError('清单不存在：${event.listId}'));
      return;
    }
    emit(TaskListState(lists: state.lists, currentListId: event.listId));
  }
}
