# ROADMAP

与领域规格 v0.2.0 对齐，破坏性重构：当前实现（客户端生成 id、PUT upsert、Task 五字段、状态取值自造）系统性偏离规格，推倒对齐，不带包袱演进。

1. 方法语义破坏性迁移：创建改 `POST`（id 由服务端生成 uuid，响应 201 携带实体），`PUT` 只做全量更新（资源不存在返回 404，废除 upsert），废除客户端生成 id（含 `<清单id>-<unix秒>` 形态）。
2. Task 字段对齐规格：补 owner_id / reviewer_id（→ Executor.id）、is_active、created_at / updated_at（started_at / due_at / completed_at 可选）；状态取值对齐规格 `created / in_progress / reviewing / done`；存量数据迁移。
3. Executor 模型与端点：`GET` / `POST` / `PUT` / `DELETE /executors`，id 服务端生成，暂不绑定账户系统。
4. Outcome 模型与端点：id / list_id（必选）/ task_ids / title / description，嵌套 `/lists/{listId}/outcomes` 四端点，Task.outcome_ids 对称回填，数据独立文件。
5. List 端点补全：`POST /lists`、`PUT /lists/{listId}`、`DELETE /lists/{listId}`（名下无任务与结果方可删，校验引用返回 409，不级联）。
6. 渠道记录：等转化链路真实发生并进入规格后再实现，服务端只存不算。
