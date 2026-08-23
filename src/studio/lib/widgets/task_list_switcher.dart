import 'package:flutter/material.dart';

import '../models/task_list.dart';

/// 左侧项目导航栏——独立的项目切换器（非过滤器/chip 形态）。
///
/// 每个项目一个垂直导航项：项目名 + 任务数；当前项目高亮
/// （背景色 + 左侧指示条）。点击回调 [onSwitch]；底部「新增项目」入口。
///
/// 定位为"项目隔离单元"切换——与分类过滤器（CategoryFilterBar）彻底分离。
class TaskListSwitcher extends StatelessWidget {
  const TaskListSwitcher({
    super.key,
    required this.lists,
    this.currentListId,
    this.onSwitch,
    this.onCreateList,
  });

  /// 全部项目（动态加载——新增项目自动出现）
  final List<TaskList> lists;

  /// 当前项目 id（高亮）
  final String? currentListId;

  /// 点击项目回调（switchList(id)——看板跟随）
  final ValueChanged<String>? onSwitch;

  /// 新增项目入口回调
  final VoidCallback? onCreateList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              '清单',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final list in lists)
                  _buildItem(context, list),
                if (onCreateList != null) _buildCreateItem(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 项目导航项：项目名 + 任务数；当前项高亮。
  Widget _buildItem(BuildContext context, TaskList list) {
    final theme = Theme.of(context);
    final selected = list.id == currentListId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey('list-${list.id}'),
          onTap: () => onSwitch?.call(list.id),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 当前项左侧指示条
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    list.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${list.tasks.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 新增项目入口（底部）
  Widget _buildCreateItem(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: const ValueKey('create-list'),
          onTap: onCreateList,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 3),
                const Icon(Icons.add, size: 18),
                const SizedBox(width: 10),
                Text(
                  '新增清单',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
