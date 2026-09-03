import 'package:flutter/material.dart';

import '../models/task.dart';

/// 看板单元格内的最小展示单元——title + priority 色点，卡片带投影（真看板形态）。
///
/// 状态不在此显示（状态已由看板所在行表达，不重复）。
/// 点击打开详情弹窗（[onTap]）；桌面端可拖拽跨列（[onDragEnd]）。
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap, this.onDragEnd});

  /// 展示的任务
  final Task task;

  /// 点击回调（打开详情弹窗）
  final VoidCallback? onTap;

  /// 拖拽结束回调（桌面跨列——实时状态变更）
  final void Function(DraggableDetails details)? onDragEnd;

  /// 优先级色点颜色：紧急红 / 高橙 / 中蓝 / 低灰——行内排序依据
  static Color colorOf(TaskPriority priority) => switch (priority) {
    TaskPriority.urgent => Colors.red,
    TaskPriority.high => Colors.orange,
    TaskPriority.medium => Colors.blue,
    TaskPriority.low => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget card = Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // priority 色点
              Container(
                key: ValueKey('priority-dot-${task.id}'),
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: colorOf(task.priority),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    // 优先级标签（文字 + 颜色，直观可见）
                    Container(
                      key: ValueKey('priority-label-${task.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colorOf(task.priority).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorOf(task.priority),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        task.priority.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorOf(task.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 始终可拖拽（桌面跨列由看板 DragTarget 承接）；抬起阴影 + 源位降透明度
    return Draggable<Task>(
      data: task,
      onDragEnd: onDragEnd,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: card,
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }
}
