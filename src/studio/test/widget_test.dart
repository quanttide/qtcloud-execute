import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/main.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';
import 'package:qtcloud_execute_studio/widgets/task_detail_dialog.dart';

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

/// 看板单元格内的任务卡片（按 分组×状态 交叉定位）
Finder cellCard(String groupWire, String statusWire, String taskId) =>
    find.descendant(
      of: find.byKey(ValueKey('drop-cell-$groupWire-$statusWire')),
      matching: find.byKey(ValueKey('task-card-$taskId')),
    );

void main() {
  testWidgets('首页渲染：清单切换器 + 二维看板（默认 qtdata）', (tester) async {
    await pumpApp(tester);

    // 清单切换器：数据驱动渲染三个清单，当前 qtdata 高亮
    expect(find.text('量潮数据'), findsOneWidget);
    expect(find.text('量潮课堂'), findsOneWidget);
    expect(find.text('量潮云'), findsOneWidget);
    final qtdata = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('list-qtdata')),
    );
    expect(qtdata.selected, isTrue);

    // 看板：列 = 分组（qtdata 实际存在 business/product），行 = 状态
    expect(find.text('分组\\状态'), findsOneWidget);
    expect(find.text('业务'), findsOneWidget);
    expect(find.text('产品'), findsOneWidget);
    expect(find.text('运营'), findsNothing); // qtdata 无运营分组
    for (final label in ['未开始', '进行中', '评审中', '已完成']) {
      expect(find.text(label), findsOneWidget);
    }

    // 任务卡片落在对应行列（business × inProgress）
    expect(find.text('客户项目结项推进'), findsOneWidget);
    expect(cellCard('business', 'inProgress', 'qtdata-project-closeout'),
        findsOneWidget);
    // 空单元格占位（不空白）
    expect(find.text('暂无任务'), findsWidgets);
  });

  testWidgets('清单切换：看板跟随（qtdata → qtclass），切换无副作用', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('量潮课堂'));
    await tester.pumpAndSettle();

    // 看板跟随 qtclass：列切换为 运营/产品，任务换源
    expect(find.text('运营'), findsOneWidget);
    expect(find.text('业务'), findsNothing);
    expect(find.text('实训基地招聘运营'), findsOneWidget);
    expect(find.text('课堂创新原型'), findsOneWidget);
    expect(find.text('客户项目结项推进'), findsNothing); // qtdata 任务消失

    // 当前清单高亮切换
    final qtclass = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('list-qtclass')),
    );
    expect(qtclass.selected, isTrue);

    // 点击当前清单不产生副作用（不重复加载——看板仍正常）
    await tester.tap(find.text('量潮课堂'));
    await tester.pumpAndSettle();
    expect(find.text('实训基地招聘运营'), findsOneWidget);
  });

  testWidgets('点击卡片打开详情弹窗（就地操作，不跳页）', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('客户项目结项推进'));
    await tester.pumpAndSettle();

    // 弹窗打开，四字段完整
    expect(find.byType(TaskDetailDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TaskDetailDialog),
        matching: find.text('客户项目结项推进'),
      ),
      findsOneWidget,
    );
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('优先级'), findsOneWidget);
    expect(find.text('描述'), findsOneWidget);

    // 初始状态 inProgress（FilledButton 高亮）、优先级高、描述带初始值
    expect(
      find.descendant(
        of: find.byType(TaskDetailDialog),
        matching: find.byKey(const ValueKey('status-inProgress')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('priority-high')), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('description-field')),
    );
    expect(field.controller!.text, '结项收尾沟通，落实结项各项事宜');

    // 关闭弹窗返回看板
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailDialog), findsNothing);
  });

  testWidgets('弹窗状态推进：即改即存，看板即时刷新（任务换行）', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('客户项目结项推进'));
    await tester.pumpAndSettle();

    // 前进到评审中（inProgress → reviewing，跳级前进允许）
    await tester.tap(find.byKey(const ValueKey('status-reviewing')));
    await tester.pumpAndSettle();

    // 看板即时刷新：任务从 inProgress 行移到 reviewing 行（弹窗仍开着）
    expect(
      cellCard('business', 'inProgress', 'qtdata-project-closeout'),
      findsNothing,
    );
    expect(
      cellCard('business', 'reviewing', 'qtdata-project-closeout'),
      findsOneWidget,
    );
  });

  testWidgets('弹窗描述编辑保存：弹窗关闭，看板卡片摘要即时更新', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('客户项目结项推进'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('description-field')),
      '结项收尾沟通，已确认验收时间',
    );
    await tester.tap(find.byKey(const ValueKey('save-description')));
    await tester.pumpAndSettle();

    // 保存后弹窗关闭，看板卡片摘要更新
    expect(find.byType(TaskDetailDialog), findsNothing);
    expect(find.text('结项收尾沟通，已确认验收时间'), findsOneWidget);
  });

  testWidgets('已完成行默认折叠，点击行头展开', (tester) async {
    await pumpApp(tester);

    // 切到量潮云（含已完成任务）
    await tester.tap(find.text('量潮云'));
    await tester.pumpAndSettle();

    // done 行默认折叠：任务卡片不渲染，显示折叠提示
    expect(
      find.byKey(const ValueKey('task-card-qtcloud-toolkit-refactor')),
      findsNothing,
    );
    expect(find.text('已折叠，点击展开'), findsOneWidget);

    // 点击行头展开：任务可见
    await tester.tap(find.byKey(const ValueKey('row-header-done')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('task-card-qtcloud-toolkit-refactor')),
      findsOneWidget,
    );
    expect(find.text('已折叠，点击展开'), findsNothing);
  });
}
