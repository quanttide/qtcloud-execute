# CLI 参考（qtcloud-execute）

量潮执行云命令行客户端 `qtcloud-execute`，云端任务管理入口，主要供 AI 与脚本调用。纯服务端客户端：只通过 HTTP 对接 provider API（见 [provider.md](provider.md)），不读写本地文件。

本文是完整命令契约（面向集成者）；上手用法与常用流程见 [用户指南](../user-guide/cli.md)。

用法：`qtcloud-execute [全局选项] <子命令> [参数]`。

## 全局选项

- `--server <地址>`——API 基地址覆盖；默认 `https://api.quanttide.com/qtcloud-execute`
- `--json`——JSON 输出，透传服务端响应（AI 友好）
- `-h` / `--help`——帮助
- `-V` / `--version`——版本号

基地址解析优先级：`--server` > 环境变量 `QTCLOUD_EXECUTE_API_BASE_URL` > 默认系统级网关。地址末尾斜杠会被去除。

执行失败（校验不通过、网络错误、HTTP 非 2xx）时向 stderr 输出 `错误: …` 并以退出码 1 结束；HTTP 错误显示为 `HTTP <code>: <响应体>`。

## 枚举取值

- 状态（`--status`）：`notStarted`、`inProgress`、`reviewing`、`done`
- 优先级（`--priority`）：`urgent`、`high`、`medium`、`low`

枚举在客户端校验，非法取值直接报错退出，不发起请求。

## lists

列出全部任务清单及各自任务数。对应 `GET /api/lists`。

```bash
qtcloud-execute lists [--json]
```

人类可读输出示例：

```
── 任务清单 ──  http://localhost:8080
  qtdata       量潮数据  (2 个任务)
  qtclass      量潮课堂  (0 个任务)
```

`--json` 输出服务端原样响应 `{ "lists": [...] }`。

## tasks

列出某清单的任务，可按状态过滤。对应 `GET /api/lists/{id}/tasks`。

```bash
qtcloud-execute tasks <清单ID> [--status <状态>] [--json]
```

位置参数：`<清单ID>`。

`--status` 过滤在客户端进行（先拉全量再过滤）。`--json` 输出 `{ "tasks": [...] }`。

人类可读输出示例（标题/状态/优先级 + 下一行任务 ID 与描述）：

```
── qtdata ──  http://localhost:8080/api/lists/qtdata/tasks
  客户项目复现                                 inProgress  high
      qtdata-reproduction  数据契约/蓝图/spec 已完成，数据清洗中
```

## add

新增任务，任务 ID 由 CLI 自动生成（`<清单ID>-<unix秒>`，冲突时自增），通过 PUT upsert 写入。对应 `PUT /api/lists/{id}/tasks/{taskId}`。

```bash
qtcloud-execute add <清单ID> <标题> [--status <状态>] [--priority <优先级>] [--description <描述>] [--json]
```

选项默认值：`--status` 为 `notStarted`，`--priority` 为 `medium`。

人类可读输出：`✓ 已新增任务 <任务ID> → <标题> (<状态>/<优先级>) @ <基地址>`。`--json` 输出服务端响应 `{ "task": Task }`。

## update

按任务 ID 更新字段，未提供的字段保持原值（先 GET 合并再 PUT 全量）。对应 `PUT /api/lists/{id}/tasks/{taskId}`。

```bash
qtcloud-execute update <清单ID> <任务ID> [--status <状态>] [--priority <优先级>] [--description <描述>] [--json]
```

位置参数：`<清单ID>`、`<任务ID>`。

`--status`/`--priority`/`--description` 至少提供一项，否则报错退出。任务不存在时报错 `任务不存在: <任务ID>（清单 <清单ID>）`。

人类可读输出：`✓ 已更新任务 <任务ID>：<标题> @ <基地址>`。`--json` 输出服务端响应 `{ "task": Task }`。

## delete

删除任务，不可撤销。对应 `DELETE /api/lists/{id}/tasks/{taskId}`。

```bash
qtcloud-execute delete <清单ID> <任务ID> [--json]
```

位置参数：`<清单ID>`、`<任务ID>`。

人类可读输出：`✓ 已删除任务 <任务ID> @ <基地址>`。`--json` 输出服务端响应 `{ "deleted": "<任务ID>" }`。

## 对端 API

各子命令与 provider 端点的对应关系见 [provider.md](provider.md)。
