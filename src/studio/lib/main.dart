import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'repositories/task_repository.dart';
import 'router.dart';
import 'states/board_cubit.dart';
import 'states/task_list_cubit.dart';
import 'theme.dart';

/// API 基地址：`--dart-define=QTCLOUD_EXECUTE_API_BASE_URL=<url>`（生产在部署时注入）。
///
/// 规范对齐 qtcloud-delib（`QTCLOUD_DELIB_API_BASE_URL`）：生产指向系统级 API 网关
/// `https://api.quanttide.com/qtcloud-execute`，由网关转发到 FC；应用层不做 CORS（网关负责）。
const String _apiBaseUrlEnv = String.fromEnvironment('QTCLOUD_EXECUTE_API_BASE_URL');

/// 默认 API 基地址：
/// - `--dart-define=QTCLOUD_EXECUTE_API_BASE_URL` 显式指定（生产网关/真实设备）；
/// - Android 模拟器经 `10.0.2.2` 访问宿主机；
/// - 其余平台（桌面 / Web）默认 `localhost`。
String _apiBaseUrl() {
  if (_apiBaseUrlEnv.isNotEmpty) {
    return _apiBaseUrlEnv;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

/// 构建服务端 API 仓储（运行期默认数据源）。
Future<TaskRepository> loadApiRepository() async =>
    ApiTaskRepository(baseUrl: _apiBaseUrl());

void main() {
  usePathUrlStrategy();
  runApp(const QuantTideExecuteStudioApp());
}

/// 应用根：注入仓储（服务端 API），MultiBlocProvider 提供 Cubit。
///
/// 仓储异步加载（API 请求）——加载完成前显示 loading，失败显示错误；
/// 测试通过 [loadRepository] 注入内存仓储（不碰文件/网络）。
class QuantTideExecuteStudioApp extends StatefulWidget {
  const QuantTideExecuteStudioApp({super.key, this.loadRepository});

  /// 仓储加载器，默认从服务端 API 构建；测试可注入替换
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
          await (widget.loadRepository ?? loadApiRepository)();
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
