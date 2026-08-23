import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_execute_studio/widgets/category_filter_bar.dart';

void main() {
  Future<void> pumpFilter(
    WidgetTester tester, {
    List<String> categories = const [],
    String? selectedCategory,
    ValueChanged<String?>? onSelect,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryFilterBar(
            categories: categories,
            selectedCategory: selectedCategory,
            onSelect: onSelect,
          ),
        ),
      ),
    );
  }

  group('CategoryFilterBar 渲染', () {
    testWidgets('「全部」+ 各分类渲染', (tester) async {
      await pumpFilter(
        tester,
        categories: const ['business', 'product', 'operation'],
      );

      expect(find.text('类别'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('business'), findsOneWidget);
      expect(find.text('product'), findsOneWidget);
      expect(find.text('operation'), findsOneWidget);
    });

    testWidgets('无分类时只渲染「全部」', (tester) async {
      await pumpFilter(tester);

      expect(find.text('全部'), findsOneWidget);
      expect(find.byType(FilterChip), findsOneWidget);
    });

    testWidgets('选中分类高亮，「全部」不高亮', (tester) async {
      await pumpFilter(
        tester,
        categories: const ['business'],
        selectedCategory: 'business',
      );

      final category = tester.widget<FilterChip>(
        find.byKey(const ValueKey('category-business')),
      );
      expect(category.selected, isTrue);
      final all = tester.widget<FilterChip>(
        find.byKey(const ValueKey('category-all')),
      );
      expect(all.selected, isFalse);
    });

    testWidgets('选中「全部」时高亮全部', (tester) async {
      await pumpFilter(
        tester,
        categories: const ['business'],
        selectedCategory: null,
      );

      final all = tester.widget<FilterChip>(
        find.byKey(const ValueKey('category-all')),
      );
      expect(all.selected, isTrue);
    });
  });

  group('CategoryFilterBar 交互', () {
    testWidgets('点击分类回调 onSelect(category)', (tester) async {
      String? selected;
      await pumpFilter(
        tester,
        categories: const ['business', 'product'],
        onSelect: (c) => selected = c,
      );

      await tester.tap(find.text('product'));
      await tester.pumpAndSettle();

      expect(selected, 'product');
    });

    testWidgets('点击「全部」回调 onSelect(null)', (tester) async {
      String? selected;
      await pumpFilter(
        tester,
        categories: const ['business'],
        onSelect: (c) => selected = c,
      );

      await tester.tap(find.byKey(const ValueKey('category-all')));
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });
}
