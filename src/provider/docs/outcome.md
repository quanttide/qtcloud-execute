# Outcome 与渠道记录开发计划

> 依据：src/provider/ROADMAP.md 与领域规格（quanttide-specification-of-execution-management）

## 现状

服务端已实现四态任务清单 API（`GET /lists`、`GET /lists/{id}/tasks`、`PUT`/`DELETE` 任务），数据文件 `data/tasks.json` 经 store 抽象（local / OSS）读写。`Task` 结构仅含 id/title/description/status/priority 五字段。

领域规格已定义但服务端未承载的模型：Executor（id/label，人工维护，暂不绑定账户）、Task 的负责人与复核人字段（owner_id/reviewer_id，均引用 Executor）、Outcome（独立模型，经 task_ids 与任务多对多关联）。

规格与代码存在状态取值不一致：代码为 `notStarted/inProgress/reviewing/done`，规格为 `created/in_progress/reviewing/done`。计划执行前需先对齐，避免新字段叠加在分歧之上。

## 阶段一：对齐与铺垫

1. 状态取值对齐：确定以规格为准或修订规格，代码、数据文件、studio/cli 三端同步，一次变更不改第二次。
2. Executor 模型与 API：`GET /executors`、`PUT /executors/{id}`，数据存独立文件（如 `data/executors.json`）。执行者只有身份与名字，靠人工维护。

## 阶段二：Task 责任字段

1. Task 增加 owner_id / reviewer_id（必选，引用 Executor.id），已存数据迁移时留空由交办人确认。
2. UpdateTask 请求体与响应同步扩展，studio / cli 客户端跟进。

## 阶段三：Outcome 模型与 API

1. Outcome 独立模型：id / task_ids / title / description，数据存独立文件（如 `data/outcomes.json`）。
2. API：`POST /outcomes`（创建并关联任务）、`GET /outcomes`、`GET /tasks/{id}/outcomes`（按任务查结果）。
3. Task 增加 outcome_ids（与 Outcome.task_ids 对称），随 Outcome 创建回填。

## 阶段四：验收结论

1. Outcome 增加验收字段：reviewer_id（复核人）、conclusion（直接采纳 / 采纳但修改 / 退回）、revisions（修改次数）。
2. 复核动作即改即存：验收不是结果之外的环节，是结果的完成态。「采纳但修改」信息量最大，conclusion 必须能表达它。

## 阶段五：渠道记录

1. Task 增加可选字段 source_channel（来源渠道标识），由创建方传入，服务端只存不算。
2. 提成结算的统计与报表不在本服务端范围内，真实发生后再决定归属。

## 验收

每个阶段完成以测试与三端同步为准：repository 单测覆盖新字段往返，handler 测试覆盖新端点，studio / cli 读取不报错。阶段一的状态对齐尤其如此——它是后续所有字段迁移的前置条件。
