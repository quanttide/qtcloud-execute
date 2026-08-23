# Changelog

> 本仓库采用**分 scope 独立版本号**：每个 scope（`cli` / `provider` / `studio`）各自维护一份 CHANGELOG，
> 发布时用 `qtcloud-devops release --version <scope>/vX.Y.Z --changelog <scope 对应文件>`。
> 下面的索引仅作总览，不承载版本条目。

## 各 scope 的 CHANGELOG

| scope      | 目录              | CHANGELOG                | 最近版本 |
|------------|-------------------|--------------------------|----------|
| `studio`   | `src/studio/`     | `src/studio/CHANGELOG.md` | 0.1.0-beta.4 |
| `site`     | `src/site/`       | `src/site/CHANGELOG.md`   | 0.1.0-alpha.3 |
| `provider` | `src/provider/`   | `src/provider/CHANGELOG.md` | 0.1.0-alpha.2 |
| `cli`      | `src/cli/`        | `src/cli/CHANGELOG.md`    | 0.1.0-alpha.1 |

## 发布约定

每个 scope 用**自己的版本号序列**（互不冲突），其历史请见对应文件：

```bash
# 例：发布 CLI
qtcloud-devops release --version cli/v0.1.0-alpha.1 --changelog src/cli/CHANGELOG.md --yes
```

详见 `AGENTS.md`。
