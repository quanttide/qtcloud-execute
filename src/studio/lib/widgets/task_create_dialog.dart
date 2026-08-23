import 'package:flutter/material.dart';

import '../models/task.dart';
import '../states/board_cubit.dart';

/// 新建任务弹窗（列头「+」触发）——目标状态列由调用方指定。
///
/// 纯组件：不持有 Cubit/仓储。标题/分类/优先级/描述表单，
/// 提交后通过 [onCreate] 回调交付 [TaskDraft]（id/status 由 Cubit 生成/指定）。
class TaskCreateDialog extends StatefulWidget {
  const TaskCreateDialog({
    super.key,
    required this.status,
    required this.onCreate,
  });

  /// 新建任务的目标状态列（列头「+」所在列）
  final TaskStatus status;

  /// 提交回调（页面调用 BoardCubit.createTask）
  final ValueChanged<TaskDraft> onCreate;

  /// 便捷打开：showDialog 包装
  static Future<void> show(
    BuildContext context, {
    required TaskStatus status,
    required ValueChanged<TaskDraft> onCreate,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          TaskCreateDialog(status: status, onCreate: onCreate),
    );
  }

  @override
  State<TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends State<TaskCreateDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  TaskPriority _priority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _categoryController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// 提交：trim 后组装 TaskDraft；标题为空不提交。
  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    widget.onCreate(
      TaskDraft(
        title: title,
        description: _descriptionController.text,
        priority: _priority,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '新建任务 · ${widget.status.label}',
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
                title: '标题',
                child: TextField(
                  key: const ValueKey('create-title-field'),
                  controller: _titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '一句话概括任务…',
                  ),
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
                title: '类别',
                child: TextField(
                  key: const ValueKey('create-category-field'),
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '业务自定义分类（可选，如 business / product）…',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                context,
                title: '描述',
                child: TextField(
                  key: const ValueKey('create-description-field'),
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
                  key: const ValueKey('create-submit'),
                  onPressed: _submit,
                  child: const Text('创建'),
                ),
              ),
            ],
            ),
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

  /// 优先级按钮：当前档高亮（FilledButton），其余可选（OutlinedButton）。
  Widget _buildPriorityButton(TaskPriority priority) {
    final isCurrent = priority == _priority;
    if (isCurrent) {
      return FilledButton(
        key: ValueKey('create-priority-${priority.wire}'),
        onPressed: () => setState(() => _priority = priority),
        child: Text(priority.label),
      );
    }
    return OutlinedButton(
      key: ValueKey('create-priority-${priority.wire}'),
      onPressed: () => setState(() => _priority = priority),
      child: Text(priority.label),
    );
  }
}
