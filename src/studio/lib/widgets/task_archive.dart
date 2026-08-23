import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_sections.dart';

/// 任务档案视图：状态、优先级、描述
class TaskArchiveView extends StatelessWidget {
  const TaskArchiveView({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskSection(
          icon: Icons.playlist_add_check_outlined,
          title: '状态',
          child: Text(task.status.label),
        ),
        TaskSection(
          icon: Icons.flag_outlined,
          title: '优先级',
          child: Text(task.priority.label),
        ),
        TaskSection(
          icon: Icons.description_outlined,
          title: '描述',
          child: Text(task.description),
        ),
      ],
    );
  }
}
