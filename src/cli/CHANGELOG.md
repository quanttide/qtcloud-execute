# Changelog

本文件仅记录 **cli（量潮执行云 CLI，Rust，纯服务端客户端）** 的版本变更。studio / provider 各自维护自己的 CHANGELOG。

## [0.1.0-alpha.1] - 2026-08-23

- cli：改为纯服务端客户端（`--server` / 环境变量 `QTCLOUD_EXECUTE_API_BASE_URL`），对接 provider HTTP API，不再读写本地文件
- cli：新增 `--json` 输出（直接透传服务端响应），供 AI/脚本解析
- cli：API 基地址统一为 `QTCLOUD_EXECUTE_API_BASE_URL`，默认系统级网关 `https://api.quanttide.com/qtcloud-execute`（对齐 studio/delib 规范）
- ci(cli)：新增 `release-cli` 工作流（`cli/*` tag → cargo build → 挂载二进制到 GitHub Release），并登记 `cli` scope
