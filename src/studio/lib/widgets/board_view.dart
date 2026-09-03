import 'package:flutter/material.dart';

import '../models/task.dart';
import '../states/board_bloc.dart';
import 'task_card.dart';

/// 真看板：状态泳道（列 = 状态，横向推进阶梯），任务卡在列间自由来回。
///
/// 方案 A 真看板形态：
/// - 板底背景 + 每列一个圆角泳道（lane）——列是明确的容器而非表格单元格
/// - 列头：状态名 + 任务数 + WIP 上限徽章 + 「+」新增卡
/// - 卡片带投影（TaskCard 渲染）
/// - 拖拽跨列任意方向（不再只前进——真看板允许退回重做）
/// - WIP 上限仅作视觉提示：超限列头标红，不硬禁放（真看板以视觉约束为主）
///
/// 投影在 Bloc 层完成（[BoardProjection]），本组件纯渲染。折叠逻辑移除
/// （典型看板列始终展开，完整呈现工作流）。
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.projection,
    this.wipLimits = const {},
    this.onTaskTap,
    this.onTaskDrop,
    this.onCreateTask,
  });

  /// 状态列投影（来自 BoardCubit）
  final BoardProjection projection;

  /// WIP 上限（状态 → 在制上限）；缺省无上限（不显示徽章）
  final Map<TaskStatus, int> wipLimits;

  /// 卡片点击回调（打开详情弹窗）
  final ValueChanged<Task>? onTaskTap;

  /// 拖拽跨列回调（实时状态变更——自由方向）
  final void Function(Task task, TaskStatus targetStatus)? onTaskDrop;

  /// 列头「+」新建卡回调（新建到指定状态列）
  final ValueChanged<TaskStatus>? onCreateTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 板底：最浅表面，衬托泳道
    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 480.0;
          return SizedBox(
            height: columnHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final status in TaskStatus.values)
                  Expanded(child: _buildLane(context, status)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 状态泳道：圆角 lane（列头 + 卡片流）+ DragTarget 承接任意方向拖拽。
  Widget _buildLane(BuildContext context, TaskStatus status) {
    final theme = Theme.of(context);
    final tasks = [...projection.tasksOf(status)]
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    final limit = wipLimits[status];
    final overWip = limit != null && tasks.length > limit;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: DragTarget<Task>(
        key: ValueKey('drop-column-${status.wire}'),
        onAcceptWithDetails: (details) =>
            onTaskDrop?.call(details.data, status),
        builder: (context, candidates, rejected) {
          final highlighted = candidates.isNotEmpty && !overWip;
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted
                    ? theme.colorScheme.primary
                    : overWip
                    ? theme.colorScheme.error
                    : theme.colorScheme.outlineVariant,
                width: highlighted || overWip ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLaneHeader(context, status, tasks.length, limit, overWip),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: tasks.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无任务',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final task in tasks)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: TaskCard(
                                    key: ValueKey('task-card-${task.id}'),
                                    task: task,
                                    onTap: onTaskTap == null
                                        ? null
                                        : () => onTaskTap!(task),
                                    onDragEnd: null,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 泳道列头：状态名 + WIP 徽章（上限超限标红）+ 新增卡「+」。
  Widget _buildLaneHeader(
    BuildContext context,
    TaskStatus status,
    int count,
    int? limit,
    bool overWip,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              status.label,
              key: ValueKey('column-title-${status.wire}'),
              style: theme.textTheme.titleSmall,
            ),
          ),
          // WIP 徽章：count（/limit）——超限标红
          if (limit != null)
            Container(
              key: ValueKey('wip-badge-${status.wire}'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: overWip
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count/$limit',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: overWip ? theme.colorScheme.error : null,
                  fontWeight: overWip ? FontWeight.bold : null,
                ),
              ),
            )
          else
            Text(
              '$count',
              key: ValueKey('column-count-${status.wire}'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 4),
          if (onCreateTask != null)
            IconButton(
              key: ValueKey('create-task-${status.wire}'),
              iconSize: 18,
              tooltip: '新增任务',
              icon: const Icon(Icons.add),
              onPressed: () => onCreateTask!(status),
            ),
        ],
      ),
    );
  }
}
