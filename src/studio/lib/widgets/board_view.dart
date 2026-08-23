import 'package:flutter/material.dart';

import '../models/task.dart';
import '../states/board_cubit.dart';
import 'task_card.dart';

/// 状态泳道看板：列 = 状态（推进阶梯，横向），列内纵向堆叠任务卡片。
///
/// 投影在 Bloc 层完成（[BoardProjection]），本组件纯渲染：
/// - 每列渲染 [TaskCard]（点击弹窗 / 桌面拖拽跨列）
/// - 空列显示"暂无任务"占位
/// - 列内按 priority 排序（紧急 → 高 → 中 → 低）
/// - 列头可折叠（"已完成"列默认折叠——减少噪声）
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.projection,
    this.onTaskTap,
    this.onTaskDrop,
  });

  /// 状态列投影（来自 BoardCubit）
  final BoardProjection projection;

  /// 卡片点击回调（打开详情弹窗）
  final ValueChanged<Task>? onTaskTap;

  /// 拖拽跨列回调（状态推进：任务放置到目标状态列）
  final void Function(Task task, TaskStatus targetStatus)? onTaskDrop;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  /// 折叠的列（已完成默认折叠）
  final Set<TaskStatus> _collapsed = {TaskStatus.done};

  void _toggleColumn(TaskStatus status) {
    setState(() {
      if (!_collapsed.remove(status)) {
        _collapsed.add(status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 列 = 固定四状态（结构维度稳定——推进阶梯完整，不随数据变化）
    // 四列均分宽度（Row + Expanded）——所有列始终可见，拖拽跨列即状态推进
    return LayoutBuilder(
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
                Expanded(child: _buildColumn(status)),
            ],
          ),
        );
      },
    );
  }

  /// 状态列：列头（可折叠）+ 任务卡片流；DragTarget 承接跨列拖拽（状态推进）
  Widget _buildColumn(TaskStatus status) {
    final theme = Theme.of(context);
    final tasks = [...widget.projection.tasksOf(status)]
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    final collapsed = _collapsed.contains(status);
    return DragTarget<Task>(
      key: ValueKey('drop-column-${status.wire}'),
      onAcceptWithDetails: (details) =>
          widget.onTaskDrop?.call(details.data, status),
      builder: (context, candidates, rejected) {
        return Container(
          decoration: BoxDecoration(
            color: candidates.isNotEmpty
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                : null,
            border: Border.all(
              color: candidates.isNotEmpty
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildColumnHeader(status, tasks.length, collapsed),
              if (collapsed)
                InkWell(
                  key: ValueKey('collapsed-column-${status.wire}'),
                  onTap: () => _toggleColumn(status),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: const Text(
                      '已折叠，点击展开',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
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
                                    onTap: widget.onTaskTap == null
                                        ? null
                                        : () => widget.onTaskTap!(task),
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
    );
  }

  /// 列头：状态文案 + 任务数 + 折叠箭头，点击展开/收起
  Widget _buildColumnHeader(
    TaskStatus status,
    int taskCount,
    bool collapsed,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('column-header-${status.wire}'),
      onTap: () => _toggleColumn(status),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(
              collapsed ? Icons.chevron_right : Icons.expand_more,
              size: 18,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                status.label,
                key: ValueKey('column-title-${status.wire}'),
                style: theme.textTheme.labelLarge,
              ),
            ),
            Text(
              '$taskCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
