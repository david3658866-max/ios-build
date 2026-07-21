# M2 验收清单（双跑对照）

> **M2 出口标准**：本清单全部通过 + `flutter test` / `flutter analyze lib` 0 error → 方可进入 M3。  
> 测试账号：`15222222222` / `123456` · API：`https://kivola.de010.com/api`

---

## 自动化（CI / 本地）

| # | 项 | 命令 / 文件 | 状态 |
|---|-----|-------------|------|
| A1 | 全量单测 | `flutter test` | ✅ 33/33 |
| A10 | 真机链路冒烟 | `test/m2_live_flow_test.dart` | ✅ 登录/好友/群/摘要 |
| A11 | 会话资料补全 | `test/chat_enrich_test.dart` | ✅ |
| A2 | 静态分析 | `flutter analyze lib` 0 error | ✅ |
| A3 | mergeFromSummary | `test/chat_dao_merge_test.dart` | ✅ |
| A4 | sessionSummary API | `test/session_summary_test.dart` | ✅ |
| A5 | dispatcher 回放 | `test/message_dispatcher_test.dart` | ✅ |
| A6 | 离线跳过已加载 | `test/offline_sync_test.dart` | ✅ |
| A7 | 发送失败路径 | `test/chat_send_test.dart` | ✅ |
| A8 | M2 流程集成 | `test/m2_flow_integration_test.dart` | ✅ |
| A9 | 离线 API 契约 | `test/m2_offline_api_test.dart` | ✅ |

---

## 自动化可替代项（无需双机）

以下已由集成测试覆盖，**不必手工双跑**：

- 登录 / refreshToken / sessionSummary API
- 好友列表、群列表 HTTP 契约
- dispatcher 入库 / 撤回 / 已读 / 去重
- 离线 skip / mergeFromSummary
- enrichFromContacts 补全会话名

## 仍需真机/UI 验收

- 气泡样式、滚动手感、键盘顶起
- WS 实时收发延迟与动画
- 杀进程后会话持久化（drift 文件级）

同一账号、同一后端，两台设备或模拟器 + H5 各跑一遍。

### 1. 私聊文字

| # | 步骤 | 预期 | uniapp | flutter |
|---|------|------|--------|---------|
| B1 | A 给 B 发文字 | B 实时收到，气泡左/右正确 | ⬜ | ⬜ |
| B2 | B 回复 | A 实时收到 | ⬜ | ⬜ |
| B3 | 己方气泡颜色 | `#656adf` 白字 | ⬜ | ⬜ |
| B4 | 对方已读后 | 己方显示「已读」 | ⬜ | ⬜ |

### 2. 群聊文字

| # | 步骤 | 预期 | uniapp | flutter |
|---|------|------|--------|---------|
| C1 | 群内发文字 | 全员实时收到 | ⬜ | ⬜ |
| C2 | 非己方消息 | 显示 sendNickName | ⬜ | ⬜ |
| C3 | 会话列表预览 | 最后一条 + 时间正确 | ⬜ | ⬜ |

### 3. 会话列表

| # | 步骤 | 预期 | uniapp | flutter |
|---|------|------|--------|---------|
| D1 | 收到新消息未进会话 | 未读 +1、置顶排序正常 | ⬜ | ⬜ |
| D2 | 点击进入 chat-box | 未读清零 | ⬜ | ⬜ |
| D3 | 在 chat-box 内收消息 | 未读保持 0（自动已读） | ⬜ | ⬜ |
| D4 | 搜索过滤 | 按 showName 过滤 | ⬜ | ⬜ |

### 4. 离线 / 重启

| # | 步骤 | 预期 | uniapp | flutter |
|---|------|------|--------|---------|
| E1 | 杀进程重启 | 会话列表、最后一条、未读一致 | ⬜ | ⬜ |
| E2 | WS 登录后 sessionSummary | 摘要合并，不丢会话 | ⬜ | ⬜ |
| E3 | 进会话 pullChatOffline | 补拉历史，不重复入库 | ⬜ | ⬜ |
| E4 | messagesLoaded 后会话 | 不再重复拉离线 | ⬜ | ⬜ |

### 5. 发送状态

| # | 步骤 | 预期 | uniapp | flutter |
|---|------|------|--------|---------|
| F1 | 断网发消息 | 失败图标 `#e60c0c` | ⬜ | ⬜ |
| F2 | 恢复网络点重发 | 成功入库 | ⬜ | ⬜ |
| F3 | 上拉历史 | 更早消息加载，位置不跳 | ⬜ | ⬜ |

### 6. 撤回（M2 骨架）

| # | 步骤 | 预期 | uniapp | flutter |
|---|------|------|--------|---------|
| G1 | 对方撤回文字 | 变为「xxx撤回了一条消息」 | ⬜ | ⬜ |

---

## M2 模块对照

| ID | 模块 | 代码状态 | 验收 |
|----|------|----------|------|
| M2-1 | chatStore + DAO | ✅ | A3–A7 |
| M2-2 | MessageDispatcher | ✅ | A5, G1 |
| M2-3 | 会话列表 | ✅ | D1–D4 |
| M2-4 | chat-box 文字 | ✅ | B*, C*, F* |
| M2-5a | 离线摘要 | ✅ | E2 |
| M2-5b | 进会话补离线 | ✅ | E3–E4 |
| M2-6 | 回放测试 | ✅ | A5–A7 |

---

## 收口签字

- [x] 自动化 A1–A9 全部通过
- [ ] 双跑 B–G 关键项与 uniapp 一致
- [ ] `parity-tracker.md` M2 行全部 ✅
- [ ] **批准进入 M3**

---

## 已知 M2 范围外（留 M3+）

- 图片 / 文件 / 语音 / 视频气泡
- 引用、@、表情、长按菜单
- 好友 drift 持久化、群详情页
- sender 独立头像（群聊暂用会话头像）
- RTC 音视频
