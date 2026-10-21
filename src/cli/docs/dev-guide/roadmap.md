# ROADMAP

与领域规格 v0.2.0 对齐，跟随 provider 破坏性重构：cli 是 AI/脚本的执行云入口，写入语义与 id 规则以规格为准。

1. 写入语义迁移：废除客户端生成 id（`<清单id>-<unix秒>` 形态），`add` 改走 `POST`（id 取 201 响应体），`update` 改走 `PUT` 全量更新，处理 404。
2. 领域字段跟进：任务输出补 owner_id / reviewer_id / is_active / 时间戳，状态取值对齐规格。
3. Executor 与 Outcome 子命令：执行者维护、结果创建与按清单查询，随 provider 端点落地。
4. AI 提炼管道客户端：日志/素材 → 任务草稿 → 人确认，真实使用后按验证标准决定。
