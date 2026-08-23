import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/main.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';

/// 从种子文件同步读取构建内存仓储（注入给应用，避免真实 asset 通道竞态）
Future<TaskRepository> loadSeedRepositoryFromFile() async {
  final String raw = File('assets/data/seed_tasks.json').readAsStringSync();
  return InMemoryTaskRepository.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    QuantTideExecuteStudioApp(loadRepository: loadSeedRepositoryFromFile),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('任务清单渲染种子任务', (WidgetTester tester) async {
    await pumpApp(tester);

    // 视口内任务直接可见
    expect(find.text('客户项目结项推进'), findsOneWidget);
    expect(find.text('进行中'), findsWidgets);

    // 视口外任务滚动后可见
    await tester.scrollUntilVisible(find.text('财务平台部署'), 300);
    expect(find.text('财务平台部署'), findsOneWidget);
    expect(find.text('紧急'), findsOneWidget);
  });

  testWidgets('点击任务卡片进入详情页', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('客户项目结项推进'));
    await tester.pumpAndSettle();

    expect(find.text('任务详情'), findsOneWidget);
    expect(
      find.text('结项收尾沟通，落实结项各项事宜'),
      findsOneWidget,
    );
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('优先级'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('高'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('任务清单'), findsOneWidget);
  });
}
