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

/// 看板层状态：当前项目的全量任务 + 状态列投影 + 写操作结果信号。
///
/// - [tasks]：状态列泳道投影（页面只渲染泳道）
/// - [writeToken]：每次写操作成功 +1（页面据此刷新清单层快照）
/// - [errorToken]/[errorMessage]：每次写操作失败 +1（页面据此提示，不静默）
class BoardState {
  const BoardState({
    this.tasks = const BoardProjection({}),
    this.writeToken = 0,
    this.errorToken = 0,
    this.errorMessage,
  });

  /// 当前清单的看板投影
  final BoardProjection tasks;

  /// 写操作成功计数
  final int writeToken;

  /// 写操作失败计数
  final int errorToken;

  /// 最近一次失败的错误信息
  final String? errorMessage;
}

/// 看板层事件
sealed class BoardEvent {
  const BoardEvent();
}

/// 加载当前清单任务（传 [listId] 切换目标项目；省略沿用上次）
class BoardLoadTasks extends BoardEvent {
  const BoardLoadTasks([this.listId]);

  final String? listId;
}

/// 更新任务（拖拽/弹窗后——同 id 替换，不存在新增）
class BoardUpdateTask extends BoardEvent {
  const BoardUpdateTask(this.task);

  final Task task;
}

/// 删除任务
class BoardDeleteTask extends BoardEvent {
  const BoardDeleteTask(this.taskId);

  final String taskId;
}

/// 新建任务（列头「+」——id 由 Bloc 生成，[status] 指定目标列）
class BoardCreateTask extends BoardEvent {
  const BoardCreateTask(this.draft, {required this.status});

  final TaskDraft draft;
  final TaskStatus status;
}

/// 看板层 Bloc：加载当前项目（清单）任务、投影为状态泳道。
///
/// 构造注入 [TaskRepository]——测试注入 [InMemoryTaskRepository]，不在此 new 仓储。
///
/// 数据流：项目切换 → [BoardLoadTasks]；拖拽/弹窗 → [BoardUpdateTask]；
/// 删除 → [BoardDeleteTask]；列头新增 → [BoardCreateTask]。
/// 写操作失败不抛异常：经 [BoardState.errorToken]/[errorMessage] 通知页面提示。
class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc(this._repository) : super(const BoardState()) {
    on<BoardLoadTasks>(_onLoadTasks);
    on<BoardUpdateTask>(_onUpdateTask);
    on<BoardDeleteTask>(_onDeleteTask);
    on<BoardCreateTask>(_onCreateTask);
  }

  final TaskRepository _repository;
  String? _listId;

  /// 当前项目全量任务（单一事实源——投影在其上重算）
  List<Task> _tasks = const [];

  /// 加载当前项目任务并按状态投影。
  Future<void> _onLoadTasks(
    BoardLoadTasks event,
    Emitter<BoardState> emit,
  ) async {
    if (event.listId != null) _listId = event.listId;
    final id = _listId;
    if (id == null) {
      _fail(emit, '尚未指定项目：先加载清单');
      return;
    }
    _tasks = await _repository.loadTasks(id);
    emit(_state());
  }

  /// 更新任务（同 id 替换，不存在新增；不计方向约束——真看板自由来回）。
  Future<void> _onUpdateTask(
    BoardUpdateTask event,
    Emitter<BoardState> emit,
  ) async {
    final id = _listId;
    if (id == null) {
      _fail(emit, '尚未加载项目：先加载清单');
      return;
    }
    try {
      await _repository.updateTask(id, event.task);
      _tasks = await _repository.loadTasks(id);
      emit(_state(writeToken: state.writeToken + 1));
    } catch (e) {
      _fail(emit, e.toString());
    }
  }

  /// 删除任务：从仓储移除后重载并重投影。
  Future<void> _onDeleteTask(
    BoardDeleteTask event,
    Emitter<BoardState> emit,
  ) async {
    final id = _listId;
    if (id == null) {
      _fail(emit, '尚未加载项目：先加载清单');
      return;
    }
    try {
      await _repository.deleteTask(id, event.taskId);
      _tasks = await _repository.loadTasks(id);
      emit(_state(writeToken: state.writeToken + 1));
    } catch (e) {
      _fail(emit, e.toString());
    }
  }

  /// 新增任务到当前项目（列头「+」）：生成 id 后写仓储并重投影。
  Future<void> _onCreateTask(
    BoardCreateTask event,
    Emitter<BoardState> emit,
  ) async {
    final id = _listId;
    if (id == null) {
      _fail(emit, '尚未加载项目：先加载清单');
      return;
    }
    try {
      final created = Task(
        id: '$id-${DateTime.now().microsecondsSinceEpoch}',
        title: event.draft.title,
        description: event.draft.description,
        status: event.status,
        priority: event.draft.priority,
      );
      await _repository.updateTask(id, created);
      _tasks = await _repository.loadTasks(id);
      emit(_state(writeToken: state.writeToken + 1));
    } catch (e) {
      _fail(emit, e.toString());
    }
  }

  /// 以当前全量任务构造状态（成功路径）。
  BoardState _state({int? writeToken}) => BoardState(
    tasks: BoardProjection.fromTasks(_tasks),
    writeToken: writeToken ?? state.writeToken,
    errorToken: state.errorToken,
  );

  /// 失败路径：投影保持不变，errorToken +1 并携带错误信息（页面提示）。
  void _fail(Emitter<BoardState> emit, String message) {
    emit(
      BoardState(
        tasks: state.tasks,
        writeToken: state.writeToken,
        errorToken: state.errorToken + 1,
        errorMessage: message,
      ),
    );
  }
}

/// 新建任务草稿（列头「+」表单输入；无 id/status——由 Bloc 生成/指定）。
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
  });

  final String title;
  final String description;
  final TaskPriority priority;
}
