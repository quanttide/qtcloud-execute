# 清单切换器组件（TaskListSwitcher）设计

> 对应：doc/screens/task_list_screen.md（顶部清单切换）
> 依赖：TaskListCubit（lists + currentListId）

## 定位

顶部清单切换——**数据驱动**（从仓储加载清单列表，不静态假设业务数量）。

## 组件结构

```
┌───────────────────────────────────────────┐
│ [qtdata] [qtclass] [qtcloud]      [+] 新增  │  ← 动态列表，当前高亮
└───────────────────────────────────────────┘
```

## 展示规则

| 元素 | 规则 |
|------|------|
| 清单项 | 从 TaskListCubit.lists 遍历渲染（动态） |
| 当前清单 | 高亮（选中态） |
| 新增入口 | "+"——新建清单（业务扩展） |
| 形态 | 移动端：水平滑动条 / 抽屉；桌面：左侧清单列表——不锁定 |

## 交互行为

- 点击清单项 → switchList(id) → 看板跟随（单向数据流）
- 新增清单 → 列表刷新（新清单自动出现）
- 切换无副作用（不丢数据）

## 数据

| 项 | 说明 |
|----|------|
| 来源 | TaskListCubit（lists + currentListId） |
| 操作 | switchList(id) / createList(name) |

## 测试（widgets/task_list_switcher_test.dart）

- 动态渲染（新增清单自动出现）
- 当前清单高亮
- 点击切换回调正确

## 验收

- 清单列表数据驱动（不静态假设）
- 切换即看板跟随
