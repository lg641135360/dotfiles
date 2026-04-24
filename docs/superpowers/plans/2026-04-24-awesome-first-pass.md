# Awesome First Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改变当前 Awesome 已验证行为的前提下，完成第一轮结构收口：tasklist markup 安全、actions 统一、prompt 依赖解耦、wibar 组件职责回收。

**Architecture:** 让 `ui/wibar.lua` 完整拥有顶部栏组件与 per-screen 生命周期，`bindings.lua` 只消费显式注入的 actions / prompt runner，不再直接依赖 screen 上的隐式字段。为本轮结构调整先补轻量 shell 回归测试，锁定目标结构与关键行为。

**Tech Stack:** AwesomeWM Lua、shell 回归测试、luajit 语法检查。

---

### 本轮范围
- `ui/wibar.lua`：接管 clock / lock / systray / sysinfo 创建，修 tasklist 标题 escape
- `bindings.lua`：改为消费注入的 action 与 prompt runner
- `rc.lua`：只做总装配
- 新增 `actions.lua`：统一 lock / rofi / screenshot / file manager 动作
- `tests/`：新增结构回归测试
