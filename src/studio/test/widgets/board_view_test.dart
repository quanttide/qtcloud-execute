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
    Map<TaskStatus, int> wipLimits = const {},
    ValueChanged<Task>? onTaskTap,
    void Function(Task task, TaskStatus targetStatus)? onTaskDrop,
    ValueChanged<TaskStatus>? onCreateTask,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardView(
            projection: projection,
            wipLimits: wipLimits,
            onTaskTap: onTaskTap,
            onTaskDrop: onTaskDrop,
            onCreateTask: onCreateTask,
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
    testWidgets('列=状态 四列固定，任务按状态归列（全部列展开）', (tester) async {
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
      // 任务落在对应状态列（真看板——无折叠，done 列也渲染）
      expect(columnCard('notStarted', 'new1'), findsOneWidget);
      expect(columnCard('inProgress', 'doing1'), findsOneWidget);
      expect(columnCard('done', 'done1'), findsOneWidget);
    });

    testWidgets('空列显示"暂无任务"占位（不空白，四列恒展开）', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('doing1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
      await pumpBoard(tester, projection: projection);

      // inProgress 非空，其余三列空（notStarted/reviewing/done）
      expect(find.text('暂无任务'), findsNWidgets(3));
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

  group('BoardView WIP 徽章', () {
    testWidgets('有上限时显示 count/limit；超限标红', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('b1', '任务1', TaskStatus.inProgress, TaskPriority.high),
        task('b2', '任务2', TaskStatus.inProgress, TaskPriority.medium),
      ]);
      // WIP 上限 = 1：inProgress 有 2 个任务，超限
      await pumpBoard(
        tester,
        projection: projection,
        wipLimits: const {TaskStatus.inProgress: 1},
      );

      final badgeContainer = find.byKey(
        const ValueKey('wip-badge-inProgress'),
      );
      // badge 是 Container 包装的 Text，直接查文本
      expect(badgeContainer, findsOneWidget);
      expect(find.text('2/1'), findsOneWidget);
    });

    testWidgets('未设上限的列不显示 WIP 徽章，显示计数', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('b1', '任务1', TaskStatus.inProgress, TaskPriority.high),
      ]);
      await pumpBoard(
        tester,
        projection: projection,
        wipLimits: const {TaskStatus.inProgress: 3},
      );

      expect(find.byKey(const ValueKey('wip-badge-inProgress')), findsOneWidget);
      // 未设上限的列（如 done）显示计数而非徽章
      expect(find.byKey(const ValueKey('column-count-done')), findsOneWidget);
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

    testWidgets('拖拽跨列回调 onTaskDrop（实时状态变更）', (tester) async {
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

    testWidgets('列头「+」回调 onCreateTask（目标状态列）', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('b1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
      TaskStatus? createStatus;
      await pumpBoard(
        tester,
        projection: projection,
        onCreateTask: (s) => createStatus = s,
      );

      await tester.tap(find.byKey(const ValueKey('create-task-notStarted')));
      await tester.pumpAndSettle();

      expect(createStatus, TaskStatus.notStarted);
    });

    testWidgets('未提供 onCreateTask 时不显示「+」', (tester) async {
      final projection = BoardProjection.fromTasks([
        task('b1', '进行中任务', TaskStatus.inProgress, TaskPriority.high),
      ]);
      await pumpBoard(tester, projection: projection);

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
