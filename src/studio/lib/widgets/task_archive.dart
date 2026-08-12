import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_sections.dart';

/// 任务档案视图：目标、需求、验收标准、角色分工、五阶段
class TaskArchiveView extends StatelessWidget {
  const TaskArchiveView({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskSection(
          icon: Icons.flag_outlined,
          title: '目标',
          child: Text(task.goal),
        ),
        TaskSection(
          icon: Icons.description_outlined,
          title: '需求',
          child: Text(task.requirement),
        ),
        TaskSection(
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
        TaskSection(
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
        TaskSection(
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
    );
  }
}
