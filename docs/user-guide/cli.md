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

## 清单

清单用来隔离不同类别的事情。量潮科技有量潮数据、量潮课堂、量潮云三个主营业务，对应 `qtdata`、`qtclass`、`qtcloud` 三个清单。

## 任务

任务属于某个清单，用标题、描述、优先级、状态四个部分描述：

- 标题：用动名词写，比如「升级量潮执行云客户端」。
- 描述：说明要做什么、怎么验收。
- 优先级：决定先处理哪件——紧急、高、中、低，默认中。
- 状态：说明推进到哪一步——未开始、执行中、评审中、已完成，默认未开始。

命令行里优先级写作 `urgent` / `high` / `medium` / `low`，状态写作 `notStarted` / `inProgress` / `reviewing` / `done`。

新增任务（`add`）时四个部分都能设置；已建任务只能改描述、优先级、状态（`update`），**标题不支持修改**——要改标题只能删除后重建。

## 常用操作

- 看有哪些清单、各有多少任务：`qtcloud-execute lists`
- 看某清单的任务，只看某个状态：`qtcloud-execute tasks qtcloud --status inProgress`
- 有新事就记下来：`qtcloud-execute add qtcloud '升级量潮执行云客户端' --priority high`
- 做完一件就推进：`qtcloud-execute update qtcloud <任务ID> --status reviewing`
- 不要了的删掉：`qtcloud-execute delete qtcloud <任务ID>`（不可撤销）
