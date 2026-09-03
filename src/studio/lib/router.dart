import 'package:go_router/go_router.dart';

import 'screens/task_list_screen.dart';

/// 构建应用路由：仅清单页（执行云首页——二维看板）。
///
/// 任务详情走弹窗（TaskDetailDialog 就地操作），不再需要 /tasks/:id 路由。
/// Cubit 由 main.dart 的 MultiBlocProvider 注入，路由无需再传递仓储。
GoRouter buildRouter() {
  return GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const TaskListScreen())],
  );
}
