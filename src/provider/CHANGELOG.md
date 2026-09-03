# Changelog

本文件仅记录 **provider（量潮任务执行服务端，Go + FC 3.0）** 的版本变更。studio / cli 各自维护自己的 CHANGELOG。

## [0.1.0] - 2026-09-03

- provider：v0.1.0 正式发布（自 `0.1.0-alpha.4` 转正，无代码变更），GA 版本与 alpha.4 构建一致

## [0.1.0] - 2026-09-03

### 首个正式版

自 alpha.1 以来的完整能力（0.1.0-alpha.4 为最后一个预发布版）：

- 任务清单 API：`GET /api/lists`、`GET /api/lists/{id}/tasks`、`PUT upsert`、`DELETE` 任务
- 数据源抽象（local / OSS）；FC 3.0 容器化部署 + Terraform IaC；数据文件 `data/tasks.json` 存 OSS
- Task 模型：id/title/description/status/priority（Executor/Outcome 等规格字段演进中，见 docs/specification）

## [0.1.0-alpha.4] - 2026-09-03

- provider：新增 `DELETE /api/lists/{id}/tasks/{taskId}` 端点（`Repository.DeleteTask` + handler + 路由），清单/任务不存在返回 404

## [0.1.0-alpha.3] - 2026-09-03

- provider：移除 `Task.Category` 字段（`json:"category,omitempty"`）——API 不再接受/返回分类，存量数据文件中的 `category` 键反序列化时忽略、写回时清除

## [0.1.0-alpha.2] - 2026-08-23

- fix(provider)：运行时任务数据 OSS 桶更名为 `qtcloud-execute-provider`（原 `qtcloud-execute-data`），并同步 FC 环境变量 `ALIYUN_OSS_BUCKET`
- fix(provider)：修正 OSS 远程 state 未迁移导致的首次 apply 冲突——迁移本地 studio state 到 `quanttide-terraform-state/qtcloud-execute/terraform.tfstate`，收敛 FC 资源入 state
- 验证：`provider/v0.1.0-alpha.1` 部署成功（build 58s + Terraform apply 33s 绿），FC 端点 `/health`、`/api/lists` 正常

## [0.1.0-alpha.1] - 2026-08-23

- provider：新增 `src/provider/Dockerfile`（多阶段静态构建 + alpine 运行）+ `docker-compose.yml`（本地一键起，挂载 `data/tasks.json`）
- provider：IaC 追加 FC 3.0 部署（`manifests/terraform/fc.tf`）——runtime `custom-container` 容器 + 运行时 OSS 数据桶 `qtcloud-execute-provider`；`main.tf` 切换到 OSS 远程 state（`quanttide-terraform-state`）
- provider：新增 `.github/workflows/deploy-provider.yml`（`provider/*` tag → 构建镜像推 ACR → Terraform apply 到 FC）；`.quanttide/devops/contract.yaml` 增加 `provider` scope
- 验证：`terraform validate` 通过、`docker build` + 容器运行 `health`/`/api/lists`/404 均正常
