import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/states/board_cubit.dart';
import 'package:qtcloud_execute_studio/widgets/task_create_dialog.dart';

void main() {
  /// 通过按钮打开弹窗（避免 pop 根路由问题）
  Future<List<TaskDraft>> pumpDialog(
    WidgetTester tester, {
    TaskStatus status = TaskStatus.notStarted,
  }) async {
    final created = <TaskDraft>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => TaskCreateDialog.show(
                  context,
                  status: status,
                  onCreate: created.add,
                ),
                child: const Text('打开新建'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开新建'));
    await tester.pumpAndSettle();
    return created;
  }

  group('TaskCreateDialog 渲染', () {
    testWidgets('渲染标题/优先级/类别/描述 + 目标状态列名', (tester) async {
      await pumpDialog(tester, status: TaskStatus.reviewing);

      expect(find.byType(TaskCreateDialog), findsOneWidget);
      // 目标状态列名展示在标题
      expect(find.text('新建任务 · 评审中'), findsOneWidget);
      expect(find.text('标题'), findsOneWidget);
      expect(find.text('优先级'), findsOneWidget);
      expect(find.text('类别'), findsOneWidget);
      expect(find.text('描述'), findsOneWidget);
      // 四档优先级初始 medium 高亮
      for (final priority in TaskPriority.values) {
        expect(find.text(priority.label), findsOneWidget);
      }
    });
  });

  group('TaskCreateDialog 提交', () {
    testWidgets('填写标题 + 分类 + 优先级，创建回调 TaskDraft', (tester) async {
      final created = await pumpDialog(tester, status: TaskStatus.inProgress);

      await tester.enterText(
        find.byKey(const ValueKey('create-title-field')),
        '新任务标题',
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-category-field')),
        '  product  ',
      );
      await tester.tap(find.byKey(const ValueKey('create-priority-urgent')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('create-submit')));
      await tester.pumpAndSettle();

      expect(created, hasLength(1));
      expect(created.last.title, '新任务标题');
      expect(created.last.category, 'product'); // trim 后提交
      expect(created.last.priority, TaskPriority.urgent);
      expect(created.last.description, isEmpty);
      // 提交后弹窗关闭
      expect(find.byType(TaskCreateDialog), findsNothing);
    });

    testWidgets('标题为空不提交（不回调，弹窗保持）', (tester) async {
      final created = await pumpDialog(tester);

      await tester.tap(find.byKey(const ValueKey('create-submit')));
      await tester.pumpAndSettle();

      expect(created, isEmpty);
      expect(find.byType(TaskCreateDialog), findsOneWidget);
    });

    testWidgets('分类留空提交：category 为 null', (tester) async {
      final created = await pumpDialog(tester);

      await tester.enterText(
        find.byKey(const ValueKey('create-title-field')),
        '无分类任务',
      );
      await tester.tap(find.byKey(const ValueKey('create-submit')));
      await tester.pumpAndSettle();

      expect(created, hasLength(1));
      expect(created.last.category, isNull);
    });
  });
}
