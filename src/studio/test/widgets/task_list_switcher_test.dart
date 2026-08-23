import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/models/task_list.dart';
import 'package:qtcloud_execute_studio/widgets/task_list_switcher.dart';

void main() {
  const List<TaskList> lists = [
    TaskList(id: 'qtdata', name: '量潮数据', groups: [Group.business, Group.product]),
    TaskList(id: 'qtclass', name: '量潮课堂', groups: [Group.operation, Group.product]),
    TaskList(id: 'qtcloud', name: '量潮云', groups: [Group.product]),
  ];

  Future<void> pumpSwitcher(
    WidgetTester tester, {
    List<TaskList>? items,
    String? currentListId,
    ValueChanged<String>? onSwitch,
    VoidCallback? onCreateList,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListSwitcher(
            lists: items ?? lists,
            currentListId: currentListId,
            onSwitch: onSwitch,
            onCreateList: onCreateList,
          ),
        ),
      ),
    );
  }

  group('TaskListSwitcher 渲染', () {
    testWidgets('数据驱动渲染全部清单（不静态假设）', (tester) async {
      await pumpSwitcher(tester);

      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.text('量潮数据'), findsOneWidget);
      expect(find.text('量潮课堂'), findsOneWidget);
      expect(find.text('量潮云'), findsOneWidget);
    });

    testWidgets('新增清单自动出现（数据驱动）', (tester) async {
      await pumpSwitcher(tester, items: const [
        TaskList(id: 'qtdata', name: '量潮数据', groups: [Group.product]),
      ]);
      expect(find.text('量潮数据'), findsOneWidget);
      expect(find.text('量潮课堂'), findsNothing);

      // 新清单加入后自动出现
      await pumpSwitcher(tester, items: const [
        TaskList(id: 'qtdata', name: '量潮数据', groups: [Group.product]),
        TaskList(id: 'newbiz', name: '新业务', groups: [Group.operation]),
      ]);
      expect(find.text('新业务'), findsOneWidget);
    });

    testWidgets('当前清单高亮（selected）', (tester) async {
      await pumpSwitcher(tester, currentListId: 'qtclass');

      final qtclass = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('list-qtclass')),
      );
      expect(qtclass.selected, isTrue);
      final qtdata = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('list-qtdata')),
      );
      expect(qtdata.selected, isFalse);
    });

    testWidgets('无当前清单时无高亮', (tester) async {
      await pumpSwitcher(tester, currentListId: null);

      for (final list in lists) {
        final chip = tester.widget<ChoiceChip>(
          find.byKey(ValueKey('list-${list.id}')),
        );
        expect(chip.selected, isFalse);
      }
    });
  });

  group('TaskListSwitcher 交互', () {
    testWidgets('点击清单项回调 onSwitch(id)', (tester) async {
      String? switched;
      await pumpSwitcher(tester, onSwitch: (id) => switched = id);

      await tester.tap(find.byKey(const ValueKey('list-qtcloud')));
      await tester.pumpAndSettle();

      expect(switched, 'qtcloud');
    });

    testWidgets('点击当前清单也回调（切换无副作用）', (tester) async {
      String? switched;
      await pumpSwitcher(
        tester,
        currentListId: 'qtdata',
        onSwitch: (id) => switched = id,
      );

      await tester.tap(find.byKey(const ValueKey('list-qtdata')));
      await tester.pumpAndSettle();

      expect(switched, 'qtdata');
    });

    testWidgets('新增清单入口回调 onCreateList', (tester) async {
      bool created = false;
      await pumpSwitcher(tester, onCreateList: () => created = true);

      await tester.tap(find.byKey(const ValueKey('create-list')));
      await tester.pumpAndSettle();

      expect(created, isTrue);
    });

    testWidgets('未提供 onCreateList 时不显示新增入口', (tester) async {
      await pumpSwitcher(tester);

      expect(find.byKey(const ValueKey('create-list')), findsNothing);
    });
  });
}
