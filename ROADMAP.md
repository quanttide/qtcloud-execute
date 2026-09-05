# ROADMAP

与领域规格 v0.2.0 对齐：0.2 让验收成为一等公民（Outcome）。当前实现与规格存在系统性偏差（客户端生成 id、PUT upsert、Task 五字段、无 Executor/Outcome），先破坏性重构对齐，再谈演进。

1. 规格对齐（破坏性）：id 由服务端生成（uuid），方法语义改为 POST 创建（201 携带实体）/ PUT 全量更新（不存在 404）/ DELETE；Task 字段对齐规格（owner_id/reviewer_id、status 取值、is_active、时间戳）；provider、cli、studio 三端同步一次到位。
2. Outcome 承载评审：按规格实现 Outcome（list_id 必选、task_ids 多对多、嵌套清单下的四端点），先支撑课题评审场景。评审者愿意在系统内记录验收结论且有人回看，Outcome 才成立。
3. AI 提炼管道：日志/素材 → 任务草稿 → 人确认，真实使用后按验证标准决定。
4. 获客归因：转化链路真实发生并进入规格后，再实现渠道记录，排在评审之后。
5. 移动端适配：按真实使用场景决定投入。
