# 消息 Tab 细项对照清单（uniapp → Flutter）

> **对照源**：`im-uniapp/pages/chat/chat.vue`、`components/chat-item/chat-item.vue`、`components/drop-down-menu/`、`components/long-press-menu/`  
> **Flutter 主文件**：`lib/pages/main/tabs/messages_tab.dart`、`lib/widgets/chat/chat_item.dart`、`lib/core/utils/chat_list_util.dart`  
> **自动化**：`test/m3_messages_tab_test.dart`、`test/m3_page_smoke_test.dart`

**最后核对**：2026-07-01

---

## A. 页面骨架与导航

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | Tab 页背景 / tab-page 结构 | `.tab-page` | `Scaffold` + `ImColors.pageBg` | ✅ | |
| A2 | NavBar 标题「消息」左对齐 | `title-align="left"` | `titleAlign: TextAlign.left` | ✅ | |
| A3 | 标题旁线路切换器 | `line-switcher` slot | `LineSwitcher` in `titleExtra` | ✅ | |
| A4 | 线路切换面板（侧滑/弹层） | `line-switcher-panel` | `LineSwitcherPanel` 遮罩下拉 | ✅ | `line_switch_test`；🔧 真机手感 |
| A5 | 搜索按钮切换搜索栏 | `@search` toggle | `showSearch` + `ImSearchBar` | ✅ | |
| A6 | 搜索栏 placeholder「搜索」 | uni-search-bar | `ImSearchBar` | ✅ | |
| A7 | 右上角「+」下拉菜单 | `drop-down-menu` | `ImDropDownMenu` anchor 按钮 | ✅ | |
| A8 | onShow 刷新角标与线路 | `onShow` | `_onTabShow` + `Offstage` 检测 | ✅ | |

---

## B. 连接状态与空态

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | WS/初始化状态条 | `chat-status-tip` | `_StatusTip` | ✅ | `messagesTabStatusMessage` |
| B2 | 状态图标 loading / offline | `statusIconClass` | 同逻辑 | ✅ | |
| B3 | 无会话空态文案+图标 | `chat-tip` | `_EmptyChatTip` | ✅ | |
| B4 | 搜索无结果提示 | 过滤为空 | `ImNoDataTip` | ✅ | |
| B5 | 列表 loading 态 | store loading | `_ListLoading` | ✅ | |

---

## C. 会话列表数据与分页

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | 置顶优先排序 | `chatStore` sort | `filterChatsForDisplay` | ✅ | 单测覆盖 |
| C2 | 搜索过滤 showName | `searchText` filter | `chat_list_util` | ✅ | |
| C3 | 首屏 30 条 | `showMaxIdx: 30` | `_showMaxIdx = 30` | ✅ | |
| C4 | 滚到底增量 +30 | `onScrollToBottom` | `_onScroll` extentAfter<200 | ✅ | |
| C5 | 列表数据源 chatStore | Pinia | `chatListStreamProvider` | ✅ | |
| C6 | 切 Tab 刷新未读角标 | badge refresh | `refreshChatBadge` | ✅ | |

---

## D. 下拉菜单（+ 按钮）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | 添加好友 | `ADD_FRIEND` | `AppRoutes.friendAdd` | ✅ | |
| D2 | 创建群聊 | `CREATE_GROUP` | `groupCreate` | ✅ | |
| D3 | 普通用户禁建群 toast | 身份校验 | `userIdentity != 1` toast | ✅ | |
| D4 | 扫一扫 | `SCAN` | `AppRoutes.scan` | ✅ | |
| D5 | 菜单项图标与文案 | iconfont | `ImIcons.*` | ✅ | |

---

## E. 会话长按菜单

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | 删除该聊天 | `DELETE` | bottom sheet + 确认框 | ✅ | |
| E2 | 置顶 / 取消置顶 | `TOP` | `_toggleTop` | ✅ | |
| E3 | 免打扰 / 新消息提醒 | `DND` | `_toggleDnd` | ✅ | |
| E4 | 私聊置顶调 `/friend/top` | HTTP + store | `friendStore.setTop` | ✅ | |
| E5 | 群聊置顶调 `/group/top` | HTTP + store | `groupStore.setTop` | ✅ | |
| E6 | 系统会话仅本地置顶 | else 分支 | `chatStore.setTop` only | ✅ | |
| E7 | 菜单在触点弹出 | `long-press-menu` @ touch | `ImLongPressMenu` + `computeLongPressMenuPosition` | ✅ | `m3_messages_tab_test`；🔧 真机手感 |
| E8 | 滑动时不弹菜单 | `isTouchMove` guard | `Listener` + `shouldOpenChatLongPressMenu` | ✅ | 单测覆盖；🔧 真机手感 |
| E9 | 删除确认文案含会话名 | popup-modal | `showImConfirmDialog` | ✅ | |

---

## F. 进入会话

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| F1 | 私聊/群聊 → chat-box | `chat-box?chatIdx` | `AppRoutes.chatPath` | ✅ | |
| F2 | 系统消息 → chat-system | `chat-system` | `AppRoutes.chatSystem` | ✅ | |
| F3 | 初始化中且无本地数据阻断 | toast 阻断 | `_openChat` 同逻辑 | ✅ | |
| F4 | 初始化中有本地数据可进 | 允许进入 | 同逻辑 | ✅ | |

---

## G. chat-item 行布局

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| G1 | 行高 ~120rpx | `.chat-item` | `SizedBox height 120rpx` | ✅ | |
| G2 | 头像 96rpx + 在线绿点 | `head-image` | `HeadImage size:96` | ✅ | 私聊 online |
| G3 | 会话名 + 公司 @tag | `company-tag-mini` | `@companyName` | ✅ | |
| G4 | 系统会话「官方」红标 | `uni-tag 官方` | 红色 Container | ✅ | |
| G5 | 右侧时间 `toTimeText` | `$date.toTimeText` | `DateUtil.formatSessionTime` | ✅ | |
| G6 | 底部分割线 | border-bottom | hairline `ImColors.border` | ✅ | |
| G7 | 置顶角标 | `icon-top-message` | `_TopCorner` | ✅ | |
| G8 | rich-text 遮罩捕获点击 | `.mask` | `InkWell` onTap | ✅ | |

---

## H. chat-item 摘要行

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| H1 | `[有人@我]` 红色 | `atMe` | `_atText` | ✅ | |
| H2 | `[@全体成员]` | `atAll` | `_atText` | ✅ | |
| H3 | 群聊发送者前缀 `昵称:` | `isShowSendName` + `isNormal` | `shouldShowChatItemSendName` + `lastMsgType` | ✅ | 单测覆盖 |
| H4 | 文字消息表情小图 | `rich-text` + emo | `EmotionText` / `EmotionUtil` | ✅ | |
| H5 | 非文字显示 lastContent 纯文本 | plain text | `Text(chat.lastContent)` | ✅ | |
| H6 | 免打扰图标替代未读 | `icon-dnd` | `Icons.notifications_off` | ✅ | |
| H7 | 未读角标 max 99 | `uni-badge` | `_UnreadBadge` | ✅ | |
| H8 | 末条类型持久化 `lastMsgType` | messages[last].type | `chats.last_msg_type` schema v2 | ✅ | 摘要无 type 时 null 不显示前缀 |

---

## I. 已知缺口 / 增强

| ID | 检查项 | 状态 | 备注 |
|----|--------|------|------|
| I1 | `active` 高亮态（H5 多窗口） | ⏭ | Flutter 无多窗口 |
| I2 | `hasEmittedInitReady` 事件 | ⏭ | uniapp 启动优化，Flutter 用 provider |
| I3 | H5 内嵌扫码组件 | ⏭ | Flutter 独立 `scan_page` |

---

## 收口建议（按优先级）

1. ~~**E7** 触点弹出菜单~~ ✅ 已做（`ImLongPressMenu` + `m3_messages_tab_test`；🔧 真机手感）
2. ~~**H3** `showSendName` 与末条消息类型对齐~~ ✅ 已做（`lastMsgType` + 单测）
3. ~~**E8** 长按滑动防误触~~ ✅ 已做（🔧 真机确认手感）
