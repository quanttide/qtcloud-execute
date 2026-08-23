import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task.dart';
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

  /// 状态列内定位任务卡片
  Finder columnCard(String statusWire, String taskId) => find.descendant(
    of: find.byKey(ValueKey('drop-column-$statusWire')),
    matching: find.byKey(ValueKey('task-card-$taskId')),
  );

  group('BoardView 状态泳道渲染', () {
    testWidgets('列=状态 四列固定，任务按状态归列', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('doing1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
        task('new1', '未开始任务', TaskStatus.notStarted, TaskPriority.medium),
        task('done1', '已完成任务', TaskStatus.done, TaskPriority.low),
      ]);
      await pumpBoard(tester, projection: projection);

      // 四列列头：状态文案各一次
      for (final status in TaskStatus.values) {
        expect(find.text(status.label), findsOneWidget);
      }
      // 任务落在对应状态列
      expect(columnCard('notStarted', 'new1'), findsOneWidget);
      expect(columnCard('inProgress', 'doing1'), findsOneWidget);
      // 折叠列（done 默认折叠）内任务不渲染
      expect(columnCard('done', 'done1'), findsNothing);
    });

    testWidgets('空列显示"暂无任务"占位（不空白）', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('doing1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
      await pumpBoard(tester, projection: projection);

      // 可见列（done 默认折叠）中空列：inProgress 非空，notStarted/reviewing 空
      expect(find.text('暂无任务'), findsNWidgets(2));
    });

    testWidgets('列内按 priority 排序（紧急→高→中→低）', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('s1', '中优先级', TaskStatus.inProgress, TaskPriority.medium),
        task('s2', '紧急任务', TaskStatus.inProgress, TaskPriority.urgent),
        task('s3', '高优先级', TaskStatus.inProgress, TaskPriority.high),
        task('s4', '低优先级', TaskStatus.inProgress, TaskPriority.low),
      ]);
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

  group('BoardView 列折叠', () {
    testWidgets('已完成列默认折叠，点击列头展开/收起', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('done1', '已完成任务', TaskStatus.done, TaskPriority.medium),
        task('doing1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
      await pumpBoard(tester, projection: projection);

      // 默认折叠：done 列任务不渲染，显示折叠提示
      expect(find.byKey(const ValueKey('task-card-done1')), findsNothing);
      expect(find.text('已折叠，点击展开'), findsOneWidget);
      // 其他列不受影响
      expect(find.byKey(const ValueKey('task-card-doing1')), findsOneWidget);

      // 点击列头展开
      await tester.tap(find.byKey(const ValueKey('column-header-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-card-done1')), findsOneWidget);
      expect(find.text('已折叠，点击展开'), findsNothing);

      // 再次点击收起
      await tester.tap(find.byKey(const ValueKey('column-header-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-card-done1')), findsNothing);
      expect(find.text('已折叠，点击展开'), findsOneWidget);
    });

    testWidgets('非已完成列默认展开', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('b1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
      await pumpBoard(tester, projection: projection);

      // 非已完成列默认展开：任务卡片可见
      expect(find.byKey(const ValueKey('task-card-b1')), findsOneWidget);
      // 折叠提示仅来自 done 列（默认折叠）
      expect(find.text('已折叠，点击展开'), findsOneWidget);
    });
  });

  group('BoardView 交互', () {
    testWidgets('点击卡片回调 onTaskTap（打开详情弹窗）', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('b1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
      Task? tapped;
      await pumpBoard(tester, projection: projection, onTaskTap: (t) => tapped = t);

      await tester.tap(find.byKey(const ValueKey('task-card-b1')));
      await tester.pumpAndSettle();

      expect(tapped?.id, 'b1');
    });

    testWidgets('拖拽跨列回调 onTaskDrop（状态推进）', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('b1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
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

      // 从 inProgress 列拖到 reviewing 列（水平位移）
      final card = find.byKey(const ValueKey('task-card-b1'));
      final target = find.byKey(const ValueKey('drop-column-reviewing'));
      final offset = tester.getCenter(target) - tester.getCenter(card);
      await tester.drag(card, offset);
      await tester.pumpAndSettle();

      expect(dropped?.id, 'b1');
      expect(targetStatus, TaskStatus.reviewing);
    });

    testWidgets('拖拽放到自身列不改变状态（同状态回调目标相同）', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('b1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
      TaskStatus? targetStatus;
      await pumpBoard(
        tester,
        projection: projection,
        onTaskDrop: (t, s) => targetStatus = s,
      );

      final card = find.byKey(const ValueKey('task-card-b1'));
      final target = find.byKey(const ValueKey('drop-column-inProgress'));
      final offset = tester.getCenter(target) - tester.getCenter(card);
      await tester.drag(card, offset);
      await tester.pumpAndSettle();

      expect(targetStatus, TaskStatus.inProgress);
    });
  });
}
