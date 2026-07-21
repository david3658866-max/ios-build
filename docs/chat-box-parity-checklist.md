# chat-box 细项对照清单（uniapp → Flutter）

> **用途**：开发 / 收口 chat-box 时**逐项打勾**，避免「大块功能做了、细节漏了」。  
> **对照源**：`im-uniapp/pages/chat/chat-box.vue`、`components/chat-message-item/chat-message-item.vue`、`components/chat-top-message/`、`docs/design-tokens-chat-box.md`  
> **Flutter 主文件**：`lib/pages/chat/chat_box_page.dart` + `lib/widgets/chat/*`  
> **自动化**：`test/m3_chat_contract_test.dart`（契约，非全覆盖）

## 状态图例

| 标记 | 含义 |
|------|------|
| ✅ | 已对齐（代码可追溯；关键项有单测或契约测） |
| 🟡 | 部分对齐（能跑但缺细节 / 与老项目行为不一致） |
| ⬜ | 未实现 |
| 🔧 | 代码有，需真机双跑确认 |
| ⏭ | 已知占位或范围外 |
| ➕ | Flutter 有意增强（超 uniapp，可选保留或收回） |

**最后核对**：2026-07-01 · `flutter test` 163/164（`line_probe_test` 网络偶发）

---

## A. 页面骨架与导航

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | 全屏：NavBar + 消息区 + send-bar + 面板 | `chat-main-box` | `Scaffold` + `Column` | ✅ | |
| A2 | 消息区背景 `#f6f8fa` | `.chat-msg` | `ImColors.msgAreaBg` | ✅ | |
| A3 | 私聊/在群：标题 + 更多按钮 | `nav-bar more` | `ImNavBar` + `Icons.more_horiz` | ✅ | |
| A4 | 已退群：仅标题+返回，无更多 | `v-else` 无 more | `showNavMore = !quit` | ✅ | `chat_box_page.dart` |
| A5 | 群聊副标题 `companyName` | `:subTitle` | `subTitle: chat?.companyName` | ✅ | |
| A6 | 群标题 `群名(N)`，N=未退群成员数 | `title` 计算属性 | `groupChatNavTitle()` | ✅ | 有单测 |
| A7 | 点击消息区收起键盘/面板 | `@click switchChatTabBox('none')` | `_dismissPanels` | ✅ | |
| A8 | 禁言/退群/封禁遮罩 + 警告图标 | `chat-editer-mask` + icon | `_SendBar` `inputMaskTip` + `ImIcons.warningCircleEmpty` | ✅ | |

---

## B. 消息列表与滚动

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | 进入会话滚到底部 | `onLoad` → `scrollToBottom` | `_scrollToBottom` init | ✅ | |
| B2 | 上拉加载更早历史 | `onScrollToTop` + `preloadStep` 40 | `preloadStep` 40 + DB limit 扩窗 | ✅ | `ChatMessageWindowUtil` |
| B3 | 虚拟窗口 `pageSize` 80 / `showMinIdx` | `showMessages` slice | `sliceMessages` + `maxRenderCount` 220 | ✅ | 契约测 |
| B4 | 非底部显示「回到底部」 | `locate-tip` | `_LocateTip` | ✅ | |
| B5 | 非底部累计「N条新消息」 | `newMessageSize` | `_newMessageSize` | ✅ | |
| B6 | 有人@我浮层（优先于回到底部） | `chat.atMe \|\| atAll` | 同逻辑 | ✅ | |
| B7 | 点击 @我 → 定位 + 清 @ 标记 | `scrollToAtMessage` | `_scrollToAtMessage` + `resetAt` | ✅ | |
| B8 | @ 消息进视口自动清 @ | `refreshAtMessage` | `_refreshAtMessage` | ✅ | |
| B9 | 定位消息 2s 高亮 | `activeMessageIdx` 2s | `_flashMessageHighlight` 2s | ✅ | |
| B10 | 定位时扩展窗口找历史消息 | `locateMessage` 扩 `showMinIdx` | `forLocate` + `locateHistoryFetchStep` 80 | ✅ | |
| B11 | 定位时滚动锁定防干扰 | `lockScrollEvent` | `_lockScrollEvent` 2s + 上拉 50ms | ✅ | 对齐 locate 高亮 |
| B12 | 路由 `locateId` 进会话定位 | 历史子页跳转 | `_pendingLocateId` / `_tryLocateMessage` | ✅ | |

---

## C. 消息行布局（chat-message-item）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | 行 padding 15×20rpx | `.message-normal` | `ChatMessageRow` | ✅ | |
| C2 | 头像 small 84rpx | `HeadImage size=small` | `HeadImage size: 84` | ✅ | |
| C3 | 左右占位 105rpx | padding-left/right | `ChatMessageRow` | ✅ | |
| C4 | 群聊对方：昵称行 | `.top .name` | `ChatSenderNameRow` | ✅ | 本轮已接 |
| C5 | 群主 tag（danger 描边） | `uni-tag 群主` | `GroupSenderRole.owner` | ✅ | |
| C6 | 管理员 tag（primary 描边） | `uni-tag 管理员` | `GroupSenderRole.manager` | ✅ | |
| C7 | 发送者昵称走成员表 `showName` | `showName(msgInfo)` | `_showNameForMessage` | ✅ | 本轮修复 |
| C8 | 点头像 → 用户资料 | `onShowUserInfo` | `_onTapHead` → `friendUserPath` | ✅ | 本轮已接 |
| C9 | 长按头像 → 加入 @ 列表 | `onLongPressHead` | `_onLongPressHead` | ✅ | 本轮已接 |
| C10 | 时间分隔 TIP_TIME | `message-tip` 26rpx | `TextBubble._TimeTip` | ✅ | |

---

## D. 文字与发送状态

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | 文字收发 | `sendTextMessage` | `sendPrivate/GroupText` | ✅ | 🔧 依赖后端 |
| D2 | 气泡左右色/圆角/三角 | scss | `TextBubble` + token | ✅ | |
| D3 | 表情 `[微笑]` gif | `EmotionText` | `emotion_text.dart` | ✅ | |
| D4 | 发送中 loading 40 #656adf | `.sending` | `MessageSendSideIcon` | ✅ | |
| D5 | 失败图标 #e60c0c 50rpx | `.send-fail` | `MessageSendSideIcon` / overlay | ✅ | |
| D6 | 文字/语音：旁侧失败可点重发 | `onResendMessage` 仅 TEXT/AUDIO 旁侧 | 文字/语音旁侧 + 媒体 overlay | ✅ | 媒体遮罩重发为增强；`m3_chat_contract_test` |
| D7 | 私聊己方：已读 #909399 | `.chat-readed` | `MessagePrivateReadLabel` | ✅ | |
| D8 | 私聊己方：未读 #e43d33 | `.chat-unread` | `ImColors.danger` | ✅ | 有单测 |
| D9 | 私聊已读条：各类型消息均显示 | `!groupId` 条件 | 文字/图/音视频/文件/语音 | ✅ | 本轮扩到媒体 |
| D10 | 群聊不显示私聊已读条 | `!groupId` | `showPrivateReadLabel` 判 chatType | ✅ | |

---

## E. 媒体消息

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | 图片：缩略图/尺寸/点击大图 | `.message-image` | `ImageMessageBubble` | ✅ | |
| E2 | 图片：发送中遮罩 loading | image-box loading | `MessageMediaSendingOverlay` | ✅ | |
| E3 | 相册多选最多 9 张 | `maxCount="9"` | `pickMultiImage(limit: 9)` | ✅ | `ChatMediaUtil` 单测 |
| E4 | 图片 ≤10M 校验 | `onUploadImageBefore` | `_pickAndSendImage` | ✅ | |
| E5 | 视频 ≤50M + 封面播放 | `.message-video` | `VideoMessageBubble` + `chat_video_page` | ✅ | |
| E6 | 文件：名/大小/图标 | `.message-file` | `FileMessageBubble` | ✅ | |
| E7 | 文件：发送中「发送中...」 | `upload-status` | 发送中替换 size 文案 | ✅ | 有单测 |
| E8 | 文件：下载进度 % | `download-progress` | `FileMessageBubble` + `FileDownloadUtil` | ✅ | 契约测；🔧 真机打开 |
| E9 | 语音：按住录音 1–60s | `chat-record` | `ChatRecordBar` | ✅ | |
| E10 | 语音：全局单例播放 | `playingAudio` | `ChatAudioPlayback` | ✅ | |
| E11 | 语音气泡 iconfont 样式 | icon-voice-play 等 | `ImIcons.voicePlay` / play / pause | ✅ | `m3_chat_contract_test` |

---

## F. send-bar 与输入

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| F1 | send-bar 白底顶部分割线 | `$im-border` | `ImColors.formDivider` | ✅ | |
| F2 | min-height 80rpx + safe-area | scss | `ConstrainedBox` + padding | ✅ | |
| F3 | 语音/键盘切换 | `icon-voice-circle` / `keyboard` | `ImIcons.voiceCircle` / `keyboard` | ✅ | |
| F4 | 输入区背景 #eef0f5 圆角 20rpx | `.send-text` | `ImColors.pageBg` | ✅ | |
| F5 | 输入框 H5 边框 #e8e8ef | border 1px | `ImColors.inputBorder` | ✅ | |
| F6 | 回执 placeholder `[回执消息]` | editor placeholder | `TextField hintText` | ✅ | |
| F7 | 有内容或 @ 时显示发送按钮 | `btn-send` | `_SendButton` | ✅ | |
| F8 | 无内容时显示 + 打开工具 | `icon-add` | `ImIcons.add` | ✅ | |
| F9 | 获焦关面板滚底 | `onEditorFocus` | `_onInputFocusChange` | ✅ | |
| F10 | 引用预览条 + 清除 | `.quote-message` | `_SendBar` quote 块 | ✅ | |

---

## G. @ 与引用

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| G1 | 群聊 @ 按钮打开选人 | `openAtBox` | `_openAtBox` | ✅ | |
| G2 | @ 预览条横向头像 | `.chat-at-bar` | `_ChatAtBar` | ✅ | |
| G3 | @ 全体成员 id=-1 | `atText @全体成员` | `_atUserIds` 含 -1 | ✅ | |
| G4 | 发送携带 atUserIds | 正文拼接 / API | `sendGroupText` atUserIds | ✅ | |
| G5 | 引用预览 + 发送 quoteMessageId | `quoteMessage` | `_quoteMessage` | ✅ | |
| G6 | 气泡内引用块 | `chat-quote-message` | `ChatQuoteMessage` | ✅ | |
| G7 | 点引用定位原消息 | `onLocateQuoteMessage` | `_locateQuotedMessage` | ✅ | |
| G8 | 长按引用块仅「定位」 | `quoteItems` | `ChatMessageMenuBuilder.forQuote` | ✅ | 有单测 |

---

## H. 长按菜单与操作

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| H1 | 菜单顺序：复制→撤回→引用→转发→置顶→删除→下载 | `menuItems` | `ChatMessageMenuBuilder` | ✅ | 有单测 |
| H8 | 菜单在触点弹出 | `long-press-menu` | `ImLongPressMenu` + `wrapMessageLongPress` | ✅ | 对齐 messages E7 |
| H2 | 复制（文本） | `COPY` | `Clipboard` | ✅ | |
| H3 | 撤回（己发/群管） | `RECALL` | `requestRecall` | ✅ | |
| H4 | 转发多选会话 | `onForwardMessage` | `ChatPickerSheet` + `forwardMessage` | ✅ | 🔧 无 widget 测 |
| H5 | 群置顶消息（菜单 TOP） | `onTopMessage` | `setGroupTopMessage` | ✅ | |
| H6 | 本地删除 | `DELETE` | `deleteMessage` | ✅ | |
| H7 | 文件「下载并打开」 | `onDownloadFile` | `FileDownloadUtil` | ✅ | |

---

## I. 群聊专属

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| I1 | 群置顶条展示/定位/关闭 | `chat-top-message` | `ChatTopMessageBar` | ✅ | |
| I2 | 管理员移除置顶确认 | 弹窗 | `_onCloseTopMessage` | ✅ | |
| I3 | 普通成员关闭仅本地隐藏 | `hideGroupTopMessage` | `hideGroupTopMessage` | ✅ | |
| I4 | 回执开关（工具栏） | `switchReceipt` | `_isReceipt` toggle | ✅ | |
| I5 | 回执工具格选中态背景 | `.active` → `$im-bg-active` | `_ToolItem active: bgActive` | ✅ | 本轮已接 |
| I6 | 群回执「N人已读」/ 绿勾 | `.chat-receipt` | `ChatReceiptBadge` | ✅ | |
| I7 | 回执已确认色 #18bc37 | `icon-ok` success | `ImColors.success` | ✅ | 有单测 |
| I8 | 回执详情已读/未读列表 | `chat-group-readed` | `ChatGroupReceiptSheet` | ✅ | |
| I9 | 发图/视频/文件/语音带 receipt 参数 | `msgInfo.receipt` | `_sendMedia(receipt:)` | ✅ | |

---

## J. 离线、已读与数据

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| J1 | 进会话补离线 | `loadChatOfflineMessages` | `pullChatOffline` | ✅ | |
| J2 | 进会话清未读 + HTTP 已读 | `readedMessage` | `activePrivate/GroupChat` | ✅ | |
| J3 | 会话内收消息保持已读 | 在底部自动已读 | `chatListStream` listen | ✅ | |
| J4 | 时间分隔与 uniapp 一致 | `$date.toTimeText` | `DateUtil.toTimeText` / `formatBubbleTime` | ✅ | `test/date_util_test.dart` |

---

## K. RTC / 名片 / 卡片

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| K1 | 单聊语音/视频通话入口 | `onPriviteVoice/Video` | RTC 路由 + 工具栏 | ✅ | 🔧 双机 |
| K2 | 群聊语音通话邀请 | `onGroupVideo` | `_onGroupVideo` | ✅ | 🔧 双机 |
| K3 | 通话记录气泡 40/41 | `chat-realtime` | `ActRtMessageBubble` | ✅ | |
| K4 | 个人/群名片 | `.message-card` | `CardMessageBubble` | ✅ | |
| K5 | 群名片 7 天过期 | `isExpired` | `CardMessageBubble.isGroupCardExpired` | ✅ | |
| K6 | 合同/借款/产品大卡片 | 大卡片 UI | `FinancialCardBubble` | ✅ | `m3_chat_contract_test`；点击 `ImToast` 占位 |
| K7 | 金融卡片点击跳转业务页 | service 路由 | ⏭ | 范围外 |

---

## L. 已知占位 / 刻意差异

| ID | 项 | 状态 | 说明 |
|----|-----|------|------|
| L1 | 金融卡片点击 | ⏭ | `_onFinancialCardTap` → `ImToast` |
| L2 | 媒体失败旁侧重发（图/视频/文件） | ➕ | uniapp 仅图/视频遮罩；Flutter 加了旁侧+遮罩 |
| L3 | H5 `#ifdef` 分支 | ⏭ | Flutter 不做 H5 |
| L4 | `scrollTop` iOS H5 特殊处理 | ⏭ | App 端不需要 |

---

## 推荐收口顺序（按漏项风险）

1. ~~**P0 功能缺口**：E3 相册 9 张、E8 文件下载进度、F5 输入框边框~~ ✅  
2. ~~**P1 行为对齐**：B2/B3 虚拟窗口与预加载步长、D6 媒体重发~~ ✅  
3. ~~**P2 视觉**：E11 语音 iconfont、K6 金融大卡片样式~~ ✅  
4. **P3 真机**：K1/K2 RTC 全链路  

---

## 使用方式

1. 改 chat-box 前：扫一遍本表，确认本轮动哪些 ID  
2. 改完后：更新对应行「状态 / 备注」  
3. 能写单测的项：补进 `test/m3_chat_contract_test.dart`（菜单、状态色、标题、标签等）  
4. 与 [m3-device-checklist.md](./m3-device-checklist.md) §3 粗项对照：粗项全绿 ≠ 细项全绿  

## 相关自动化

```bash
flutter test test/m3_chat_contract_test.dart   # chat-box 契约（含金融大卡片）
flutter test                                    # 全量门禁
```
