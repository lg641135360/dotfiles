# scripts/

TypeScript 工具目录。与 `.config/scripts/`（POSIX shell 桌面辅助脚本）不同，本目录收录需要 Node.js 运行时的仓库级工具。

## 工具

### archive_trace.ts

将 `logs/trace.md` 中超过保留数量的旧条目按月归档到 `logs/trace-archive/`。

归档单位是「一条变更摘要」（trace.md 中的一条记录），而非 `## YYYY-MM-DD` 日期标题：单日往往会产生多个变更摘要，按日期计数会让单日多变更的情况无法被归档。

支持两种 trace.md 格式：
1. `## YYYY-MM-DD` 裸日期 + 一个或多个 `### 子条目标题` 子条目
2. `## YYYY-MM-DD — 变更标题` 日期带标题，日期下直接是正文（视为单条子条目）

## 依赖

- Node.js
- [tsx](https://github.com/privatenumber/tsx)（通过 `npm install` 自动安装到 `scripts/node_modules/`）

## 用法

```shell
# 安装依赖（首次或 package.json 变更后）
npm --prefix scripts install

# 预览归档（不写文件）
npm --prefix scripts run archive-trace -- --dry-run

# 实际执行归档（默认保留最近 5 条子条目）
npm --prefix scripts run archive-trace

# 自定义保留数量
npm --prefix scripts run archive-trace -- --keep 10

# 类型检查（不产出文件）
npm --prefix scripts run typecheck
```

## 与 `.config/scripts/` 的区别

| 目录 | 语言 | 运行时 | 用途 |
|------|------|--------|------|
| `scripts/` | TypeScript | Node.js + tsx | 仓库级工具（trace 归档等） |
| `.config/scripts/` | POSIX shell | 系统_shell | 桌面辅助脚本（锁屏、启动器、壁纸等），由 `install.sh` 部署到 `~/.config/scripts/` |
