import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/task.dart';
import 'screens/task_detail.dart';
import 'screens/tasks.dart';

/// 构建应用路由：任务清单为首页，任务档案按 id 查看详情
///
/// [loadTasks] 可由调用方注入，便于测试替换种子数据来源。
GoRouter buildRouter({required Future<TaskList> Function() loadTasks}) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            TasksScreen(loadTasks: loadTasks),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (BuildContext context, GoRouterState state) =>
            TaskDetailScreen(
          taskId: state.pathParameters['id']!,
          loadTasks: loadTasks,
        ),
      ),
    ],
  );
}
