# uniapp → Flutter 细项对照清单（总索引）

> **用途**：按模块逐项打勾，避免「大块做了、细节漏了」。粒度与 [chat-box-parity-checklist.md](./chat-box-parity-checklist.md) 一致。  
> **对照源**：`im-uniapp/pages/**`、`im-uniapp/components/**`、`docs/design-tokens-*.md`、`docs/migration-reference.md`  
> **粗勾入口**：[m3-device-checklist.md](./m3-device-checklist.md)（真机双跑 10 章）

## 状态图例

| 标记 | 含义 |
|------|------|
| ✅ | 已对齐（代码可追溯；关键项有单测或契约测） |
| 🟡 | 部分对齐（能跑但缺细节 / 与老项目行为不一致） |
| ⬜ | 未实现 |
| 🔧 | 代码有，需真机双跑确认 |
| ⏭ | 已知占位或范围外（金融 service/loan、投诉 complaint、离线推送等） |
| ➕ | Flutter 有意增强（超 uniapp，可选保留或收回） |

**最后核对**：2026-07-02 · `flutter test` 257/257

---

## 清单一览

| 模块 | 文档 | uniapp 对照 | Flutter 主路径 | 检查点约 |
|------|------|-------------|----------------|----------|
| 聊天页 | [chat-box-parity-checklist.md](./chat-box-parity-checklist.md) | `chat-box.vue` | `pages/chat/chat_box_page.dart` | 70+ |
| 消息 Tab | [messages-tab-parity-checklist.md](./messages-tab-parity-checklist.md) | `chat.vue` + `chat-item` | `tabs/messages_tab.dart` | 45+ |
| 通讯录/好友 | [friend-parity-checklist.md](./friend-parity-checklist.md) | `friend.vue` + 子页 | `tabs/contacts_tab.dart` + `pages/friend/*` | 55+ |
| 群组 | [group-parity-checklist.md](./group-parity-checklist.md) | `group*.vue` | `pages/group/*` | 50+ |
| 我的/设置 | [mine-parity-checklist.md](./mine-parity-checklist.md) | `mine.vue` + 子页 | `tabs/mine_tab.dart` + `pages/mine/*` | 45+ |
| 登录/注册 | [auth-parity-checklist.md](./auth-parity-checklist.md) | `login/register/reset-pwd` | `pages/login/*` | 35+ |
| 主壳/TabBar | [shell-parity-checklist.md](./shell-parity-checklist.md) | `pages.json` tabBar | `main_shell.dart` + `im_tab_bar.dart` | 25+ |
| 聊天辅助 | [chat-aux-parity-checklist.md](./chat-aux-parity-checklist.md) | system/history/scan/rtc | `pages/chat/*` + `scan/*` | 40+ |
| App 能力 | [app-capability-parity-checklist.md](./app-capability-parity-checklist.md) | WS/角标/采集等 | `services/*` + `core/ws/*` | 30+ |

---

## 推荐收口顺序（P0 → P1）

1. **消息 Tab + chat-box**（用户主路径，已有 chat-box 细项，先补 messages-tab 标 🟡/⬜）
2. **通讯录 + 好友子页**（索引、申请流、资料页）
3. **群组**（群资料格、禁言/移除、建群权限）
4. **我的 + 设置**（头部卡、绑定、青少年模式）
5. **登录/壳层**（线路、Tab 角标、启动恢复）
6. **聊天辅助 + App 能力**（RTC 双机、系统通知、数据采集）

---

## 自动化测试索引

| 模块 | 测试文件 |
|------|----------|
| **功能总表** | `tool/feature_registry.dart` + `test/feature_coverage_test.dart` |
| **验收报告** | `dart run tool/generate_acceptance_report.dart` → `acceptance-matrix.md` / `human-only-acceptance.md` |
| 消息 Tab | `test/m3_messages_tab_test.dart`、`test/m3_page_smoke_test.dart` |
| chat-box | `test/m3_chat_contract_test.dart`（含虚拟窗口契约） |
| 时间格式 | `test/date_util_test.dart` |
| 好友 | `test/m3_friend_test.dart` |
| 登录/注册 | `test/m3_auth_mine_test.dart`（含 AuthFormUtil、PolicyConsentUtil、AuthLoginModeUtil） |
| 发送队列 | `test/message_send_util_test.dart` |
| 我的 | `test/m3_mine_util_test.dart`、`test/m3_auth_mine_test.dart` |
| 群组 | `test/m3_group_permission_test.dart`、`test/m3_group_leave_test.dart`、`test/m3_page_smoke_test.dart` |
| 主壳/TabBar | `test/m3_shell_ui_test.dart`（Toast/Loading/确认框/NavBar）、`test/line_switch_test.dart` |
| 冒烟 | `test/m3_page_smoke_test.dart` |

细项清单 **不替代** 真机双跑；标 ✅ 的项仍建议在 [m3-device-checklist.md](./m3-device-checklist.md) 勾 Flutter 列。

---

## 范围外（整模块 ⏭，不写细项）

- `pages/service/**`、`pages/loan/**`（金融）
- `pages/complaint/**`（投诉）
- `mine-real-name*`（uniapp 菜单已隐藏）
- uniapp H5 专属扫码插件（Flutter 用 `mobile_scanner`）
