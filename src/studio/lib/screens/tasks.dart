import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/task.dart';

/// 任务清单页：从种子数据加载任务档案
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

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
      final String raw = await rootBundle.loadString(
        'assets/data/seed_tasks.json',
      );
      final TaskList list = TaskList.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
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
          ? _EmptyState(message: '加载失败：$_error')
          : const Center(child: CircularProgressIndicator());
    }
    if (tasks.isEmpty) {
      return const _EmptyState(message: '暂无任务');
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

/// 任务卡片：展示目标、验收标准、角色分工与五阶段
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, this.dependsOnName});

  final Task task;
  final String? dependsOnName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              icon: Icons.flag_outlined,
              title: '目标',
              child: Text(task.goal),
            ),
            _Section(
              icon: Icons.description_outlined,
              title: '需求',
              child: Text(task.requirement),
            ),
            _Section(
              icon: Icons.checklist_outlined,
              title: '验收标准',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in task.acceptance)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Section(
              icon: Icons.group_outlined,
              title: '角色分工',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final role in task.roles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              role.role,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(role.desc)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Section(
              icon: Icons.timeline_outlined,
              title: '阶段',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < task.phases.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.phases[i].phase,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(task.phases[i].content),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 卡片内分节标题
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// 空状态/加载失败占位
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
