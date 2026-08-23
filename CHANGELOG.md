# Changelog

## [0.1.0-alpha.2] - 2026-08-23

- fix(provider)：运行时任务数据 OSS 桶更名为 `qtcloud-execute-provider`（原 `qtcloud-execute-data`），并同步 FC 环境变量 `ALIYUN_OSS_BUCKET`
- fix(provider)：修正 OSS 远程 state 未迁移导致的首次 apply 冲突——迁移本地 studio state 到 `quanttide-terraform-state/qtcloud-execute/terraform.tfstate`，收敛 FC 资源入 state
- 验证：`provider/v0.1.0-alpha.1` 部署成功（build 58s + Terraform apply 33s 绿），FC 端点 `/health`、`/api/lists` 正常

## [0.1.0-alpha.1] - 2026-08-23

- provider：新增 `src/provider/Dockerfile`（多阶段静态构建 + alpine 运行）+ `docker-compose.yml`（本地一键起，挂载 `data/tasks.json`）
- provider：IaC 追加 FC 3.0 部署（`manifests/terraform/fc.tf`）——runtime `custom-container` 容器 + 运行时 OSS 数据桶 `qtcloud-execute-provider`；`main.tf` 切换到 OSS 远程 state（`quanttide-terraform-state`）
- provider：新增 `.github/workflows/deploy-provider.yml`（`provider/*` tag → 构建镜像推 ACR → Terraform apply 到 FC）；`.quanttide/devops/contract.yaml` 增加 `provider` scope
- 验证：`terraform validate` 通过、`docker build` + 容器运行 `health`/`/api/lists`/404 均正常

## [0.1.0-beta.2] - 2026-08-23

- studio：真看板（方案 A）重构——一次一个清单（项目隔离单元），左侧清单导航栏 + 状态列泳道看板
- studio：类别过滤器（全部 + 各业务类别，Task.category 作次级视角，与清单切换分离）
- studio：列头「+」新增卡（TaskCreateDialog），卡片显示优先级标签与投影
- studio：Task.advanceTo（只前进）→ moveTo（自由来回），任务可跨列推进/回退
- studio：移除已完成列默认折叠，WIP 上限徽章，看板列恒展开
- studio：文案 "分类"→"类别"，导航栏标题 "项目"→"清单"

## [0.1.0-beta.1] - 2026-08-23

- studio：二维看板首页（清单切换器 + 分组×状态看板，列=分组、行=状态）
- studio：任务卡片点击弹窗详情（状态四态只前进 / 优先级四档 / 描述编辑，即改即存）
- studio：清单切换数据驱动、已完成行默认折叠、路由简化（详情走弹窗）

## [0.1.0] - 2026-07-12

- 初始化仓库
