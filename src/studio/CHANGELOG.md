# CHANGELOG

## [0.1.0-beta.4] - 2026-08-23

### Added

- studio：客户端域名迁至 `studio.execute.cloud.quanttide.com`（原 `execute.cloud.quanttide.com` 移交站点）

## [0.1.0-beta.3] - 2026-08-23

### Added

- 客户端接入服务端 API（`ApiTaskRepository`）：清单/任务经系统级 API 网关 `https://api.quanttide.com/qtcloud-execute` 读取，不再内置种子
- API 基地址经 `--dart-define=QTCLOUD_EXECUTE_API_BASE_URL` 注入（部署流水线 repo 变量，对齐 qtcloud-delib 规范）
- 应用层零 CORS（跨域由系统级网关统一处理，与 qtcloud-delib 一致）

### Removed

- 移除内置种子数据 `assets/data/seed_tasks.json` 与 loader `lib/data/seed_tasks.dart`
- 移除 `LocalFileTaskRepository`（本地文件持久化，`dart:io`）
- 运行数据完全依赖服务端（服务端从 OSS `data/tasks.json` 读取）

## [0.1.0-beta.2] - 2026-08-23

### Added

- 真看板（方案 A）重构：一次一个清单（项目隔离单元），左侧清单导航栏 + 状态列泳道看板
- 左侧清单导航栏（`TaskListSwitcher`）：清单名 + 任务数徽章，当前清单高亮（背景色 + 指示条），「新增清单」入口
- 类别过滤器（`CategoryFilterBar`）：「全部」+ 各业务类别，选中过滤看板（`Task.category` 作"看分组"次级视角，与清单切换分离）
- 列头「+」新增卡（`TaskCreateDialog`）：标题/优先级/类别/描述表单，创建到目标状态列
- 卡片显示优先级标签（文字 + 颜色），不再只靠色点
- 卡片投影（elevation）、板底 + 圆角泳道 lane（真看板形态）

### Changed

- `Task.advanceTo`（只前进）→ `Task.moveTo`（自由来回）：任务可在任意状态列间推进与回退（真看板语义）
- 详情弹窗状态按钮全部可选（无只前进禁用）
- 看板列恒展开，移除"已完成列默认折叠"（完整呈现工作流）
- WIP 上限徽章（进行中/评审中，超限标红提示）
- 页面布局分栏：左侧清单导航（220px）+ 右侧（类别过滤器 + 看板）
- 文案："分类"→"类别"，导航栏标题"项目"→"清单"
- 移除折叠逻辑（`_collapsed` 状态）

### Removed

- 移除"只前进"约束（状态可回退重做）
- 移除已完成列默认折叠

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
