import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/main.dart';
import 'package:qtcloud_execute_studio/repositories/task_repository.dart';
import 'package:qtcloud_execute_studio/widgets/task_create_dialog.dart';
import 'package:qtcloud_execute_studio/widgets/task_detail_dialog.dart';

/// 从测试夹具同步读取构建内存仓储（注入给应用，避免真实 asset 通道竞态）
Future<TaskRepository> loadFixtureRepository() async {
  final String raw = File('test/fixtures/tasks.json').readAsStringSync();
  return InMemoryTaskRepository.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
  );
}

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    QuantTideExecuteStudioApp(loadRepository: loadFixtureRepository),
  );
  await tester.pumpAndSettle();
}

/// 状态列看板内定位任务卡片
Finder columnCard(String statusWire, String taskId) => find.descendant(
  of: find.byKey(ValueKey('drop-column-$statusWire')),
  matching: find.byKey(ValueKey('task-card-$taskId')),
);

void main() {
  testWidgets('首页渲染：项目切换器 + 状态泳道看板（默认 qtdata）', (tester) async {
    await pumpApp(tester);

    // 项目导航栏：独立切换器渲染三个项目，当前 qtdata 项存在
    expect(find.text('量潮数据'), findsOneWidget);
    expect(find.text('量潮课堂'), findsOneWidget);
    expect(find.text('量潮云'), findsOneWidget);
    expect(find.byKey(const ValueKey('list-qtdata')), findsOneWidget);

    // 看板：四列 = 四状态（未开始/进行中/评审中/已完成）
    for (final label in ['未开始', '进行中', '评审中', '已完成']) {
      expect(find.text(label), findsOneWidget);
    }

    // 任务卡片落在对应状态列（inProgress 列）
    expect(find.text('客户项目结项推进'), findsOneWidget);
    expect(columnCard('inProgress', 'qtdata-project-closeout'), findsOneWidget);
    // 空列占位（不空白）
    expect(find.text('暂无任务'), findsWidgets);
  });

  testWidgets('项目切换：看板跟随（qtdata → qtclass），切换无副作用', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('量潮课堂'));
    await tester.pumpAndSettle();

    // 看板跟随 qtclass：任务换源，状态列仍固定四列
    expect(find.text('实训基地招聘运营'), findsOneWidget);
    expect(find.text('课堂创新原型'), findsOneWidget);
    expect(find.text('客户项目结项推进'), findsNothing); // qtdata 任务消失

    // 当前项目高亮切换（qtclass 导航项存在）
    expect(find.byKey(const ValueKey('list-qtclass')), findsOneWidget);
    expect(find.byKey(const ValueKey('list-qtdata')), findsOneWidget);

    // 点击当前项目不产生副作用（不重复加载——看板仍正常）
    await tester.tap(find.text('量潮课堂'));
    await tester.pumpAndSettle();
    expect(find.text('实训基地招聘运营'), findsOneWidget);
  });

  testWidgets('点击卡片打开详情弹窗（就地操作，不跳页）', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('客户项目结项推进'));
    await tester.pumpAndSettle();

    // 弹窗内四字段（限定在弹窗内）
    expect(find.byType(TaskDetailDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TaskDetailDialog),
        matching: find.text('客户项目结项推进'),
      ),
      findsOneWidget,
    );
    for (final label in ['状态', '优先级', '描述']) {
      expect(
        find.descendant(
          of: find.byType(TaskDetailDialog),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

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

  testWidgets('弹窗状态变更：即改即存，看板即时刷新（任务跨列，自由来回）', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('客户项目结项推进'));
    await tester.pumpAndSettle();

    // 前进到评审中（inProgress → reviewing）
    await tester.tap(find.byKey(const ValueKey('status-reviewing')));
    await tester.pumpAndSettle();

    // 看板即时刷新：任务从 inProgress 列移到 reviewing 列（弹窗仍开着）
    expect(columnCard('inProgress', 'qtdata-project-closeout'), findsNothing);
    expect(columnCard('reviewing', 'qtdata-project-closeout'), findsOneWidget);

    // 回退到未开始（真看板自由来回——退回重做）
    await tester.tap(find.byKey(const ValueKey('status-notStarted')));
    await tester.pumpAndSettle();
    expect(columnCard('notStarted', 'qtdata-project-closeout'), findsOneWidget);
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

  testWidgets('已完成任务始终可见（真看板——列恒展开，无折叠）', (tester) async {
    await pumpApp(tester);

    // 切到量潮云（含已完成任务）
    await tester.tap(find.text('量潮云'));
    await tester.pumpAndSettle();

    // done 列任务始终渲染（无折叠）
    expect(
      find.byKey(const ValueKey('task-card-qtcloud-toolkit-refactor')),
      findsOneWidget,
    );
    expect(find.text('已折叠，点击展开'), findsNothing);
  });

  testWidgets('列头「+」新建任务：表单提交后看板即时出现', (tester) async {
    await pumpApp(tester);

    // 点击未开始列头「+」
    await tester.tap(find.byKey(const ValueKey('create-task-notStarted')));
    await tester.pumpAndSettle();

    expect(find.byType(TaskCreateDialog), findsOneWidget);

    // 填写标题 + 创建
    await tester.enterText(
      find.byKey(const ValueKey('create-title-field')),
      '新建的未开始任务',
    );
    await tester.tap(find.byKey(const ValueKey('create-submit')));
    await tester.pumpAndSettle();

    // 弹窗关闭，看板即时出现新任务（notStarted 列）
    expect(find.byType(TaskCreateDialog), findsNothing);
    expect(find.text('新建的未开始任务'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('drop-column-notStarted')),
        matching: find.text('新建的未开始任务'),
      ),
      findsOneWidget,
    );
  });
}
