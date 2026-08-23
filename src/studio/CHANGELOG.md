# CHANGELOG

## [0.1.0-beta.1] - 2026-08-23

### Added

- 二维看板首页：顶部清单切换器 + 分组×状态看板（列=分组、行=状态，与档案结构同构）
- 清单切换数据驱动（清单动态加载，切换即看板跟随，点击当前清单无副作用）
- 任务卡片点击打开详情弹窗（就地操作，不跳页）：状态四态只前进 / 优先级四档 / 描述编辑，即改即存、看板即时刷新
- 已完成行默认折叠（减少噪声），行头点击展开/收起

### Changed

- 路由简化：仅清单页（详情走弹窗，移除 /tasks/:id）
- 主入口注入仓储（种子/本地文件），MultiBlocProvider 提供 TaskListCubit / BoardCubit，页面只消费不创建
- 桌面拖拽跨行（状态推进）接入 BoardCubit.updateTask（状态只前进）

### Removed

- 删除旧代码：screens/tasks.dart、screens/task_detail.dart、widgets/task_archive.dart、widgets/task_sections.dart

## [0.1.0-alpha.1] - 2026-08-12

### Added

- 任务清单页面：从种子数据加载任务档案，卡片概览任务名、依赖角标与目标
- 任务详情页：按 id 展示完整任务档案（需求、验收标准、角色分工、五阶段）
- 路由化改造（go_router + usePathUrlStrategy）与量潮执行云主题
- CI（deploy-studio / test-studio）与 IaC（OSS 桶 + CDN 域名）配置
