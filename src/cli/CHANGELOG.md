# Changelog

本文件仅记录 **cli（量潮执行云 CLI，Rust，纯服务端客户端）** 的版本变更。studio / provider 各自维护自己的 CHANGELOG。

## [0.1.0] - 2026-09-03

- cli：v0.1.0 正式发布（自 `0.1.0-alpha.6` 转正，无代码变更），crates.io 同步发 0.1.0

## [0.1.0] - 2026-09-03

### 首个正式版

自 alpha.1 以来的完整能力（0.1.0-alpha.6 为最后一个预发布版）：

- 纯服务端客户端：`lists` / `tasks` / `add`（含 `--status`） / `update` / `delete`
- `--json` 输出（AI 友好）；API 基地址：`--server` > `QTCLOUD_EXECUTE_API_BASE_URL` > 默认系统级网关
- crates.io 发布 + 多平台二进制（release-cli）

## [0.1.0-alpha.6] - 2026-09-03

- cli：新增 `delete <list_id> <task_id>` 命令（对接 provider DELETE 端点，不可撤销）

## [0.1.0-alpha.5] - 2026-09-03

- cli：`add` 新增 `--status` 参数（新建时直接指定状态，默认 notStarted）——不再需要 add 后再 update 两跳

## [0.1.0-alpha.4] - 2026-09-03

- cli：移除 `--category` 参数（add/update）与 `Task.category` 字段，tasks 列表不再显示分类列（provider/studio 三层同步移除）

## [0.1.0-alpha.3] - 2026-08-23

- ci(cli)：release-cli 对齐 qtcloud-devops 惯例——`check`（validate-version/validate-changelog 脚本）+ `build-binaries`（多平台矩阵）+ `publish-crate`（crates.io）；保留 GitHub Release 二进制发布（`attach-release`，按目标名区分）
- ci(cli)：契约补齐 `stages`/`platform` 与 cli 的 `framework`/`registry`(crates)/`release.changelog`/`test_threshold`
- 验证：`validate-version.sh`/`validate-changelog.sh` 本地通过（版本匹配/不匹配均正确）

## [0.1.0-alpha.2] - 2026-08-23

- ci(cli)：`release-cli` 工作流增加 crates.io 发布（`cargo publish`，需 secret `CRATES_API_TOKEN`）
- cli：Cargo 元数据补齐（description/license/repository/authors/readme），`version` 对齐 `0.1.0-alpha.2`；contract 登记 `cli` scope `registry: crates`
- 验证：`cargo publish --dry-run` 通过（crates.io 接受该 crate）

## [0.1.0-alpha.1] - 2026-08-23

- cli：改为纯服务端客户端（`--server` / 环境变量 `QTCLOUD_EXECUTE_API_BASE_URL`），对接 provider HTTP API，不再读写本地文件
- cli：新增 `--json` 输出（直接透传服务端响应），供 AI/脚本解析
- cli：API 基地址统一为 `QTCLOUD_EXECUTE_API_BASE_URL`，默认系统级网关 `https://api.quanttide.com/qtcloud-execute`（对齐 studio/delib 规范）
- ci(cli)：新增 `release-cli` 工作流（`cli/*` tag → cargo build → 挂载二进制到 GitHub Release），并登记 `cli` scope
- ci(cli)：`release-cli` 增加 crates.io 发布（`cargo publish`，需 secret `CRATES_API_TOKEN`）；Cargo 元数据补齐（description/license/repository），版本对齐 `0.1.0-alpha.1`
