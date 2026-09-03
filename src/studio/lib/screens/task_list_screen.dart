import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../states/board_cubit.dart';
import '../states/task_list_cubit.dart';
import '../widgets/board_view.dart';
import '../widgets/task_create_dialog.dart';
import '../widgets/task_detail_dialog.dart';
import '../widgets/task_list_switcher.dart';

/// 执行云首页——真看板（方案 A）页面。
///
/// 一次一个项目（TaskList/清单）为隔离单元：
/// - 顶部项目切换器（TaskListCubit）——项目即隔离单元，切换看板跟随
/// - 状态泳道看板（BoardCubit）——真看板，任务卡在不同状态列间自由来回
/// - 列头「+」新建任务到目标列（TaskCreateDialog）
///
/// 数据流（单向，Cubit 由 main.dart 的 MultiBlocProvider 注入）：
/// - 项目切换 → BoardCubit.loadTasks
/// - 卡片点击 → TaskDetailDialog → onUpdated → BoardCubit.updateTask
/// - 卡片拖拽跨列 → BoardCubit.updateTask（moveTo 自由方向）
/// - 列头「+」 → TaskCreateDialog → BoardCubit.createTask
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
    unawaited(context.read<TaskListCubit>().loadLists());
  }

  /// 项目切换跟随：currentListId 变化 → 以新 id 加载看板。
  void _onListChanged(BuildContext context, TaskListState state) {
    final id = state.currentListId;
    if (id == null || id == _loadedListId) return;
    _loadedListId = id;
    unawaited(context.read<BoardCubit>().loadTasks(id));
  }

  /// 卡片点击 → 详情弹窗打开；操作回调写仓储并刷新看板（单向数据流）。
  Future<void> _openDetail(Task task) async {
    await TaskDetailDialog.show(
      context,
      task: task,
      onUpdated: (updated) =>
          unawaited(context.read<BoardCubit>().updateTask(updated)),
      onDeleted: (taskId) =>
          unawaited(context.read<BoardCubit>().deleteTask(taskId)),
    );
  }

  /// 列头「+」新建任务：指定目标状态列，创建后看板刷新。
  Future<void> _openCreate(TaskStatus status) async {
    await TaskCreateDialog.show(
      context,
      status: status,
      onCreate: (draft) => unawaited(
        context.read<BoardCubit>().createTask(draft, status: status),
      ),
    );
  }

  /// 拖拽跨列（实时状态变更——真看板自由来回，不限定方向）。
  void _onDrop(Task task, TaskStatus targetStatus) {
    if (targetStatus == task.status) return;
    // moveTo 自由方向——允许前进也允许回退；同状态视为无操作
    unawaited(context.read<BoardCubit>().updateTask(task.moveTo(targetStatus)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('执行云看板')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TaskListCubit, TaskListState>(listener: _onListChanged),
        ],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧独立项目导航栏（项目即隔离单元——独立的切换器，非过滤器）
            SizedBox(
              width: 220,
              child: BlocBuilder<TaskListCubit, TaskListState>(
                builder: (context, state) => TaskListSwitcher(
                  lists: state.lists,
                  currentListId: state.currentListId,
                  onSwitch: (id) =>
                      context.read<TaskListCubit>().switchList(id),
                ),
              ),
            ),
            // 右侧：状态泳道看板（真看板）
            Expanded(
              child: BlocBuilder<BoardCubit, BoardState>(
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
