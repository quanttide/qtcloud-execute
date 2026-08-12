import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'data/seed_tasks.dart';
import 'models/task.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const QuantTideExecuteStudioApp());
}

class QuantTideExecuteStudioApp extends StatelessWidget {
  const QuantTideExecuteStudioApp({super.key, this.loadTasks});

  /// 任务数据来源，默认从种子 asset 加载；测试可注入替换
  final Future<TaskList> Function()? loadTasks;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '量潮执行云',
      theme: buildTheme(),
      routerConfig: buildRouter(loadTasks: loadTasks ?? loadSeedTasks),
    );
  }
}
