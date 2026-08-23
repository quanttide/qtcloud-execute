# Task 模型设计（models/task.dart）

## 定位

执行云的最小领域单元——一个事项（事件风暴收敛：Task + TaskList 两个聚合）。

## 模型定义

```
Task
├── id（唯一标识）
├── title（标题——一句话概括）
├── description（描述——展开细节）
├── status（未开始 / 进行中 / 评审中 / 已完成）
└── priority（紧急 / 高 / 中 / 低——AI 建议 + 人确认）
```

## 枚举

```
TaskStatus
├── notStarted  未开始
├── inProgress  进行中
├── reviewing   评审中
└── done        已完成

TaskPriority
├── urgent  紧急
├── high    高
├── medium  中
└── low     低
```

## 状态流转（只前进）

```
未开始 → 进行中 → 评审中 → 已完成
```

- 状态只前进不后退（进行中可回未开始？——待确认：按量潮惯例只前进）
- blocked 不设独立状态（卡点记在 description，或后续需要再加）

## 优先级规则

- AI 建议 + 人确认（AI 不直接改——判断不是事实）
- 四档枚举，不扩展（简单优先）

## 序列化

- JSON 序列化/反序列化（toJson/fromJson，全字段）
- 存本地文件（seed/运行时数据）

## 测试（models/task_test.dart）

- JSON 往返无损（全字段）
- 状态流转合法（未开始→进行中→评审中→已完成；非法回退拒绝）
- 优先级默认值（medium？——待定：默认中）

## 验收

- 四字段齐全，枚举明确
- JSON 往返无损
- 状态只前进
