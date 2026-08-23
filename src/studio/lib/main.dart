import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'data/seed_tasks.dart';
import 'repositories/task_repository.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const QuantTideExecuteStudioApp());
}

class QuantTideExecuteStudioApp extends StatelessWidget {
  const QuantTideExecuteStudioApp({super.key, this.loadRepository});

  /// 仓储加载器，默认从种子 asset 构建；测试可注入替换
  final Future<TaskRepository> Function()? loadRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '量潮执行云',
      theme: buildTheme(),
      routerConfig: buildRouter(
        loadRepository: loadRepository ?? loadSeedRepository,
      ),
    );
  }
}
