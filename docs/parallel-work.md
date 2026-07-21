# 多 Agent 并行分工

## 主 agent（M2 主线 — 独占热点）

| 任务 | 状态 |
|------|------|
| M2-5a 离线会话摘要 + WS | ✅ |
| M2-3 会话列表 | ✅ |
| M2-5b 进会话补离线 | 🟡 pullChatOffline 已实现 |
| M2-4 chat-box 文字 MVP | 🟡 私聊发送/气泡/路由 |

**热点（side 禁止改）**：`chat_store`, `message_dispatcher`, `offline_sync`, `auth_controller`, `app_database` schema

## 第二批 Side（✅ 全部完成）

| ID | 任务 | 交付 |
|----|------|------|
| D | chat-box 设计 token | `docs/design-tokens-chat-box.md` |
| E | ImColors + chat/friend 用 token | `im_colors.dart`, `chat_item`, `friend_item` |
| F | friend_store + contacts 接 API | `friend_store.dart`, `contacts_tab.dart` |

## 第一批 Side（✅）

| A 测试 | B 通讯录 UI | C chat token + mine |

## 当前阶段：M3 D1 并行

| Agent | 任务 | 独占目录 | 状态 |
|-------|------|----------|------|
| D1-A | 好友：添加/申请/详情/备注 | `lib/pages/friend/` `friend_store` `widgets/friend/` | 🟡 进行中 |
| D1-C | 我的：资料/改密/账号安全/关于 | `lib/pages/mine/` | 🟡 进行中 |
| 主 agent | 路由 + Tab 入口对接 | `app_router` `contacts_tab` `mine_tab` | 待合并 |

**热点（side 禁止改）**：`chat_store`, `message_dispatcher`, `offline_sync`, `auth_controller`, `app_database` schema

- 发消息后端 500 暂缓，不阻塞 M3
- M2 自动化 ✅ 33/33
