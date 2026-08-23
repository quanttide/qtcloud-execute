import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../repositories/task_repository.dart';
import '../widgets/task_archive.dart';
import '../widgets/task_sections.dart';

/// 任务详情页：按 id 展示单个任务档案
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.loadRepository,
  });

  final String taskId;
  final Future<TaskRepository> Function() loadRepository;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final TaskRepository repository = await widget.loadRepository();
      final List<TaskList> lists = await repository.loadLists();
      Task? task;
      for (final list in lists) {
        final grouped = await repository.loadTasks(list.id);
        for (final groupTasks in grouped.values) {
          for (final t in groupTasks) {
            if (t.id == widget.taskId) {
              task = t;
              break;
            }
          }
          if (task != null) break;
        }
        if (task != null) break;
      }
      if (!mounted) return;
      setState(() => _task = task);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务详情')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final task = _task;
    if (task == null) {
      return _error != null
          ? EmptyState(message: '加载失败：$_error')
          : const Center(child: CircularProgressIndicator());
    }
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(task.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        TaskArchiveView(task: task),
      ],
    );
  }
}
