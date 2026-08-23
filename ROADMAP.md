# QtCloud Execute ROADMAP

> 更新：2026-08-23
> 依据：src/studio/doc/（models/screens/views/states 全量设计）+ 方案 A 真看板重构

## 背景

studio 领域模型已从旧 GTD 重模型（name/requirement/goal/roles/phases）迁移到
`Task`（id/title/description/status/priority/category）四字段模型。当前按
**方案 A 真看板**重构：清单（项目）作为隔离单元，状态列泳道看板，
`Task.category` 作类别过滤器，任务可自由来回（非只前进）。

## 已落地（0.1.0-beta.2）

### 领域层（模型 + 仓储）

- [x] `models/task.dart`：Task（id/title/description/status/priority/category）+ 枚举（四态/四档）
- [x] `models/task_list.dart`：TaskList（业务清单——任务直接归属，无分组层级）
- [x] `repositories/task_repository.dart`：仓储（DDD——种子/本地文件，可注入）
- [x] `assets/data/seed_tasks.json` 重写：新模型种子数据
- [x] 单测：Task JSON 往返 / 分类可选 / TaskList 归属 / 仓储读写

### 状态层（Bloc）

- [x] 依赖：flutter_bloc
- [x] `states/task_list_cubit.dart`：loadLists（动态）/ switchList
- [x] `states/board_cubit.dart`：loadTasks / setCategory / updateTask / createTask（分类过滤 + 状态列投影）
- [x] 单测：Cubit 注入内存仓储（清单切换/分类过滤/自由移动/新建）

### 组件层（views）

- [x] `widgets/task_card.dart`：title + 优先级色点 + 优先级标签（状态由列表达）
- [x] `widgets/task_detail_dialog.dart`：详情弹窗（状态/优先级/类别/描述——状态自由来回）
- [x] `widgets/task_list_switcher.dart`：左侧清单导航栏（清单名 + 任务数，当前高亮）
- [x] `widgets/board_view.dart`：真看板（状态列泳道 + 板底 + lane + WIP 徽章 + 列头「+」）
- [x] `widgets/category_filter_bar.dart`：类别过滤器（全部 + 各类别）
- [x] `widgets/task_create_dialog.dart`：新建任务弹窗（列头「+」触发）
- [x] widget 测试：各组件（点击/排序/拖拽/WIP/新建/类别过滤）

### 页面收敛 + 旧代码删除

- [x] `screens/task_list_screen.dart`：分栏布局（左侧清单导航 + 右侧类别过滤器 + 看板）
- [x] 删除旧代码：screens/tasks.dart、screens/task_detail.dart、widgets/task_archive.dart、widgets/task_sections.dart
- [x] router 简化（仅清单页——详情走弹窗）
- [x] 集成验证：analyze 零问题 + 全测试绿（97）+ build web 成功

## 验收（方案 A）

- [x] 清单（项目隔离单元）切换：左侧导航 → 一次一个清单全量任务 → 看板跟随
- [x] 类别过滤器：全部 / 各业务类别，过滤看板（与清单切换分离）
- [x] 状态泳道看板：列 = 状态，卡片投影、WIP 徽章、列头「+」新建
- [x] 任务自由来回（moveTo）：跨列可推进可回退
- [x] 卡片显示优先级标签，操作（弹窗/拖拽）即改即存、看板即时刷新

## 后续（验证后决定）

- AI 提炼管道（日志/素材 → 任务草稿 → 人确认）——真实使用后按验证标准决定
- 移动端适配（当前看板四列恒宽偏向桌面）
