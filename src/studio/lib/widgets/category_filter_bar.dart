import 'package:flutter/material.dart';

import '../states/board_cubit.dart';

/// 分类过滤器（独立看板顶栏）——「全部」+ 各分类单选。
///
/// 数据源为当前项目任务中去重后的分类集合（[BoardState.categories]）。
/// 选择分类过滤看板（只显示该分类任务）；「全部」不过滤。
/// 与左侧项目导航（TaskListSwitcher）彻底分离——上游负责项目切换，
/// 本组件只负责分类视角。分类为业务自定义自由字符串（不枚举约束）。
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onSelect,
  });

  /// 可供选择的分类集合（当前项目去重；缺失时只渲染「全部」）
  final List<String> categories;

  /// 当前选中的分类；null = 全部
  final String? selectedCategory;

  /// 选择回调（null = 全部）
  final ValueChanged<String?>? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '类别',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(context, key: 'category-all', label: '全部'),
                  for (final category in categories)
                    _buildChip(
                      context,
                      key: 'category-$category',
                      label: category,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 单个分类 FilterChip（当前选中带对勾）。
  Widget _buildChip(
    BuildContext context, {
    required String key,
    required String label,
  }) {
    final isSelected = label == '全部'
        ? selectedCategory == null
        : selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: ValueKey(key),
        label: Text(label),
        selected: isSelected,
        showCheckmark: true,
        onSelected: (_) {
          if (label == '全部') {
            onSelect?.call(null);
          } else {
            onSelect?.call(label);
          }
        },
      ),
    );
  }
}
