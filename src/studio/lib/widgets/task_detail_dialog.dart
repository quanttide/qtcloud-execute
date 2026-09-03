import 'package:flutter/material.dart';

import '../models/task.dart';

/// 任务详情弹窗——清单内就地操作，不跳页。
///
/// 纯组件：不持有 Cubit/仓储。状态/优先级点选即改、描述编辑保存，
/// 所有变更通过 [onUpdated] 回调交给页面（页面负责写仓储并刷新看板）。
///
/// 状态任意选择（真看板——自由来回，不限定只前进）。
class TaskDetailDialog extends StatefulWidget {
  const TaskDetailDialog({
    super.key,
    required this.task,
    required this.onUpdated,
  });

  /// 初始任务（清单页传入）
  final Task task;

  /// 变更回调（清单页刷新列表——本组件不写仓储）
  final ValueChanged<Task> onUpdated;

  /// 便捷打开：右侧滑出面板（showDialog 右对齐包装）
  static Future<void> show(
    BuildContext context, {
    required Task task,
    required ValueChanged<Task> onUpdated,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => TaskDetailDialog(task: task, onUpdated: onUpdated),
    );
  }

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  /// 弹窗内草稿——每处变更即改即存（回调）
  late Task _draft;

  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _draft = widget.task;
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// 应用变更：更新草稿并回调（页面写仓储、看板即时刷新）
  void _apply(Task next) {
    setState(() => _draft = next);
    widget.onUpdated(next);
  }

  /// 状态变更（真看板——任意方向选择，自由来回）。
  ///
  /// 复用领域方法 [Task.moveTo]；同状态视为无操作（不回调）。
  void _setStatus(TaskStatus status) {
    final next = _draft.moveTo(status);
    if (identical(next, _draft)) return;
    _apply(next);
  }

  void _setPriority(TaskPriority priority) {
    _apply(_draft.copyWith(priority: priority));
  }

  /// 保存描述：trim 后提交。
  void _save() {
    _apply(_draft.copyWith(description: _descriptionController.text));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      // 右侧滑出面板：右对齐 + 全高 + 左侧圆角
      alignment: Alignment.centerRight,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
      ),
      child: SizedBox(
        width: 440,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 + 关闭
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _draft.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: '状态',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in TaskStatus.values)
                      _buildStatusButton(status),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                title: '优先级',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final priority in TaskPriority.values)
                      _buildPriorityButton(priority),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                title: '描述',
                child: TextField(
                  key: const ValueKey('description-field'),
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '补充任务描述…',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('save-description'),
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  /// 状态按钮：当前态高亮（FilledButton），其余全部可选（OutlinedButton，
  /// 真看板自由来回——无非法回退禁用）。
  Widget _buildStatusButton(TaskStatus status) {
    final isCurrent = status == _draft.status;
    if (isCurrent) {
      return FilledButton(
        key: ValueKey('status-${status.wire}'),
        onPressed: () => _setStatus(status),
        child: Text(status.label),
      );
    }
    return OutlinedButton(
      key: ValueKey('status-${status.wire}'),
      onPressed: () => _setStatus(status),
      child: Text(status.label),
    );
  }

  /// 优先级按钮：当前档高亮，四档均可选（单选）
  Widget _buildPriorityButton(TaskPriority priority) {
    final isCurrent = priority == _draft.priority;
    if (isCurrent) {
      return FilledButton(
        key: ValueKey('priority-${priority.wire}'),
        onPressed: () => _setPriority(priority),
        child: Text(priority.label),
      );
    }
    return OutlinedButton(
      key: ValueKey('priority-${priority.wire}'),
      onPressed: () => _setPriority(priority),
      child: Text(priority.label),
    );
  }
}
