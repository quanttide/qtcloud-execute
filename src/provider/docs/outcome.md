# 规格对齐开发计划

> 依据：领域规格 v0.2.0（quanttide-specification-of-execution-management）

## 现状

服务端已实现 `GET /lists`、`GET /lists/{id}/tasks`、`PUT /lists/{id}/tasks/{taskId}`（upsert）、`DELETE` 任务。`Task` 结构仅 id/title/description/status/priority 五字段，id 由客户端生成，状态取值为 `notStarted/inProgress/reviewing/done`——均偏离规格。

## 阶段一：写入语义迁移（破坏性）

1. 创建改 `POST /lists/{listId}/tasks`：服务端生成 uuid，响应 201 携带实体；`PUT` 只更新已存在资源，不存在返回 404，废除 upsert。
2. `DELETE /lists/{listId}`：名下无任务与结果方可删，校验引用返回 409，不级联。

## 阶段二：Task 字段对齐规格

1. 补 owner_id / reviewer_id（必选，→ Executor.id）、is_active（默认 True）、created_at / updated_at（系统生成）、started_at / due_at / completed_at（可选，completed_at 随 status 进入 done 回填）。
2. 状态取值对齐规格 `created / in_progress / reviewing / done`，数据文件与三端同步。
3. 存量数据迁移：owner_id / reviewer_id 无历史的留空，由交办人补录。

## 阶段三：Executor

1. 模型：id（服务端生成）/ label，数据独立文件。
2. 端点：`GET /executors`、`POST /executors`、`PUT /executors/{executorId}`、`DELETE /executors/{executorId}`（未被任务引用方可删）。

## 阶段四：Outcome

1. 模型：id（服务端生成）/ list_id（必选）/ task_ids（可选，多对多）/ title / description，数据独立文件。
2. 端点：`GET` / `POST` / `PUT` / `DELETE /lists/{listId}/outcomes`，Task.outcome_ids 对称回填。
3. 验收结论（reviewer_id / conclusion / reviewed_at）不在本版规格内，待章程约束明确后再演进。

## 验收

每阶段以测试与三端同步为准：repository 单测覆盖字段往返与新语义（201 / 404 / 409），handler 测试覆盖端点，studio / cli 同步迁移后全测试绿。
