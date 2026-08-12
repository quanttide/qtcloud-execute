import 'package:flutter/material.dart';

import '../models/task.dart';
import '../widgets/task_archive.dart';
import '../widgets/task_sections.dart';

/// 任务详情页：按 id 展示单个任务档案
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.loadTasks,
  });

  final String taskId;
  final Future<TaskList> Function() loadTasks;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  String? _dependsOnName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final TaskList list = await widget.loadTasks();
      Task? task;
      for (final t in list.tasks) {
        if (t.id == widget.taskId) {
          task = t;
          break;
        }
      }
      String? dependsOnName;
      if (task?.dependsOn != null) {
        for (final t in list.tasks) {
          if (t.id == task!.dependsOn) {
            dependsOnName = t.name;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _task = task;
        _dependsOnName = dependsOnName;
      });
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
        Text(task.name, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_dependsOnName != null)
              Chip(
                avatar: const Icon(Icons.link, size: 16),
                label: Text('依赖：$_dependsOnName'),
              ),
          ],
        ),
        TaskArchiveView(task: task),
      ],
    );
  }
}
