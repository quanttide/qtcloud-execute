import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/tasks.dart';

/// 应用路由：任务清单为首页
final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const TasksScreen(),
    ),
  ],
);
