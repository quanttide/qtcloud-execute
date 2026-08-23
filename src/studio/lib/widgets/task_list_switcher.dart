import 'package:flutter/material.dart';

import '../models/task_list.dart';

/// 顶部清单切换器——数据驱动（从 TaskListCubit.lists 渲染，不静态假设业务数量）。
///
/// 当前清单高亮；点击清单项回调 [onSwitch]（switchList(id)，看板跟随）；
/// 新增清单入口回调 [onCreateList]。
class TaskListSwitcher extends StatelessWidget {
  const TaskListSwitcher({
    super.key,
    required this.lists,
    this.currentListId,
    this.onSwitch,
    this.onCreateList,
  });

  /// 全部业务清单（动态加载——新增清单自动出现）
  final List<TaskList> lists;

  /// 当前清单 id（高亮）
  final String? currentListId;

  /// 点击清单项回调（switchList(id)）
  final ValueChanged<String>? onSwitch;

  /// 新增清单入口回调
  final VoidCallback? onCreateList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final list in lists)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: ValueKey('list-${list.id}'),
                label: Text(list.name),
                selected: list.id == currentListId,
                onSelected: (_) => onSwitch?.call(list.id),
              ),
            ),
          if (onCreateList != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                key: const ValueKey('create-list'),
                avatar: Icon(
                  Icons.add,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                label: const Text('新增'),
                onPressed: onCreateList,
              ),
            ),
        ],
      ),
    );
  }
}
