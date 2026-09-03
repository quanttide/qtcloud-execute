# Provider API 参考

量潮执行云 provider（qtcloud-execute-provider）是任务清单服务端，提供基于 JSON 的 REST API。它以数据文件 `tasks.json` 为唯一数据源（local 直读文件 / OSS 两种数据源），写操作即时落盘。

## 基地址

- 本地：`http://localhost:8080`（环境变量 `QTCLOUD_EXECUTE_ADDR` 可覆盖监听地址）
- 生产：`https://api.quanttide.com/qtcloud-execute`（系统级 API 网关转发到 FC，客户端默认地址）

健康检查：`GET /health`，返回 200 `{"status":"ok"}`（text/plain）。

## 数据模型

任务（task）的 JSON 字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 任务 ID，清单内唯一 |
| `title` | string | 标题 |
| `description` | string | 描述；缺省时输出为空字符串 `""` |
| `status` | string | 状态，取值见下 |
| `priority` | string | 优先级，取值见下 |

清单（list）：`{ "id": string, "name": string, "tasks": [Task] }`。顶层结构：`{ "lists": [List] }`。

枚举取值（`tasks.json` 数据契约约定）：

- 状态：`notStarted`、`inProgress`、`reviewing`、`done`
- 优先级：`urgent`、`high`、`medium`、`low`

服务端不校验 `status`/`priority` 取值与必填字段（`id` 一致性除外），原样存储；取值合法性由调用方（CLI、studio）保证。请求体中未知字段被忽略。

## 端点一览

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/lists` | 列出全部清单（含各自任务） |
| GET | `/api/lists/{id}/tasks` | 列出某清单的任务 |
| PUT | `/api/lists/{id}/tasks/{taskId}` | 写入任务（upsert） |
| DELETE | `/api/lists/{id}/tasks/{taskId}` | 删除任务 |

## GET /api/lists

列出全部清单及其任务。

响应 200：

```json
{
  "lists": [
    {
      "id": "qtdata",
      "name": "量潮数据",
      "tasks": [
        {
          "id": "qtdata-reproduction",
          "title": "客户项目复现",
          "description": "",
          "status": "inProgress",
          "priority": "high"
        }
      ]
    }
  ]
}
```

## GET /api/lists/{id}/tasks

路径参数：`id` 清单 ID。

响应 200：`{ "tasks": [Task] }`。

错误：

- 404：清单不存在，响应体 `清单不存在`。

## PUT /api/lists/{id}/tasks/{taskId}

写入任务，**upsert 语义**：清单内已有同 ID 任务则整体替换，否则追加。

路径参数：`id` 清单 ID、`taskId` 任务 ID。

请求体为 Task JSON。`id` 可省略（默认取路径 `taskId`）；若提供则必须与路径一致。

```json
{
  "title": "升级量潮执行云客户端",
  "description": "发布 0.1.0",
  "status": "inProgress",
  "priority": "high"
}
```

响应 200：`{ "task": Task }`。

错误：

- 400：请求体解析失败，或路径 `taskId` 与请求体 `id` 不一致
- 404：清单不存在

## DELETE /api/lists/{id}/tasks/{taskId}

删除任务，不可撤销。

路径参数：`id` 清单 ID、`taskId` 任务 ID。

响应 200：`{ "deleted": "<taskId>" }`。

错误：

- 404：清单或任务不存在（响应体文本区分 `清单不存在` / `任务不存在`）

## 错误约定

- 非 2xx 响应的响应体为**纯文本**（不是 JSON），中文错误消息，如 `清单不存在`、`任务更新失败：…`。
- 状态码：400 请求体/参数错误、404 资源不存在、405 方法不允许、500 服务端错误。
- 未匹配任何路由的请求由 Go 标准库兜底（404/405 纯文本）。
