import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'router.dart';
import 'theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const QuantTideExecuteStudioApp());
}

class QuantTideExecuteStudioApp extends StatelessWidget {
  const QuantTideExecuteStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '量潮执行云',
      theme: buildTheme(),
      routerConfig: router,
    );
  }
}
