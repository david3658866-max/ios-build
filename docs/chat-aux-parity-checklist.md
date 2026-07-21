# 聊天辅助页 细项对照清单（uniapp → Flutter）

> **对照源**：`chat-system.vue`、`chat-system-content.vue`、`chat-history*.vue`、`chat-private-video.vue`、`chat-group-video.vue`、`scan` 相关、`common/external-link.vue`  
> **Flutter 主文件**：`lib/pages/chat/chat_system*.dart`、`chat_history*.dart`、`rtc_*.dart`、`chat_video_page.dart`、`lib/pages/scan/scan_page.dart`

**最后核对**：2026-07-01

---

## A. 系统消息列表（chat-system.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | NavBar「系统通知」 | title | `ChatSystemPage` | ✅ | |
| A2 | 消息列表标题+时间 | list item | ListTile | ✅ | |
| A3 | 未读/已读样式 | read flag | 🔧 | |
| A4 | 点击进入详情 | chat-system-content | `chatSystemContent` | ✅ | |
| A5 | 与 chatStore 系统会话联动 | SYSTEM type | 同 | ✅ | |

---

## B. 系统消息详情（chat-system-content.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | 富文本/链接内容展示 | web-view/html | `ChatSystemContentPage` | 🔧 | |
| B2 | 外链跳转 external-link | navigate | `ExternalLinkPage` | ✅ | |
| B3 | 标记已读 | read API | 同 | 🔧 | |

---

## C. 聊天记录（chat-history.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | 从群资料/私聊更多进入 | group-info | route from chat | ✅ | |
| C2 | 关键词搜索 | search input | `ChatHistoryPage` | ✅ | |
| C3 | 结果列表点击定位 chat-box | locateId | `chatPath?locateId` | ✅ | |
| C4 | 图片子页入口 | chat-history-image | `chatHistoryImage` | ✅ | |
| C5 | 文件子页入口 | chat-history-file | `chatHistoryFile` | ✅ | |
| C6 | 分页加载 | scroll load | 🔧 | |

---

## D. 历史图片（chat-history-image.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | 网格展示图片 | grid | `ChatHistoryImagePage` | ✅ | |
| D2 | 点击预览大图 | preview | photo view | 🔧 | |
| D3 | 按会话过滤 | chatId | 同 | ✅ | |

---

## E. 历史文件（chat-history-file.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | 文件列表名+大小+时间 | list | `ChatHistoryFilePage` | ✅ | |
| E2 | 点击下载/打开 | download | url_launcher / 下载 | 🔧 | |
| E3 | 空列表提示 | empty | 同 | ✅ | |

---

## F. 扫一扫

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| F1 | 从消息 Tab + 菜单进入 | SCAN | `ScanPage` | ✅ | |
| F2 | 相机权限 | APP-PLUS | `permission_handler` | 🔧 | |
| F3 | 解析用户二维码加好友 | onScanOk | 跳 friendAdd keyword | 🔧 | |
| F4 | 解析群二维码加群 | join group | group join API | 🔧 | |
| F5 | 解析扫码登录 qr | qr login | `qrLoginConfirm` | 🔧 | |
| F6 | 无效码 toast | onScanFail | 错误提示 | 🔧 | |
| F7 | H5 扫码插件 | cshaptx4869 | ⏭ | Flutter 原生 scanner |

---

## G. 单聊音视频（chat-private-video.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| G1 | InAppWebView 加载 hybrid/rtc-private | web-view | `RtcPrivatePage` | ✅ | |
| G2 | 传入 token/userId/好友 id | query | WebView URL 参数 | 🔧 | 双机 |
| G3 | 发起语音呼叫 | RTC signal | WS + WebView | 🔧 | M4 |
| G4 | 发起视频呼叫 | 同 | 同 | 🔧 | |
| G5 | 接听/拒绝/挂断 | RTC 信令 | 同 | 🔧 | |
| G6 | 挂断后通话记录消息 | MESSAGE_TYPE | dispatcher | 🔧 | |
| G7 | 悬浮窗/后台 | plus | ⬜ | 复杂能力 |

---

## H. 群聊音视频（chat-group-video.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| H1 | WebView rtc-group | hybrid | `RtcGroupPage` | ✅ | |
| H2 | 邀请成员入会 | invite | 🔧 | 双机 |
| H3 | 多人画面布局 | WebView 内 | 同 | 🔧 | |
| H4 | 与 chat-box 群通话入口一致 | toolbar | chat-box 清单 | 🔧 | |

---

## I. 视频消息全屏播放

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| I1 | 点击视频气泡全屏 | player page | `ChatVideoPage` | ✅ | |
| I2 | 下载/缓存播放 | 同 | video_player | 🔧 | |

---

## J. 外链页（external-link.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| J1 | NavBar + WebView | web-view | `ExternalLinkPage` | ✅ | |
| J2 | 标题随网页 | setTitle | 🔧 | |

---

## 收口建议

1. **F2–F6** 扫码全链路真机（加好友/加群/登录）
2. **G/H** RTC 双机回归（M4 里程碑）
3. **C6、E2** 历史搜索分页与文件打开
