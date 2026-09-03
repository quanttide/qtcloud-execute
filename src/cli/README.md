# qtcloud-execute CLI

量潮执行云 **云端任务管理** 命令行客户端 —— 已部署 provider（FC）的辅助入口，主要供 **AI/脚本** 调用。

纯服务端客户端：只通过 HTTP 对接已部署的 provider API，**不读写本地文件**。

## 服务端地址

默认指向 **系统级 API 网关** `https://api.quanttide.com/qtcloud-execute`（与 studio/delib 约定一致）。可覆盖：

```bash
# 环境变量（推荐，一次配置）
export QTCLOUD_EXECUTE_API_BASE_URL=https://api.quanttide.com/qtcloud-execute
qtcloud-execute lists

# 或每次显式指定 --server（优先级最高）
qtcloud-execute --server https://api.quanttide.com/qtcloud-execute lists
```

优先级：`--server` > `QTCLOUD_EXECUTE_API_BASE_URL` > 默认网关。

## 子命令

| 命令 | 说明 |
|------|------|
| `lists` | 列出全部任务清单（`GET /api/lists`） |
| `tasks <list_id> [--status <s>]` | 列出某清单任务，可按状态过滤（`GET /api/lists/{id}/tasks`） |
| `add <list_id> <title> [--description] [--priority] [--status]` | 新增任务（ID 由 CLI 生成，`PUT` upsert） |
| `update <list_id> <task_id> [--status] [--priority] [--description]` | 更新任务（先 GET 合并再 `PUT` 全量） |
| `delete <list_id> <task_id>` | 删除任务（不可撤销） |

枚举：
- 状态：`notStarted` / `inProgress` / `reviewing` / `done`
- 优先级：`urgent` / `high` / `medium` / `low`

## JSON 输出（AI 友好）

所有子命令加 `--json` 即输出服务端原样 JSON（便于程序解析）：

```bash
qtcloud-execute lists --json
qtcloud-execute tasks qtdata --status inProgress --json
qtcloud-execute update qtdata qtdata-project-closeout --status reviewing --json
```

## 示例

```bash
# 看板概览
qtcloud-execute lists

# 看某清单在做的任务
qtcloud-execute tasks qtdata --status inProgress --json

# 一键推进任务（AI 常做的操作）
qtcloud-execute update qtdata qtdata-project-closeout --status reviewing
```

## 构建

```bash
cd src/cli
cargo build --release          # 产物 target/release/qtcloud-execute
```
