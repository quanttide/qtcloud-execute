import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../states/board_bloc.dart';
import '../states/task_list_bloc.dart';
import '../widgets/board_view.dart';
import '../widgets/task_create_dialog.dart';
import '../widgets/task_detail_dialog.dart';
import '../widgets/task_list_switcher.dart';

/// 执行云首页——真看板（方案 A）页面。
///
/// 一次一个项目（TaskList/清单）为隔离单元：
/// - 顶部项目切换器（TaskListBloc）——项目即隔离单元，切换看板跟随
/// - 状态泳道看板（BoardBloc）——真看板，任务卡在不同状态列间自由来回
/// - 列头「+」新建任务到目标列（TaskCreateDialog）
///
/// 数据流（单向，Bloc 由 main.dart 的 MultiBlocProvider 注入）：
/// - 项目切换 → BoardLoadTasks
/// - 卡片点击 → TaskDetailDialog → onUpdated → BoardUpdateTask
/// - 卡片拖拽跨列 → BoardUpdateTask（moveTo 自由方向）
/// - 列头「+」 → TaskCreateDialog → BoardCreateTask
/// - 写操作成功（writeToken 变化）→ TaskListLoadLists 刷新清单快照
/// - 写操作失败（errorToken 变化）→ SnackBar 提示
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  /// WIP 上限（进行中/评审中——真看板在制约束，超限列头标黄提示）
  static const Map<TaskStatus, int> _wipLimits = {
    TaskStatus.inProgress: 3,
    TaskStatus.reviewing: 3,
  };

  /// 已触发看板加载的项目 id——切换去重（点击当前项目不重复加载）。
  String? _loadedListId;

  @override
  void initState() {
    super.initState();
    context.read<TaskListBloc>().add(const TaskListLoadLists());
  }

  /// 项目切换跟随：currentListId 变化 → 以新 id 加载看板。
  void _onListChanged(BuildContext context, TaskListState state) {
    final id = state.currentListId;
    if (id == null || id == _loadedListId) return;
    _loadedListId = id;
    context.read<BoardBloc>().add(BoardLoadTasks(id));
  }

  /// 写操作失败（errorToken 变化）→ SnackBar 提示，不静默。
  void _onWriteError(BuildContext context, BoardState state) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('操作失败：${state.errorMessage}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  /// 写操作成功（writeToken 变化）→ 刷新清单层快照（switcher 徽章跟随）。
  void _onWriteSuccess(BuildContext context, BoardState state) {
    context.read<TaskListBloc>().add(const TaskListLoadLists());
  }

  /// 卡片点击 → 详情弹窗打开；操作回调派发事件（单向数据流）。
  Future<void> _openDetail(Task task) async {
    await TaskDetailDialog.show(
      context,
      task: task,
      onUpdated: (updated) =>
          context.read<BoardBloc>().add(BoardUpdateTask(updated)),
      onDeleted: (taskId) =>
          context.read<BoardBloc>().add(BoardDeleteTask(taskId)),
    );
  }

  /// 列头「+」新建任务：指定目标状态列，创建后看板刷新。
  Future<void> _openCreate(TaskStatus status) async {
    await TaskCreateDialog.show(
      context,
      status: status,
      onCreate: (draft) =>
          context.read<BoardBloc>().add(BoardCreateTask(draft, status: status)),
    );
  }

  /// 拖拽跨列（实时状态变更——真看板自由来回，不限定方向）。
  void _onDrop(Task task, TaskStatus targetStatus) {
    if (targetStatus == task.status) return;
    // moveTo 自由方向——允许前进也允许回退；同状态视为无操作
    context.read<BoardBloc>().add(BoardUpdateTask(task.moveTo(targetStatus)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('执行云看板')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TaskListBloc, TaskListState>(listener: _onListChanged),
          BlocListener<BoardBloc, BoardState>(
            listenWhen: (previous, current) =>
                current.errorToken != previous.errorToken,
            listener: _onWriteError,
          ),
          BlocListener<BoardBloc, BoardState>(
            listenWhen: (previous, current) =>
                current.writeToken != previous.writeToken,
            listener: _onWriteSuccess,
          ),
        ],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧独立项目导航栏（项目即隔离单元——独立的切换器，非过滤器）
            SizedBox(
              width: 220,
              child: BlocBuilder<TaskListBloc, TaskListState>(
                builder: (context, state) => TaskListSwitcher(
                  lists: state.lists,
                  currentListId: state.currentListId,
                  onSwitch: (id) =>
                      context.read<TaskListBloc>().add(TaskListSwitchList(id)),
                ),
              ),
            ),
            // 右侧：状态泳道看板（真看板）
            Expanded(
              child: BlocBuilder<BoardBloc, BoardState>(
                builder: (context, state) => BoardView(
                  projection: state.tasks,
                  wipLimits: _wipLimits,
                  onTaskTap: _openDetail,
                  onTaskDrop: _onDrop,
                  onCreateTask: _openCreate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
