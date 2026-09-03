import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/widgets/task_card.dart';

void main() {
  const Task baseTask = Task(
    id: 't1',
    title: '财务平台部署',
    description: 'ACR 实例凭证待确认，已发 issue',
    status: TaskStatus.inProgress,
    priority: TaskPriority.urgent,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    Task task = baseTask,
    VoidCallback? onTap,
    void Function(DraggableDetails)? onDragEnd,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TaskCard(task: task, onTap: onTap, onDragEnd: onDragEnd),
          ),
        ),
      ),
    );
  }

  group('TaskCard 渲染', () {
    testWidgets('title + description 摘要渲染', (tester) async {
      await pumpCard(tester);

      expect(find.text('财务平台部署'), findsOneWidget);
      expect(find.text('ACR 实例凭证待确认，已发 issue'), findsOneWidget);
    });

    testWidgets('priority 色点四档颜色正确（紧急红/高橙/中蓝/低灰）', (tester) async {
      const cases = {
        TaskPriority.urgent: Colors.red,
        TaskPriority.high: Colors.orange,
        TaskPriority.medium: Colors.blue,
        TaskPriority.low: Colors.grey,
      };
      for (final entry in cases.entries) {
        await pumpCard(
          tester,
          task: Task(
            id: entry.key.wire,
            title: '任务',
            description: '',
            status: TaskStatus.notStarted,
            priority: entry.key,
          ),
        );

        final dot = tester.widget<Container>(
          find.byKey(ValueKey('priority-dot-${entry.key.wire}')),
        );
        final decoration = dot.decoration as BoxDecoration;
        expect(decoration.color, entry.value);
        expect(decoration.shape, BoxShape.circle);
      }
      // 静态映射一致
      expect(TaskCard.colorOf(TaskPriority.urgent), Colors.red);
      expect(TaskCard.colorOf(TaskPriority.high), Colors.orange);
      expect(TaskCard.colorOf(TaskPriority.medium), Colors.blue);
      expect(TaskCard.colorOf(TaskPriority.low), Colors.grey);
    });

    testWidgets('状态不显示，优先级标签显示（卡片展示优先级信息）', (tester) async {
      await pumpCard(tester); // baseTask: inProgress / urgent

      // 状态文案不显示（由看板行表达，卡片不重复）
      expect(find.text('进行中'), findsNothing);
      // 优先级标签显示（本次新增——卡片直观展示优先级）
      expect(find.text('紧急'), findsOneWidget);
      expect(find.byKey(const ValueKey('priority-label-t1')), findsOneWidget);
    });

    testWidgets('空 description 不显示摘要行', (tester) async {
      await pumpCard(
        tester,
        task: Task(
          id: 't2',
          title: '无描述任务',
          description: '',
          status: TaskStatus.notStarted,
          priority: TaskPriority.low,
        ),
      );

      expect(find.text('无描述任务'), findsOneWidget);
      // 只有一张卡片：description 为空不渲染摘要；但 priority label 显示
      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(TaskCard),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      // 非空文本 = 标题 + 优先级标签（低）；无 description 摘要
      expect(texts.where((t) => t != null && t.isNotEmpty), ['无描述任务', '低']);
    });
  });

  group('TaskCard 交互', () {
    testWidgets('点击触发 onTap（打开详情弹窗用）', (tester) async {
      Task? tapped;
      await pumpCard(tester, onTap: () => tapped = baseTask);

      await tester.tap(find.text('财务平台部署'));
      await tester.pumpAndSettle();

      expect(tapped, baseTask);
    });

    testWidgets('桌面拖拽触发 onDragEnd', (tester) async {
      DraggableDetails? details;
      await pumpCard(tester, onDragEnd: (d) => details = d);

      await tester.drag(find.byType(TaskCard), const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(details, isNotNull);
      expect(details!.wasAccepted, isFalse);
    });
  });
}
