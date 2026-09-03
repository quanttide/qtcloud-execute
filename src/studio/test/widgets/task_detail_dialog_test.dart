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

  /// 通过按钮打开弹窗（避免 pop 根路由问题）；返回 (更新列表, 删除 id 列表)
  Future<(List<Task>, List<String>)> pumpDialog(
    WidgetTester tester, {
    Task task = baseTask,
  }) async {
    final updated = <Task>[];
    final deleted = <String>[];
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
                  onDeleted: deleted.add,
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
    return (updated, deleted);
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

  group('TaskDetailDialog 状态流转（真看板自由来回）', () {
    testWidgets('全部状态可选（无非法回退禁用）', (tester) async {
      await pumpDialog(tester); // 初始 inProgress

      // 所有非当前状态均为可点 OutlinedButton（前进与回退均合法）
      for (final status in TaskStatus.values) {
        if (status == TaskStatus.inProgress) continue;
        final btn = tester.widget<OutlinedButton>(
          find.byKey(ValueKey('status-${status.wire}')),
        );
        expect(btn.onPressed, isNotNull);
      }
      // 当前状态为 FilledButton
      final current = tester.widget<FilledButton>(
        find.byKey(const ValueKey('status-inProgress')),
      );
      expect(current.onPressed, isNotNull);
    });

    testWidgets('点击前进触发 onUpdated（含跳级）', (tester) async {
      final (updated, _) = await pumpDialog(tester);

      // 前进到 reviewing
      await tester.tap(find.byKey(const ValueKey('status-reviewing')));
      await tester.pump();
      expect(updated.last.status, TaskStatus.reviewing);
      expect(updated.last.priority, TaskPriority.medium);

      // 跳级前进到 done（允许）
      await tester.tap(find.byKey(const ValueKey('status-done')));
      await tester.pump();
      expect(updated.last.status, TaskStatus.done);
    });

    testWidgets('点击回退也触发 onUpdated（真看板——退回重做）', (tester) async {
      final (updated, _) = await pumpDialog(tester); // 初始 inProgress

      // 回退到 notStarted
      await tester.tap(find.byKey(const ValueKey('status-notStarted')));
      await tester.pump();
      expect(updated.last.status, TaskStatus.notStarted);

      // 再从 notStarted 前进回 inProgress（任意方向）
      await tester.tap(find.byKey(const ValueKey('status-inProgress')));
      await tester.pump();
      expect(updated.last.status, TaskStatus.inProgress);
    });

    testWidgets('点击当前状态视为无操作（不重复回调）', (tester) async {
      final (updated, _) = await pumpDialog(tester);

      // 当前状态是 FilledButton（点击不产生变更）
      await tester.tap(find.byKey(const ValueKey('status-inProgress')));
      await tester.pump();
      expect(updated, isEmpty);
    });
  });

  group('TaskDetailDialog 优先级选择', () {
    testWidgets('四档单选：点选即回调', (tester) async {
      final (updated, _) = await pumpDialog(tester); // 初始 medium

      await tester.tap(find.byKey(const ValueKey('priority-urgent')));
      await tester.pump();
      expect(updated.last.priority, TaskPriority.urgent);

      await tester.tap(find.byKey(const ValueKey('priority-low')));
      await tester.pump();
      expect(updated.last.priority, TaskPriority.low);
      expect(updated.last.status, TaskStatus.inProgress); // 不影响状态
    });
  });

  group('TaskDetailDialog 标题编辑', () {
    testWidgets('编辑标题 + 保存触发 onUpdated（trim 后提交）', (tester) async {
      final (updated, _) = await pumpDialog(tester);

      await tester.enterText(
        find.byKey(const ValueKey('title-field')),
        '  财务平台部署（改名）  ',
      );
      await tester.tap(find.byKey(const ValueKey('save-description')));
      await tester.pumpAndSettle();

      expect(updated, hasLength(1));
      expect(updated.last.title, '财务平台部署（改名）');
      // 描述未编辑保持原值
      expect(updated.last.description, 'ACR 实例凭证待确认，已发 issue');
      // 保存后弹窗关闭
      expect(find.byType(TaskDetailDialog), findsNothing);
    });

    testWidgets('标题清空后保存：保留原标题', (tester) async {
      final (updated, _) = await pumpDialog(tester);

      await tester.enterText(find.byKey(const ValueKey('title-field')), '  ');
      await tester.tap(find.byKey(const ValueKey('save-description')));
      await tester.pumpAndSettle();

      expect(updated.last.title, '财务平台部署');
    });
  });

  group('TaskDetailDialog 描述编辑', () {
    testWidgets('编辑 + 保存触发 onUpdated 并关闭弹窗', (tester) async {
      final (updated, _) = await pumpDialog(tester);

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

  group('TaskDetailDialog 删除', () {
    testWidgets('删除按钮 → 二次确认 → onDeleted 回调并关闭弹窗', (tester) async {
      final (updated, deleted) = await pumpDialog(tester);

      // 底部有删除按钮（红色 TextButton）
      expect(find.byKey(const ValueKey('delete-task')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('delete-task')));
      await tester.pumpAndSettle();

      // 二次确认弹窗出现，任务未删除
      expect(find.text('删除任务'), findsOneWidget);
      expect(deleted, isEmpty);
      expect(updated, isEmpty);

      // 取消：不删除
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(deleted, isEmpty);
      expect(find.byType(TaskDetailDialog), findsOneWidget);

      // 再次打开确认弹窗，点删除：回调任务 id 并关闭面板
      await tester.tap(find.byKey(const ValueKey('delete-task')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-delete')));
      await tester.pumpAndSettle();

      expect(deleted, ['t1']);
      expect(updated, isEmpty);
      expect(find.byType(TaskDetailDialog), findsNothing);
    });
  });
}
