# ROADMAP

v0.1.x：增加目标功能。

## 云端同步（2026-11-03 盘点）

现状：云端 provider 跑的是 09-03 构建（路由 `/api/*`）；源码 09-06 已去前缀（breaking，未部署）。两边互不认识——源码版 studio 调 `/lists` 打生产 404，云上旧版 studio 调 `/api/lists` 正常。云上 studio 站与介绍页仍是 09-03 版本；今天的侧边栏、目标页只在本机。

待办（顺序即依赖）：

1. 打 `provider/**` 标签部署去前缀版本，源码与云端对齐
2. 打 `studio/**` 标签发布侧边栏与目标页

待评审：

- `apps/qtcloud-execute/src/provider/docs/outcome.md`
- `docs/specification/matters/outcome.md`

（路径相对 quanttide-execute 领域根）
