# Changelog

> 本文件为 `site` scope（React+Vite 介绍页）的版本记录。发布使用
> `qtcloud-devops release --version site/vX.Y.Z --changelog src/site/CHANGELOG.md`，
> 推送 `site/*` tag 会触发 `.github/workflows/deploy-site.yml`（构建 → 上传 OSS → 刷新 CDN）。

## [0.1.0-alpha.2] - 2026-08-23

### Added

- 介绍页增加通向 studio 的入口：hero 主 CTA「进入执行云」+ footer「进入工作台」
  （跳转 `https://studio.execute.cloud.quanttide.com`）

## [0.1.0-alpha.1] - 2026-08-23

### Added

- React+Vite 介绍页上线：看清 / 推进 / 提炼三步 + 同理心文案
- 部署链路 `site/*` tag → `deploy-site.yml` → `qtcloud-execute-site` 桶 → CDN `execute.cloud.quanttide.com`
- site 基础设施（OSS 桶 + CDN）纳入 `manifests/terraform` 管理
