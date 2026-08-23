import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../states/board_cubit.dart';
import '../states/task_list_cubit.dart';
import '../widgets/board_view.dart';
import '../widgets/task_detail_dialog.dart';
import '../widgets/task_list_switcher.dart';

/// 执行云首页——业务清单的二维看板页面。
///
/// 接线：顶部清单切换器（TaskListCubit）+ 看板（BoardCubit 投影）+ 详情弹窗。
/// Cubit 由上层 [MultiBlocProvider] 注入（main.dart），本页只消费不创建。
///
/// 数据流（单向）：
/// - initState → TaskListCubit.loadLists（清单动态加载）
/// - currentListId 变化 → BoardCubit.loadTasks（清单切换看板跟随）
/// - 卡片点击 → TaskDetailDialog（纯组件）→ onUpdated → BoardCubit.updateTask
/// - 桌面拖拽跨行 → BoardCubit.updateTask（状态推进，只前进）
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  /// 已触发看板加载的清单 id——切换去重（点击当前清单不重复加载，切换无副作用）。
  String? _loadedListId;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<TaskListCubit>().loadLists());
  }

  /// 清单切换跟随：currentListId 变化 → 以新 id 加载看板。
  ///
  /// 去重：同一清单的状态刷新（如 switchList 当前项）不重复 loadTasks。
  void _onListChanged(BuildContext context, TaskListState state) {
    final id = state.currentListId;
    if (id == null || id == _loadedListId) return;
    _loadedListId = id;
    unawaited(context.read<BoardCubit>().loadTasks(id));
  }

  /// 卡片点击 → 弹窗打开；操作回调写仓储并刷新看板（单向数据流）。
  Future<void> _openDetail(Task task) async {
    await TaskDetailDialog.show(
      context,
      task: task,
      onUpdated: (updated) =>
          unawaited(context.read<BoardCubit>().updateTask(updated)),
    );
  }

  /// 桌面拖拽跨行（状态推进）：目标状态不早于当前才推进（状态只前进）。
  void _onDrop(Task task, TaskStatus targetStatus) {
    if (targetStatus.index < task.status.index) return;
    if (targetStatus == task.status) return;
    unawaited(
      context.read<BoardCubit>().updateTask(task.advanceTo(targetStatus)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务清单')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TaskListCubit, TaskListState>(
            listener: _onListChanged,
          ),
        ],
        child: Column(
          children: [
            // 顶部清单切换器（数据驱动——清单动态加载，不静态假设）
            BlocBuilder<TaskListCubit, TaskListState>(
              builder: (context, state) => TaskListSwitcher(
                lists: state.lists,
                currentListId: state.currentListId,
                onSwitch: (id) =>
                    context.read<TaskListCubit>().switchList(id),
              ),
            ),
            // 二维看板（列=分组 × 行=状态——投影在 Bloc 层完成，页面纯渲染）
            Expanded(
              child: BlocBuilder<BoardCubit, BoardState>(
                builder: (context, state) => BoardView(
                  projection: state.tasks,
                  onTaskTap: _openDetail,
                  onTaskDrop: _onDrop,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
