import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/main.dart';
import 'package:qtcloud_execute_studio/models/task.dart';

/// 从种子文件同步读取任务数据（注入给应用，避免真实 asset 通道竞态）
Future<TaskList> loadSeedFromFile() async {
  final String raw = File('assets/data/seed_tasks.json').readAsStringSync();
  return TaskList.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    QuantTideExecuteStudioApp(loadTasks: loadSeedFromFile),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('任务清单渲染种子任务', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('量潮课堂实训基地账本配套审批'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('量潮课堂实训基地账本对账'), 300);
    expect(find.text('量潮课堂实训基地账本对账'), findsOneWidget);
    expect(find.text('依赖前置任务'), findsOneWidget);
  });

  testWidgets('点击任务卡片进入详情页', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('量潮课堂实训基地账本配套审批'));
    await tester.pumpAndSettle();

    expect(find.text('任务详情'), findsOneWidget);
    expect(find.text('档案：ledger-approval.md'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('任务清单'), findsOneWidget);
  });
}
