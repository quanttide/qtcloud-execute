import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'data/seed_tasks.dart';
import 'repositories/task_repository.dart';
import 'router.dart';
import 'states/board_cubit.dart';
import 'states/task_list_cubit.dart';
import 'theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const QuantTideExecuteStudioApp());
}

/// 应用根：注入仓储（种子/本地文件），MultiBlocProvider 提供 Cubit。
///
/// 仓储异步加载（asset/文件 IO）——加载完成前显示 loading，失败显示错误；
/// 测试通过 [loadRepository] 注入内存仓储（不碰文件/网络）。
class QuantTideExecuteStudioApp extends StatefulWidget {
  const QuantTideExecuteStudioApp({super.key, this.loadRepository});

  /// 仓储加载器，默认从种子 asset 构建；测试可注入替换
  final Future<TaskRepository> Function()? loadRepository;

  @override
  State<QuantTideExecuteStudioApp> createState() =>
      _QuantTideExecuteStudioAppState();
}

class _QuantTideExecuteStudioAppState extends State<QuantTideExecuteStudioApp> {
  TaskRepository? _repository;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final TaskRepository repository =
          await (widget.loadRepository ?? loadSeedRepository)();
      if (!mounted) return;
      setState(() => _repository = repository);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    if (repository == null) {
      // 仓储未就绪：loading / 加载失败
      return MaterialApp(
        title: '量潮执行云',
        theme: buildTheme(),
        home: Scaffold(
          body: _error != null
              ? Center(child: Text('加载失败：$_error'))
              : const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp.router(
      title: '量潮执行云',
      theme: buildTheme(),
      routerConfig: buildRouter(),
      // 在 Navigator 之上提供 Cubit——页面经 context.read 消费，不直接持有仓储
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => TaskListCubit(repository)),
          BlocProvider(create: (_) => BoardCubit(repository)),
        ],
        child: child!,
      ),
    );
  }
}
