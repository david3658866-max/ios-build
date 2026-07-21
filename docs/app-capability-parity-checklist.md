# App 能力 细项对照清单（uniapp → Flutter）

> **对照源**：`im-uniapp/App.vue`、`common/wssocket.js`、`store/chatStore.js`、数据采集相关、`permission.js`  
> **Flutter 主文件**：`lib/core/ws/*`、`lib/services/badge_service.dart`、`lib/services/data_collect/*`、`lib/stores/*`

**最后核对**：2026-07-01

---

## A. WebSocket 连接

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | 登录后连接 WS | connect after login | `ws_client` connect | ✅ | |
| A2 | URL `wss://{host}/im` | env | line config | ✅ | |
| A3 | 心跳保活 | heartbeat | ping/pong | ✅ | |
| A4 | 断线自动重连 | reconnect | reconnect policy | ✅ | |
| A5 | 切前台重连 onShow | App onShow | lifecycle observer | 🔧 | |
| A6 | 网络恢复重连 | network change | connectivity_plus | 🔧 | |
| A7 | 连接状态 UI（消息 Tab 条） | statusMessage | `messagesTabStatusMessage` | ✅ | |

---

## B. WS 消息分发（cmd）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | 私聊消息 cmd3 | handler | `message_dispatcher` | ✅ | |
| B2 | 群聊消息 cmd4 | handler | 同 | ✅ | |
| B3 | 消息回执 cmd5 | receipt | 同 | ✅ | |
| B4 | 好友申请 cmd6 | friend request | 同 | ✅ | |
| B5 | 已读 cmd7 | readed | 同 | ✅ | |
| B6 | 撤回 cmd8 | recall | 同 | ✅ | |
| B7 | 踢下线 cmd2 | force logout | 同 | 🔧 | 双机 |
| B8 | 系统消息 cmd9 | system | 同 | ✅ | |
| B9 | 数据采集 cmd55/56 | data collect | `data_collect_handler` | 🔧 | Android |
| B10 | RTC 信令 cmd | RTC | WebView bridge | 🔧 | |

> 完整 cmd 表见 [migration-reference.md](./migration-reference.md)

---

## C. 本地存储与离线

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | 会话列表持久化 | local storage | drift `chats` | ✅ | |
| C2 | 消息持久化 | chat messages | drift messages | ✅ | |
| C3 | 进会话拉离线 `/message/private|group` | pull offline | chat_store pull | ✅ | |
| C4 | 发送失败重试队列 | resend + reqQueue | `MessageSendQueue` + failed 态 + `MessageResendUtil` | ✅ | `message_send_util_test`；媒体旁侧重发为增强 |
| C5 | Hive KV token/配置 | uni.storage | Hive kv | ✅ | |

---

## D. 角标

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | Tab 消息未读 | tab badge | `badge_service` | ✅ | |
| D2 | Tab 好友申请 | friend recv | 同 | ✅ | |
| D3 | Android 桌面角标 | plus shortcut | `app_badge_plus` | 🔧 | 厂商差异 |
| D4 | iOS 桌面角标 | 同 | 同 | 🔧 | |
| D5 | 免打扰会话不计入或未推送 | isDnd | 角标逻辑 | 🔧 | 对照免打扰规则 |

---

## E. 提示音与震动

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | 新消息提示音开关 | audioTip user flag | userStore.isAudioTip | ✅ | |
| E2 | 播放 tip 音频 | innerAudioContext | `shouldPlayMessageTipSound` + `audioplayers` | ✅ | 🔧 真机前台收到消息播放 |
| E3 | 免打扰不响 | isDnd | 同 | 🔧 | |
| E4 | 后台推送响铃 | unipush | ⏭ | 范围外不做 unipush |

---

## F. 数据采集（Android）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| F1 | 服务端 cmd55 触发采集 | handler | `data_collect_handler` | 🔧 | |
| F2 | 通讯录上传 | contacts | flutter_contacts | 🔧 | 权限 |
| F3 | 通话记录上传 | call_log | call_log package | 🔧 | |
| F4 | 相册/图片上传 | photos | photo_manager | 🔧 | |
| F5 | 设置页开关（注释态） | mine-setting | ⏭ | uniapp 亦注释 |

---

## G. 设备与权限

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| G1 | 相册读写 | chooseImage | image_picker | ✅ | |
| G2 | 相机（扫码/拍照） | camera | permission_handler | 🔧 | |
| G3 | 麦克风（语音/RTC） | record | record package | 🔧 | |
| G4 | 通讯录读 | contacts | flutter_contacts | ✅ | |
| G5 | 文件读写 | file | path_provider | ✅ | |
| G6 | 定位（若发位置消息） | location | geolocator | 🔧 | chat-box 位置 |

---

## H. 应用生命周期

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| H1 | onLaunch 初始化 store | App.vue | bootstrap after login | ✅ | |
| H2 | onShow 刷新线路/角标 | 各 tab | tab + lifecycle | ✅ | |
| H3 | 后台暂停 WS（若有） | 策略 | 🔧 | 对照是否保持连接 |
| H4 | 清缓存/重装后数据 | 重装空 | drift 重建 | ✅ | |

---

## I. 日志与调试

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| I1 | 请求日志 | console | `app_logger` | ✅ | |
| I2 | WS 帧日志 | debug | 同 | ✅ | release 应关 |
| I3 | 埋点/统计 | 若有 | ⬜ | 非 IM 核心 |

---

## 收口建议

1. **D3–D5、E2–E3** 真机角标与提示音
2. **B7** 异地登录双机
3. **F1–F4** 数据采集权限与 cmd55/56（若业务需要）
4. **A5–A6** 弱网/切后台重连场景
