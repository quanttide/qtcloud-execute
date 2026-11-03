import 'package:go_router/go_router.dart';

import 'screens/studio_shell.dart';

/// 构建应用路由：仅分区壳页（执行云首页——侧边导航：目标 / 任务 / 设置）。
///
/// 分区切换在壳内完成（IndexedStack，惯例同 qtcloud-media-studio）；
/// 任务详情走弹窗（TaskDetailDialog 就地操作），不需要 /tasks/:id 路由。
/// Cubit 由 main.dart 的 MultiBlocProvider 注入，路由无需再传递仓储。
GoRouter buildRouter() {
  return GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const StudioShell())],
  );
}
