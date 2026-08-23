import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/widgets/task_detail_dialog.dart';

void main() {
  const Task baseTask = Task(
    id: 't1',
    title: '财务平台部署',
    description: 'ACR 实例凭证待确认，已发 issue',
    status: TaskStatus.inProgress,
    priority: TaskPriority.medium,
  );

  /// 通过按钮打开弹窗（避免 pop 根路由问题）
  Future<List<Task>> pumpDialog(WidgetTester tester, {Task task = baseTask}) async {
    final updated = <Task>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => TaskDetailDialog.show(
                  context,
                  task: task,
                  onUpdated: updated.add,
                ),
                child: const Text('打开详情'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开详情'));
    await tester.pumpAndSettle();
    return updated;
  }

  group('TaskDetailDialog 渲染', () {
    testWidgets('弹窗渲染四字段（title/状态/优先级/描述）', (tester) async {
      await pumpDialog(tester);

      expect(find.byType(TaskDetailDialog), findsOneWidget);
      expect(find.text('财务平台部署'), findsOneWidget);
      // 状态四态 + 标题
      expect(find.text('状态'), findsOneWidget);
      for (final status in TaskStatus.values) {
        expect(find.text(status.label), findsOneWidget);
      }
      // 优先级四档 + 标题
      expect(find.text('优先级'), findsOneWidget);
      for (final priority in TaskPriority.values) {
        expect(find.text(priority.label), findsOneWidget);
      }
      // 描述（可编辑输入框携带初始值）
      expect(find.text('描述'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('description-field')),
      );
      expect(field.controller!.text, 'ACR 实例凭证待确认，已发 issue');
    });
  });

  group('TaskDetailDialog 状态流转（只前进）', () {
    testWidgets('非法回退禁用、前进合法可点', (tester) async {
      await pumpDialog(tester); // 初始 inProgress

      // 回退目标（notStarted）禁用
      final back = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('status-notStarted')),
      );
      expect(back.onPressed, isNull);
      // 前进目标（reviewing/done）合法可点
      final reviewing = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('status-reviewing')),
      );
      expect(reviewing.onPressed, isNotNull);
      final done = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('status-done')),
      );
      expect(done.onPressed, isNotNull);
    });

    testWidgets('点击前进触发 onUpdated（含跳级）', (tester) async {
      final updated = await pumpDialog(tester);

      // 前进到 reviewing
      await tester.tap(find.byKey(const ValueKey('status-reviewing')));
      await tester.pump();
      expect(updated.last.status, TaskStatus.reviewing);
      expect(updated.last.priority, TaskPriority.medium);

      // 跳级前进到 done（允许）
      await tester.tap(find.byKey(const ValueKey('status-done')));
      await tester.pump();
      expect(updated.last.status, TaskStatus.done);

      // done 后无合法前进目标：inProgress 回退目标全部禁用
      final back = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('status-inProgress')),
      );
      expect(back.onPressed, isNull);
    });

    testWidgets('点击禁用目标不触发 onUpdated（回退拒绝）', (tester) async {
      final updated = await pumpDialog(tester);

      // 回退目标按钮禁用——点击无效（onPressed null）
      final back = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('status-notStarted')),
      );
      expect(back.onPressed, isNull);
      await tester.tap(
        find.byKey(const ValueKey('status-notStarted')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(updated, isEmpty);
    });

    testWidgets('原地前进视为无操作（不重复回调）', (tester) async {
      final updated = await pumpDialog(tester);

      // 当前状态是 FilledButton（点击不产生变更）
      await tester.tap(find.byKey(const ValueKey('status-inProgress')));
      await tester.pump();
      expect(updated, isEmpty);
    });
  });

  group('TaskDetailDialog 优先级选择', () {
    testWidgets('四档单选：点选即回调', (tester) async {
      final updated = await pumpDialog(tester); // 初始 medium

      await tester.tap(find.byKey(const ValueKey('priority-urgent')));
      await tester.pump();
      expect(updated.last.priority, TaskPriority.urgent);

      await tester.tap(find.byKey(const ValueKey('priority-low')));
      await tester.pump();
      expect(updated.last.priority, TaskPriority.low);
      expect(updated.last.status, TaskStatus.inProgress); // 不影响状态
    });
  });

  group('TaskDetailDialog 描述编辑', () {
    testWidgets('编辑 + 保存触发 onUpdated 并关闭弹窗', (tester) async {
      final updated = await pumpDialog(tester);

      await tester.enterText(
        find.byKey(const ValueKey('description-field')),
        '凭证已确认，等待客户回复',
      );
      await tester.tap(find.byKey(const ValueKey('save-description')));
      await tester.pumpAndSettle();

      expect(updated, hasLength(1));
      expect(updated.last.description, '凭证已确认，等待客户回复');
      expect(updated.last.status, TaskStatus.inProgress);
      expect(updated.last.priority, TaskPriority.medium);
      // 保存后弹窗关闭
      expect(find.byType(TaskDetailDialog), findsNothing);
    });
  });
}
