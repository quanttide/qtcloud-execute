# ROADMAP

与领域规格 v0.2.0 对齐，跟随 provider 破坏性重构：废除客户端生成 id 与 upsert 写法，字段与取值以规格为准。

1. 写入语义迁移：新建任务改走 `POST`（id 取 201 响应体，废除本地 uuid 生成），编辑改走 `PUT` 全量更新，处理 404。
2. 领域字段呈现：任务卡与详情面板补负责人 / 复核人（owner_id / reviewer_id），状态取值对齐规格 `created / in_progress / reviewing / done`。
3. Outcome 承载评审：评审者在系统内记录交付结果（标题 / 描述 / 关联任务），评审者愿意填、有人回看，Outcome 才成立。
4. 移动端适配：看板四列恒宽偏向桌面，按真实使用场景决定投入。
