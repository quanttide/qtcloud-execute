# 命令行工具

`qtcloud-execute` 是量潮执行云的命令行客户端，用于云端任务管理。它是纯服务端客户端：只通过 HTTP 对接已部署的 provider 接口，不读写本地文件，主要供 AI 与脚本调用。

## 安装

从 crates.io 安装：

```bash
cargo install qtcloud-execute-cli
```

若 crates.io 上最新版是预发布版本（如 `0.1.0-alpha.x`），默认安装命令不会命中预发布版本，需显式指定：

```bash
cargo install qtcloud-execute-cli --version 0.1.0-alpha.3
```

安装后得到命令 `qtcloud-execute`。也可以从源码构建，产物在 `target/release/qtcloud-execute`。

## 服务端地址

默认连接系统级 API 网关 `https://api.quanttide.com/qtcloud-execute`，可通过两种方式覆盖，优先级从高到低：

1. `--server <地址>`——每次执行时指定；
2. 环境变量 `QTCLOUD_EXECUTE_API_BASE_URL`——一次配置，全局生效。

```bash
export QTCLOUD_EXECUTE_API_BASE_URL=https://api.quanttide.com/qtcloud-execute
qtcloud-execute lists
```

本地联调时把地址指向本地 provider（如 `--server http://localhost:8080`）即可。

## 任务与清单

清单（list）按业务隔离任务，量潮科技目前有 `qtdata`（量潮数据）、`qtclass`（量潮课堂）、`qtcloud`（量潮云）三个清单。任务（task）归属于某个清单，字段为标题、描述、优先级、状态，ID 在清单内唯一。

状态与优先级的取值：

- 状态：`notStarted` 未开始、`inProgress` 执行中、`reviewing` 评审中、`done` 已完成
- 优先级：`urgent` 紧急、`high` 高、`medium` 中、`low` 低

## 命令

### lists

列出全部任务清单及各自任务数。

```bash
qtcloud-execute lists
```

### tasks

列出某清单的任务，可按状态过滤。

```bash
qtcloud-execute tasks <清单ID> [--status <状态>]
```

### add

新增任务，任务 ID 由 CLI 自动生成。默认状态 `notStarted`、默认优先级 `medium`。

```bash
qtcloud-execute add <清单ID> <标题> [--status <状态>] [--priority <优先级>] [--description <描述>]
```

### update

按任务 ID 更新字段，未提供的字段保持原值（先读取再合并）。至少提供一项要更新的字段。

```bash
qtcloud-execute update <清单ID> <任务ID> [--status <状态>] [--priority <优先级>] [--description <描述>]
```

### delete

删除任务。

```bash
qtcloud-execute delete <清单ID> <任务ID>
```

> 删除不可撤销，执行前确认任务 ID。

## JSON 输出

命令加 `--json` 后直接输出服务端原样 JSON，便于程序解析，AI 调用常用：

```bash
qtcloud-execute lists --json
qtcloud-execute tasks qtdata --status inProgress --json
```

## 常用流程

```bash
# 看板概览
qtcloud-execute lists

# 新增一个高优先级任务
qtcloud-execute add qtcloud '升级量潮执行云客户端' --priority high

# 推进任务状态（执行中 → 评审中）
qtcloud-execute update qtcloud <任务ID> --status reviewing

# 查看评审中的任务
qtcloud-execute tasks qtcloud --status reviewing
```
