import 'package:flutter/material.dart';

import 'task_list_screen.dart';

/// 侧边导航壳：目标（规划中）/ 任务（看板首页）/ 设置（底部图标）。
///
/// 惯例对齐 qtcloud-media-studio 的 StudioShell：NavigationRail 两分区 +
/// trailing 设置入口，IndexedStack 保活各分区。
class StudioShell extends StatefulWidget {
  const StudioShell({super.key});

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  /// 当前分区（0 目标 / 1 任务）；初始落在任务看板（应用既有首页）
  int _index = 1;
  bool _settings = false;

  void _select(int i) {
    setState(() {
      _index = i;
      _settings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            selectedIndex: _settings ? null : _index,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.flag_outlined),
                label: Text('目标'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.checklist_outlined),
                label: Text('任务'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    tooltip: '设置',
                    onPressed: () => setState(() => _settings = true),
                    icon: Icon(
                      Icons.settings_outlined,
                      color: _settings
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _settings ? 2 : _index,
              children: const [
                _PlaceholderPage(title: '目标'),
                TaskListScreen(),
                _PlaceholderPage(title: '设置'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 预留分区页：目标、设置尚未开发（惯例同 qtcloud-media-studio 的 PlaceholderPage）。
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('规划中')),
    );
  }
}
