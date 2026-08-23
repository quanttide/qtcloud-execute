# Changelog

本文件仅记录 **provider（量潮任务执行服务端，Go + FC 3.0）** 的版本变更。studio / cli 各自维护自己的 CHANGELOG。

## [0.1.0-alpha.2] - 2026-08-23

- fix(provider)：运行时任务数据 OSS 桶更名为 `qtcloud-execute-provider`（原 `qtcloud-execute-data`），并同步 FC 环境变量 `ALIYUN_OSS_BUCKET`
- fix(provider)：修正 OSS 远程 state 未迁移导致的首次 apply 冲突——迁移本地 studio state 到 `quanttide-terraform-state/qtcloud-execute/terraform.tfstate`，收敛 FC 资源入 state
- 验证：`provider/v0.1.0-alpha.1` 部署成功（build 58s + Terraform apply 33s 绿），FC 端点 `/health`、`/api/lists` 正常

## [0.1.0-alpha.1] - 2026-08-23

- provider：新增 `src/provider/Dockerfile`（多阶段静态构建 + alpine 运行）+ `docker-compose.yml`（本地一键起，挂载 `data/tasks.json`）
- provider：IaC 追加 FC 3.0 部署（`manifests/terraform/fc.tf`）——runtime `custom-container` 容器 + 运行时 OSS 数据桶 `qtcloud-execute-provider`；`main.tf` 切换到 OSS 远程 state（`quanttide-terraform-state`）
- provider：新增 `.github/workflows/deploy-provider.yml`（`provider/*` tag → 构建镜像推 ACR → Terraform apply 到 FC）；`.quanttide/devops/contract.yaml` 增加 `provider` scope
- 验证：`terraform validate` 通过、`docker build` + 容器运行 `health`/`/api/lists`/404 均正常
