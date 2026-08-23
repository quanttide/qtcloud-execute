# AGENTS.md — QtCloud Execute 仓库约定

> 供 Agent/协作者查阅的仓库操作约定。以 CI 与社区脚本为准。

## 项目结构

- `src/studio/` — qtcloud_execute_studio（Flutter 应用，studio 看板）
- `src/provider/` — qtcloud-execute provider（Go 服务端，FC 3.0 部署）
- `src/cli/` — qtcloud-execute CLI（Rust，纯服务端客户端，AI 辅助入口）
- `.github/workflows/` — CI（`test-studio.yml`、`deploy-studio.yml`、`deploy-provider.yml`、`release-cli.yml`）

## 分 scope 的 CHANGELOG

每个 scope 维护**自己的** CHANGELOG 与版本号序列（互不冲突）：

| scope | CHANGELOG | 示例版本 |
|-------|-----------|----------|
| `studio` | `src/studio/CHANGELOG.md` | `studio/v0.1.0-beta.4` |
| `provider` | `src/provider/CHANGELOG.md` | `provider/v0.1.0-alpha.2` |
| `cli` | `src/cli/CHANGELOG.md` | `cli/v0.1.0-alpha.1` |

根 `CHANGELOG.md` 仅作**索引**（总览），不承载版本条目。

## Studio 测试与构建

```bash
cd src/studio
flutter analyze                      # 静态分析（需零问题）
flutter test                         # 单元/组件/widget 测试（当前 97 全绿）
flutter build web --release          # 发布产物验证
```

## 发布流程（qtcloud-devops release）

发布由 **`qtcloud-devops release`** 完成：创建 Git 标签并推送 + 创建 GitHub Release。
推送 `studio/*` tag 会触发 `deploy-studio.yml`（构建 web → 上传 OSS → 刷新 CDN）。

前置：

```bash
cd /home/iguo/repos/quanttide/domains/quanttide-execute/apps/qtcloud-execute
```

版本号使用 `studio/vX.Y.Z` 前缀（确保 `deploy-studio.yml` 的 `studio/*` tag 触发）。

### 1. 准备（保持仓库干净）

- 更新 `src/studio/pubspec.yaml` 的 `version:` 为 `X.Y.Z`（不含 v）
- 更新 `src/studio/CHANGELOG.md`：新增 `## [X.Y.Z] - YYYY-MM-DD` 条目
- 更新 `ROADMAP.md`（如涉及方向/范围变化）
- 提交三段式 commit：
  - `feat(studio): ...`（代码 + 测试）
  - `docs: 版本 X.Y.Z——... 发布条目`（CHANGELOG/ROADMAP）
  - `chore: bump studio version to X.Y.Z`（pubspec.yaml）
- git 工作区干净（qtcloud-devops 预检查要求）
- 根 `CHANGELOG.md` 为索引，无需改动

### 2. 发布

```bash
# 发布时用 scope 对应的 CHANGELOG（多个 scope 版本号互不冲突）
qtcloud-devops release --version studio/vX.Y.Z --changelog src/studio/CHANGELOG.md
```

- 预检查：版本格式 / `## [X.Y.Z]` 记录（在 `--changelog` 指定文件内）/ 工作区干净 / 在 main/master/release/* 分支
- 若本地已存在同名 tag，跳过创建（仅推送 + GitHub Release）
- 生成 GitHub Release（notes 取自 `--changelog` 文件内 `## [X.Y.Z]` 段）
- `--dry-run`：仅检查；`--yes`：跳过确认

### 3. 验证

- `gh release view studio/vX.Y.Z --repo quanttide/qtcloud-execute` 确认 Release 存在
- 确认 `deploy-studio.yml` 因 tag push 已触发构建部署
