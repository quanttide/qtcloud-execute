# 状态层设计（states/——Bloc）

## 定位

页面状态管理——清单层与看板层的状态划分，单向数据流。技术实现：flutter_bloc（Cubit）。

## Cubit 划分（两个）

```
TaskListCubit（清单层）
├── loadLists()          # 加载清单（动态——不静态假设）
├── switchList(String id) # 切换当前清单
└── state: { lists, currentListId }

BoardCubit（看板层）
├── loadTasks()          # 加载当前清单任务
├── updateTask(Task)     # 弹窗/拖拽操作后更新（状态/优先级/描述）
└── state: { tasks }     # 页面投影为 二维看板（分组×状态）
```

## 数据流

```
TaskListCubit.loadLists → 清单切换器渲染（顶部）
    ↓ switchList(id)
BoardCubit.loadTasks → 看板投影（列=分组 × 行=状态）
    ↓ 卡片点击
TaskDetailDialog 打开（纯组件，不持有 Cubit）
    ↓ 操作（状态/优先级/描述）→ onUpdated 回调
BoardCubit.updateTask → 仓储 update → 看板重新投影
```

## 关键规则

1. **弹窗是纯组件**：不持有 Cubit——操作通过回调交给 BoardCubit（单向数据流）
2. **投影在 Bloc 层**：二维看板（分组×状态矩阵）由 BoardCubit 从任务列表投影——页面只渲染矩阵
3. **清单切换 = 状态切换**：TaskListCubit 管理 currentListId，看板跟随
4. **仓储注入**：Cubit 构造接收 TaskRepository——测试注入内存实现（不碰文件/网络）
5. **不引入额外状态**：弹窗内的临时编辑（未保存）用组件局部 state——不进 Cubit

## 文件布局

```
lib/
├── states/
│   ├── task_list_cubit.dart
│   └── board_cubit.dart
└── repositories/task_repository.dart   # 仓储（Cubit 依赖）
```

## 测试（states/）

- TaskListCubit：loadLists 动态加载、switchList 状态切换
- BoardCubit：loadTasks 投影正确（分组×状态）、updateTask 后重投影
- 注入内存仓储——不碰文件/网络

## 验收

- 清单切换 → 看板跟随（单向数据流）
- 弹窗操作 → 看板即时刷新
- Cubit 测试注入内存仓储全过
