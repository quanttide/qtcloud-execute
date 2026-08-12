import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/task.dart';
import '../widgets/task_archive.dart';
import '../widgets/task_sections.dart';

/// 任务清单页：加载任务档案列表
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.loadTasks});

  final Future<TaskList> Function() loadTasks;

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
      final TaskList list = await widget.loadTasks();
      if (!mounted) return;
      setState(() => _tasks = list.tasks);
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
    final Map<String, String> names = {
      for (final task in tasks) task.id: task.name,
    };
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) {
        final Task task = tasks[index];
        return _TaskCard(
          task: task,
          dependsOnName: task.dependsOn == null ? null : names[task.dependsOn],
        );
      },
    );
  }
}

/// 任务卡片：点击进入任务档案详情
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, this.dependsOnName});

  final Task task;
  final String? dependsOnName;

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
                    child: Text(task.name, style: theme.textTheme.titleLarge),
                  ),
                  if (dependsOnName != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Tooltip(
                        message: '依赖：$dependsOnName',
                        child: const Chip(
                          avatar: Icon(Icons.link, size: 16),
                          label: Text('依赖前置任务'),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TaskArchiveView(task: task),
            ],
          ),
        ),
      ),
    );
  }
}
