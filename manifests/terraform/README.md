# qtcloud-execute 基础设施（Terraform）

管理「量潮执行云」的云上基础设施，含两部分：

## 一、静态站（studio + site）

- **studio OSS 桶** `qtcloud-execute-studio`：studio Web 构建产物部署目标（`deploy-studio.yml` 上传路径）
- **studio CDN 域名** `studio.execute.cloud.quanttide.com`：web 加速，回源到上述 OSS 桶
- **site OSS 桶** `qtcloud-execute-site`：site（React+Vite 介绍页）构建产物部署目标（`deploy-site.yml` 上传路径）
- **site CDN 域名** `execute.cloud.quanttide.com`：web 加速，回源到上述 OSS 桶（原 studio 域，按惯例移交 site 承载）

## 二、provider（FC 3.0 容器，任务 API）

- **FC 函数** `qtcloud-execute-prod`：custom-container，承载 `src/provider`（任务清单 API）
- **数据 OSS 桶** `qtcloud-execute-provider`（私有）：provider 运行时读写 `data/tasks.json`
  （`QTCLOUD_EXECUTE_STORE=oss`；见 `fc.tf` 的 `environment_variables`）
- **HTTP 触发器**：`https://<fc-fn>.<region>.fcapp.run`（直连入口，后续可上系统级 API 网关）

## 远程状态（OSS backend）

本配置已切换到 OSS 远程 state（`main.tf` 的 `backend "oss"`），本机与 CI 共用。

### 首次：从本地 state 迁移到远程

本仓库之前使用本地 `terraform.tfstate`（已被 `.gitignore` 忽略）。切换到 OSS backend 后，首次需迁移：

```bash
cd manifests/terraform
export ALICLOUD_ACCESS_KEY_ID=xxx
export ALICLOUD_ACCESS_KEY_SECRET=xxx

terraform init -migrate-state \
  -backend-config="bucket=quanttide-terraform-state" \
  -backend-config="key=qtcloud-execute/terraform.tfstate" \
  -backend-config="region=cn-hangzhou"
terraform plan   # 应显示 No changes（studio 资源仍在 state 中）
```

> 迁移前请先备份本地 `terraform.tfstate`（仓库内已含 `.terraform.lock.hcl`，勿删）。

### 之后（本机/CI）

```bash
terraform init \
  -backend-config="bucket=quanttide-terraform-state" \
  -backend-config="key=qtcloud-execute/terraform.tfstate" \
  -backend-config="region=cn-hangzhou"
export TF_VAR_image=<ACR>/quanttide/qtcloud-execute-provider:latest
export TF_VAR_oss_access_key_id=xxx
export TF_VAR_oss_access_key_secret=xxx
terraform plan
terraform apply
```

> 注：`oss_access_key_id/secret` 会明文落入 tfstate（FC 环境变量注入），生产建议后续改用 FC 密钥管理。

## 发布（provider）

`provider/*` tag（如 `provider/v0.1.0-alpha.1`）推送触发 `.github/workflows/deploy-provider.yml`：
构建 `src/provider` 镜像 → 推 ACR（`quanttide/qtcloud-execute-provider`）→ Terraform apply 到 FC。

前置：ACR 仓库已创建（PUBLIC）、GitHub org secrets 已配置（`ALIYUN_ACCESS_KEY_ID/SECRET`、
`ALIYUN_ACR_USERNAME/PASSWORD/REGISTRY`）、OSS 状态桶 `quanttide-terraform-state` 已存在。

## 前置条件（公共）

| 项 | 说明 |
|----|------|
| DNS | `execute.cloud.quanttide.com` 需 CNAME 到 CDN 分配的地址（当前指向 `*.kunlunaq.com`），无需变更 |
| ICP 备案 | 大陆 CDN 节点要求备案；如未备案，将 `cdn_scope` 设为 `overseas` |
| Secrets | GitHub Actions 部署需要仓库配置 `ALIYUN_ACCESS_KEY_ID` / `ALIYUN_ACCESS_KEY_SECRET` |

## 说明

- studio 桶 ACL 为 `public-read`（CDN 回源需要）；provider 数据桶为私有
- studio 桶/CDN 命名与 `.github/workflows/deploy-studio.yml` 保持一致；provider 数据桶/FC 与 `.github/workflows/deploy-provider.yml` 保持一致
