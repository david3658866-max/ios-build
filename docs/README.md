# im-flutter 文档包（开发前必读）

本目录是 im-uniapp → im-flutter 改造的完整开发依据。**开发任何模块前，先读对应文档。**

## 项目背景

将 `im-uniapp`（uni-app + Vue3 + Pinia 的 IM App）改造为 Flutter 双端 App。

- **平台**：Android + iOS（不做 H5/小程序）
- **范围**：仅 IM（不做金融 service/loan/iou、投诉 complaint、离线推送 unipush）
- **音视频**：InAppWebView 复用 `im-uniapp/hybrid/html/rtc-private | rtc-group`
- **技术栈**：Riverpod + drift(SQLite) + Hive + Dio + web_socket_channel
- **后端**：复用现有 `im-server`(Netty WS) + `im-platform`(REST)，协议不变

## 测试环境

- 线路：`kivola.de010.com`（主线路，API `/api`，WS `wss://kivola.de010.com/im`）
- H5 旧 App（抓包对照用）：`https://novali.de010.com`
- 测试账号：`13444444444` / `15222222222`，密码均 `123456`

## 五份文档导航

| # | 文档 | 内容 | 何时读 |
|---|---|---|---|
| ① | [migration-reference.md](./migration-reference.md) | 接口清单、WS cmd→动作、数据模型、功能走查表（**事实依据**，基于后端源码定稿） | 写任何接口/模型/消息逻辑前 |
| ② | [architecture.md](./architecture.md) | 技术栈、分层、目录、Riverpod、drift 表、6 大核心模块设计 | 动手前了解全局 |
| ③ | [development-plan.md](./development-plan.md) | 里程碑 M0–M5、排期、交付物、验收标准、风险 | 了解节奏与验收 |
| ④ | [task-breakdown.md](./task-breakdown.md) | 任务卡、并行批次、文件所有权（**防冲突**） | 派发/认领任务时 |
| ⑤ | [coding-conventions.md](./coding-conventions.md) | 命名、状态管理、网络、存储、日志、git、并行红线 | 写代码全程遵守 |

## 推进流程

```
M0 地基(单线,定契约) → 用户验证WS
  → M1 登录(单线) → 用户验证登录
    → M2 会话+文字MVP(单线核心) → 用户双跑对照
      → M3 功能(多agent并行) + M4 音视频(独立)
        → M5 App能力+收口 → 用户回归 → 灰度
```

## 并行开发防冲突三原则

1. **契约先行**：M0 冻结 models/api/stores 签名、drift 表、enums，并行期不私改。
2. **文件所有权**：每个 agent 只改自己任务卡的独占文件，批次内文件不相交。
3. **热点串行**：`chat_box_page` / `message_dispatcher` / `app_router` / `app_database` 不并行同改。

## 质量保障

抓包黄金参照 → 回放单测 → 旧/新双跑对照 → 走查表逐项验收 → 小步快跑（M2 先验收）。

### 验收清单索引

| 文档 | 粒度 | 用途 |
|------|------|------|
| [parity-checklists-index.md](./parity-checklists-index.md) | **总索引** | 各模块细项清单入口 + 收口顺序 |
| [m3-device-checklist.md](./m3-device-checklist.md) | 模块级（10 章） | 真机双跑粗勾 |
| [chat-box-parity-checklist.md](./chat-box-parity-checklist.md) | chat-box 细项（A–L） | 聊天页开发收口 |
| [messages-tab-parity-checklist.md](./messages-tab-parity-checklist.md) | 消息 Tab（A–I） | 会话列表 / chat-item |
| [friend-parity-checklist.md](./friend-parity-checklist.md) | 通讯录（A–K） | 好友 Tab + 子页 |
| [group-parity-checklist.md](./group-parity-checklist.md) | 群组（A–I） | 群列表 / 资料 / 设置 |
| [mine-parity-checklist.md](./mine-parity-checklist.md) | 我的（A–I） | 个人中心 + 设置 |
| [auth-parity-checklist.md](./auth-parity-checklist.md) | 登录注册（A–F） | 登录 / 注册 / 找回 |
| [shell-parity-checklist.md](./shell-parity-checklist.md) | 主壳（A–G） | TabBar / 启动 / 线路 |
| [chat-aux-parity-checklist.md](./chat-aux-parity-checklist.md) | 聊天辅助（A–J） | 系统通知 / 记录 / 扫码 / RTC |
| [app-capability-parity-checklist.md](./app-capability-parity-checklist.md) | App 能力（A–I） | WS / 角标 / 采集 / 权限 |
| [parity-tracker.md](./parity-tracker.md) | 里程碑进度 | 阶段状态 |
