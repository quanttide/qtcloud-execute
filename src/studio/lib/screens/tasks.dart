import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../repositories/task_repository.dart';
import '../widgets/task_sections.dart';

/// 任务清单页：加载全部清单任务（阶段 1 过渡展示，阶段 4 换二维看板）
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.loadRepository});

  final Future<TaskRepository> Function() loadRepository;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task>? _tasks;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final TaskRepository repository = await widget.loadRepository();
      final List<TaskList> lists = await repository.loadLists();
      final List<Task> tasks = [];
      for (final list in lists) {
        final grouped = await repository.loadTasks(list.id);
        for (final groupTasks in grouped.values) {
          tasks.addAll(groupTasks);
        }
      }
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务清单')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final tasks = _tasks;
    if (tasks == null) {
      return _error != null
          ? EmptyState(message: '加载失败：$_error')
          : const Center(child: CircularProgressIndicator());
    }
    if (tasks.isEmpty) {
      return const EmptyState(message: '暂无任务');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) =>
          _TaskCard(task: tasks[index]),
    );
  }
}

/// 任务卡片：标题 + 状态/优先级，点击进入详情
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/tasks/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(task.title, style: theme.textTheme.titleLarge),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      Icons.circle,
                      size: 12,
                      color: _statusColor(theme, task.status),
                    ),
                    label: Text(task.status.label),
                  ),
                  Chip(
                    avatar: const Icon(Icons.flag_outlined, size: 16),
                    label: Text(task.priority.label),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, TaskStatus status) => switch (status) {
    TaskStatus.notStarted => theme.colorScheme.outline,
    TaskStatus.inProgress => theme.colorScheme.primary,
    TaskStatus.reviewing => theme.colorScheme.tertiary,
    TaskStatus.done => theme.colorScheme.secondary,
  };
}
