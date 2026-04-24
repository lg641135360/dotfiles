# Awesome Autostart Consolidation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改变当前已验证平台差异行为的前提下，收口 Awesome 三个平台 autostart 脚本的公共逻辑，减少重复与漂移。

**Architecture:** 新增 `autostart/common.sh` 承载公共 helper 与稳定公共启动项，三个平台脚本只保留平台特有的 PATH、显示器/触摸板、壁纸、Snipaste/greenclip/flameshot 等差异行为，并在末尾调用公共入口。先用 shell 回归测试锁定结构，再做保守抽取。

**Tech Stack:** shell 脚本、轻量 shell 回归测试。

---

### 本轮范围
- 新增 `.config/linux/awesome/autostart/common.sh`
- 收口 `run()` 与公共启动项
- 保留各平台脚本中的平台特有逻辑不变
- 新增 autostart 结构回归测试
