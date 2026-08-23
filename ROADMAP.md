# QtCloud Execute ROADMAP

> 更新：2026-08-23
> 依据：src/studio/doc/（models/screens/views/states 全量设计）

## 背景

现有 lib 代码（599 行）基于旧模型（GTD 重模型：name/requirement/goal/roles/phases）——与新领域模型（Task 四字段 + 清单/分组 + 二维看板）不匹配。按设计文档重构。

## 阶段 1：领域层（模型 + 仓储）

- [ ] `models/task.dart` 重写：Task（id/title/description/status/priority）+ 枚举（四态/四档）+ 状态流转
- [ ] `models/task_list.dart`：TaskList（业务清单）+ Group（职能分组）
- [ ] `repositories/task_repository.dart`：仓储（DDD——种子/本地文件，可注入）
- [ ] `assets/data/seed_tasks.json` 重写：新模型种子数据
- [ ] 单测：Task JSON 往返 / 状态流转 / TaskList 分组归属

## 阶段 2：状态层（Bloc）

- [ ] 依赖：flutter_bloc
- [ ] `states/task_list_cubit.dart`：loadLists（动态）/ switchList
- [ ] `states/board_cubit.dart`：loadTasks / updateTask（投影 分组×状态）
- [ ] 单测：Cubit 注入内存仓储（清单切换/看板投影/更新重投影）

## 阶段 3：组件层（views）

- [ ] `views/task_card.dart`：title + priority 色点（状态由行表达）
- [ ] `views/task_detail_dialog.dart`：详情弹窗（状态四态/优先级/描述——回调不持 Cubit）
- [ ] `views/task_list_switcher.dart`：清单切换器（数据驱动）
- [ ] `views/board_view.dart`：二维看板（列=分组 × 行=状态 + 空占位 + 行折叠）
- [ ] widget 测试：各组件（点击/排序/占位/折叠）

## 阶段 4：页面收敛 + 旧代码删除

- [ ] `screens/task_list_screen.dart`：二维看板页面（切换器 + BoardView + 弹窗）
- [ ] 删除旧代码：screens/tasks.dart、screens/task_detail.dart、widgets/task_archive.dart、widgets/task_sections.dart
- [ ] router 简化（仅清单页——详情走弹窗）
- [ ] 集成验证：analyze 零问题 + 全测试绿 + build web

## 验收

- [ ] 二维看板可用：清单切换（动态）→ 分组×状态矩阵 → 卡片点击弹窗操作
- [ ] 状态只前进、优先级四档（AI 建议 + 人确认）
- [ ] 弹窗操作即改即存，看板即时刷新
- [ ] 旧代码全部删除，无残留

## 后续（验证后决定）

- AI 提炼管道（日志/素材 → 任务草稿 → 人确认）——真实使用后按验证标准决定
- 桌面拖拽跨行（状态推进）
