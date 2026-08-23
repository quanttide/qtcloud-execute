import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
import 'package:qtcloud_execute_studio/models/task_list.dart';
import 'package:qtcloud_execute_studio/states/board_cubit.dart';
import 'package:qtcloud_execute_studio/widgets/board_view.dart';
import 'package:qtcloud_execute_studio/widgets/task_card.dart';

void main() {
  Task task(String id, String title, TaskStatus status, TaskPriority priority) =>
      Task(
        id: id,
        title: title,
        description: '',
        status: status,
        priority: priority,
      );

  Future<void> pumpBoard(
    WidgetTester tester, {
    required BoardProjection projection,
    ValueChanged<Task>? onTaskTap,
    void Function(Task task, TaskStatus targetStatus)? onTaskDrop,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardView(
            projection: projection,
            onTaskTap: onTaskTap,
            onTaskDrop: onTaskDrop,
          ),
        ),
      ),
    );
  }

  group('BoardView 矩阵渲染', () {
    testWidgets('列=分组 × 行=状态 交叉定位（投影矩阵渲染）', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.business: [
          task('b-doing', '结项推进', TaskStatus.inProgress, TaskPriority.high),
        ],
        Group.product: [
          task('p-new', '产品调研', TaskStatus.notStarted, TaskPriority.medium),
        ],
      });
      await pumpBoard(tester, projection: projection);

      // 列头：分组（含角头）
      expect(find.text('分组\\状态'), findsOneWidget);
      expect(find.text('业务'), findsOneWidget);
      expect(find.text('产品'), findsOneWidget);
      // 行头：四状态
      for (final status in TaskStatus.values) {
        expect(find.text(status.label), findsOneWidget);
      }
      // 任务落在对应行列
      expect(find.text('结项推进'), findsOneWidget); // business × inProgress
      expect(find.text('产品调研'), findsOneWidget); // product × notStarted
    });

    testWidgets('仅渲染该清单实际存在的分组列', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.operation: [
          task('o1', '运营排期', TaskStatus.inProgress, TaskPriority.urgent),
        ],
      });
      await pumpBoard(tester, projection: projection);

      expect(find.text('运营'), findsOneWidget);
      expect(find.text('业务'), findsNothing);
      expect(find.text('产品'), findsNothing);
    });

    testWidgets('空单元格显示"暂无任务"占位（不空白）', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.business: [
          task('b-doing', '结项推进', TaskStatus.inProgress, TaskPriority.high),
        ],
        Group.product: [
          task('p-new', '产品调研', TaskStatus.notStarted, TaskPriority.medium),
        ],
      });
      await pumpBoard(tester, projection: projection);

      // 可见行（done 默认折叠）中空单元格：2 列 × 3 行 - 2 个非空 = 4 个占位
      expect(find.text('暂无任务'), findsNWidgets(4));
    });

    testWidgets('行内按 priority 排序（紧急→高→中→低）', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.business: [
          task('s1', '中优先级', TaskStatus.inProgress, TaskPriority.medium),
          task('s2', '紧急任务', TaskStatus.inProgress, TaskPriority.urgent),
          task('s3', '高优先级', TaskStatus.inProgress, TaskPriority.high),
          task('s4', '低优先级', TaskStatus.inProgress, TaskPriority.low),
        ],
      });
      await pumpBoard(tester, projection: projection);

      final titles = tester
          .widgetList<TaskCard>(find.byType(TaskCard))
          .map((c) => c.task.title)
          .toList();
      expect(titles, ['紧急任务', '高优先级', '中优先级', '低优先级']);
      // 排序依据为 priority.index（urgent=0…low=3）
      expect(TaskPriority.urgent.index, 0);
      expect(TaskPriority.low.index, 3);
    });
  });

  group('BoardView 行折叠', () {
    testWidgets('已完成行默认折叠，点击行头展开/收起', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.business: [
          task('done1', '已完成任务', TaskStatus.done, TaskPriority.medium),
          task('doing1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
        ],
      });
      await pumpBoard(tester, projection: projection);

      // 默认折叠：done 行任务不渲染，显示折叠提示
      expect(find.byKey(const ValueKey('task-card-done1')), findsNothing);
      expect(find.text('已折叠，点击展开'), findsOneWidget);
      // 其他行不受影响
      expect(find.byKey(const ValueKey('task-card-doing1')), findsOneWidget);

      // 点击行头展开
      await tester.tap(find.byKey(const ValueKey('row-header-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-card-done1')), findsOneWidget);
      expect(find.text('已折叠，点击展开'), findsNothing);

      // 再次点击收起
      await tester.tap(find.byKey(const ValueKey('row-header-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-card-done1')), findsNothing);
      expect(find.text('已折叠，点击展开'), findsOneWidget);
    });

    testWidgets('非已完成行默认展开', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.business: [
          task('b1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
        ],
      });
      await pumpBoard(tester, projection: projection);

      // 非已完成行默认展开：任务卡片可见
      expect(find.byKey(const ValueKey('task-card-b1')), findsOneWidget);
      // 折叠提示仅来自 done 行（默认折叠）
      expect(find.text('已折叠，点击展开'), findsOneWidget);
    });
  });

  group('BoardView 交互', () {
    testWidgets('点击卡片回调 onTaskTap（打开详情弹窗）', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.business: [
          task('b1', '结项推进', TaskStatus.inProgress, TaskPriority.high),
        ],
      });
      Task? tapped;
      await pumpBoard(tester, projection: projection, onTaskTap: (t) => tapped = t);

      await tester.tap(find.byKey(const ValueKey('task-card-b1')));
      await tester.pumpAndSettle();

      expect(tapped?.id, 'b1');
    });

    testWidgets('拖拽跨行回调 onTaskDrop（状态推进）', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.business: [
          task('b1', '结项推进', TaskStatus.inProgress, TaskPriority.high),
        ],
      });
      Task? dropped;
      TaskStatus? targetStatus;
      await pumpBoard(
        tester,
        projection: projection,
        onTaskDrop: (t, s) {
          dropped = t;
          targetStatus = s;
        },
      );

      // 从 inProgress 行拖到 reviewing 行（垂直位移——不触发水平滚动）
      final card = find.byKey(const ValueKey('task-card-b1'));
      final target = find.byKey(
        const ValueKey('drop-cell-business-reviewing'),
      );
      final offset = tester.getCenter(target) - tester.getCenter(card);
      await tester.drag(card, offset);
      await tester.pumpAndSettle();

      expect(dropped?.id, 'b1');
      expect(targetStatus, TaskStatus.reviewing);
    });

    testWidgets('拖拽放到自身行不改变状态（同状态回调目标相同）', (tester) async {
      final projection = BoardProjection.fromGrouped({
        Group.business: [
          task('b1', '结项推进', TaskStatus.inProgress, TaskPriority.high),
        ],
      });
      TaskStatus? targetStatus;
      await pumpBoard(
        tester,
        projection: projection,
        onTaskDrop: (t, s) => targetStatus = s,
      );

      final card = find.byKey(const ValueKey('task-card-b1'));
      final target = find.byKey(
        const ValueKey('drop-cell-business-inProgress'),
      );
      final offset = tester.getCenter(target) - tester.getCenter(card);
      await tester.drag(card, offset);
      await tester.pumpAndSettle();

      expect(targetStatus, TaskStatus.inProgress);
    });
  });
}
