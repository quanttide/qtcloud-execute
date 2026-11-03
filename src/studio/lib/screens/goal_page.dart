import 'package:flutter/material.dart';

/// 目标页：一个 OKR 一张卡片，O 与 KR 明确标注。
///
/// v0.1.x 内置内容（与 profile qtcloud / qtclass「目标」一致）；服务端目标 API
/// 落地后改由仓储注入。进度由挂载任务的真实状态计算，不在本页写死。
class GoalPage extends StatelessWidget {
  const GoalPage({super.key});

  /// OKR 列表（一个 OKR 一张卡片），内容与 profile 各业务「目标」一致
  static const List<(String objective, List<String> keyResults)> okrs = [
    (
      '量潮云成长为主营业务',
      [
        '媒体云：原型变生产可用上线，获取第一个付费客户',
        '执行云：原型变生产可用上线，获取第一个付费客户',
      ],
    ),
    (
      '人才培养体系收支平衡',
      ['量潮课堂产品为实训基地提供服务'],
    ),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (objective, keyResults) in okrs)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _tag(context, 'O'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            objective,
                            key: const ValueKey('objective'),
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final kr in keyResults)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tag(context, 'KR'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                kr,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// O / KR 标签：小色块，层级一眼可辨。
  Widget _tag(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
