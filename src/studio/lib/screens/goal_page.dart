import 'package:flutter/material.dart';

/// 目标页：长期目标居顶，分解出的短期目标（关键结果）缩进其下。
///
/// v0.1.x 内置内容（与 profile qtcloud「目标」一致）；服务端目标 API
/// 落地后改由仓储注入。进度由挂载任务的真实状态计算，不在本页写死。
class GoalPage extends StatelessWidget {
  const GoalPage({super.key});

  /// 长期目标
  static const String longTermGoal = '量潮云成长为主营业务';

  /// 短期目标（长期目标的关键结果）
  static const List<String> shortTermGoals = [
    '媒体云：原型变生产可用上线，获取第一个付费客户',
    '执行云：原型变生产可用上线，获取第一个付费客户',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('目标'),
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('新建目标：功能开发中')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('新目标'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              longTermGoal,
              key: const ValueKey('long-term-goal'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final goal in shortTermGoals)
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 12),
                child: Text(
                  goal,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
