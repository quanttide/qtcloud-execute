import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../states/board_cubit.dart';
import 'task_card.dart';

/// 二维看板：列 = 分组（职能，结构横向），行 = 状态（推进阶梯，纵向）。
///
/// 投影在 Bloc 层完成（[BoardProjection]），本组件纯渲染：
/// - 单元格渲染 [TaskCard]（点击弹窗 / 桌面拖拽跨行）
/// - 空单元格显示"暂无任务"占位
/// - 行内按 priority 排序（紧急 → 高 → 中 → 低）
/// - 行头可折叠（"已完成"行默认折叠——减少噪声）
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.projection,
    this.onTaskTap,
    this.onTaskDrop,
  });

  /// 分组×状态 投影矩阵（来自 BoardCubit）
  final BoardProjection projection;

  /// 卡片点击回调（打开详情弹窗）
  final ValueChanged<Task>? onTaskTap;

  /// 拖拽跨行回调（状态推进：任务放置到目标状态行）
  final void Function(Task task, TaskStatus targetStatus)? onTaskDrop;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  /// 折叠的行（已完成默认折叠）
  final Set<TaskStatus> _collapsed = {TaskStatus.done};

  static const double _rowHeaderWidth = 120;
  static const double _cellWidth = 240;

  void _toggleRow(TaskStatus status) {
    setState(() {
      if (!_collapsed.remove(status)) {
        _collapsed.add(status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 列 = 该清单实际存在的分组（按枚举固定顺序——结构维度稳定）
    final groups = Group.values
        .where(widget.projection.matrix.containsKey)
        .toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _rowHeaderWidth + groups.length * _cellWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderRow(groups),
            for (final status in TaskStatus.values)
              _buildStatusRow(status, groups),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(List<Group> groups) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: _rowHeaderWidth,
          child: _bordered(
            theme,
            alignment: Alignment.center,
            child: Text('分组\\状态', style: theme.textTheme.labelMedium),
          ),
        ),
        for (final group in groups)
          SizedBox(
            width: _cellWidth,
            child: _bordered(
              theme,
              alignment: Alignment.center,
              child: Text(
                group.label,
                key: ValueKey('group-header-${group.wire}'),
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusRow(TaskStatus status, List<Group> groups) {
    final theme = Theme.of(context);
    if (_collapsed.contains(status)) {
      // 折叠行：只留行头（点击展开）+ 整行提示
      return Row(
        children: [
          _buildRowHeader(status, collapsed: true),
          Expanded(
            child: InkWell(
              onTap: () => _toggleRow(status),
              child: _bordered(
                theme,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  '已折叠，点击展开',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRowHeader(status, collapsed: false),
        for (final group in groups) _buildCell(group, status),
      ],
    );
  }

  Widget _buildRowHeader(TaskStatus status, {required bool collapsed}) {
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('row-header-${status.wire}'),
      onTap: () => _toggleRow(status),
      child: SizedBox(
        width: _rowHeaderWidth,
        child: _bordered(
          theme,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                collapsed ? Icons.chevron_right : Icons.expand_more,
                size: 18,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(status.label, style: theme.textTheme.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 单元格：任务卡片列（按 priority 排序）或"暂无任务"占位；DragTarget 承接跨行拖拽
  Widget _buildCell(Group group, TaskStatus status) {
    final theme = Theme.of(context);
    final tasks = [...widget.projection.tasksOf(group, status)]
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return SizedBox(
      width: _cellWidth,
      child: DragTarget<Task>(
        key: ValueKey('drop-cell-${group.wire}-${status.wire}'),
        onAcceptWithDetails: (details) =>
            widget.onTaskDrop?.call(details.data, status),
        builder: (context, candidates, rejected) {
          return Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(6),
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
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      '暂无任务',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
          );
        },
      ),
    );
  }

  Widget _bordered(
    ThemeData theme, {
    required Alignment alignment,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
  }) {
    return Container(
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}
