# 通讯录 / 好友 细项对照清单（uniapp → Flutter）

> **对照源**：`im-uniapp/pages/friend/friend.vue` 及 `friend-*.vue`、`components/friend-item/`  
> **Flutter 主文件**：`lib/pages/main/tabs/contacts_tab.dart`、`lib/pages/friend/*`、`lib/widgets/friend/*`  
> **自动化**：`test/m3_friend_test.dart`、`test/m3_page_smoke_test.dart`

**最后核对**：2026-07-01

---

## A. 通讯录 Tab 骨架

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | NavBar 标题「好友」 | `nav-bar title` | `ImNavBar title: 好友` | ✅ | |
| A2 | 添加好友按钮 | `@add` | `IconButton` → `friendAdd` | ✅ | |
| A3 | 搜索按钮 toggle | `@search` | `showSearch` toggle | ✅ | |
| A4 | 更多按钮 | `@more` | `Icons.more_horiz` | ✅ | |
| A5 | 搜索栏 placeholder | 「点击搜索好友」 | `ImSearchBar` 同文案 | ✅ | |
| A6 | onShow 刷新好友申请角标 | `onShow` | `refreshFriendBadge` | ✅ | |
| A7 | 首次进入自动刷新好友 | `autoRefreshed` | `_autoRefreshed` + load | ✅ | 邀请码默认好友 |

---

## B. 顶部固定入口

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | 「新的朋友」+ 头像图 | `new_friend.png` | `FriendTopItem.newFriend` | ✅ | |
| B2 | 新朋友未读角标 max 99 | `uni-badge recvCount` | `badgeCount: recvCount` | ✅ | |
| B3 | 点击 → friend-request | navigate | `AppRoutes.friendRequest` | ✅ | |
| B4 | 「我的群聊」+ 群图标 | `icon-create-group` | `FriendTopItem.myGroups` | ✅ | |
| B5 | 点击 → group 列表 | `/pages/group/group` | `AppRoutes.groupList` | ✅ | |
| B6 | 顶栏白底/卡片圆角 | scss `.top-item` | `FriendTopItem` 圆角卡 | ✅ | 批 A 已收口 |

---

## C. 好友列表与索引

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | 拼音首字母分组 | `pinyin-pro` | `friend_store` 分组逻辑 | ✅ | |
| C2 | `*` 组显示「在线好友」 | anchor 文案 | 同逻辑 | ✅ | |
| C3 | 字母索引条 | `up-index-list` | `_FriendIndexBar` | ✅ | |
| C4 | 点击索引滚动定位 | index tap | `_scrollToGroup` | ✅ | |
| C5 | 好友行头像+昵称 | `friend-item` | `FriendItem` | ✅ | |
| C6 | 在线绿点 | `online` prop | `HeadImage online` | ✅ | |
| C7 | 搜索过滤好友 | `searchText` | ListView filter | ✅ | |
| C8 | 列表右侧留索引条空间 | padding | `padding right 36rpx` | ✅ | |
| C9 | 无好友空态+添加按钮 | `friend-tip` | `FriendEmptyTip` | ✅ | Widget 已有 |

---

## D. 更多菜单 · 手机通讯录

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | ActionSheet「手机通讯录」 | `showActionSheet` | `ImActionSheet` | ✅ | `m3_friend_test` |
| D2 | 跳转 friend-contact | navigate | `AppRoutes.friendContact` | ✅ | |
| D3 | 每日一次权限引导弹窗 | `checkContactsPermissionGuide` | 未接入 / 已移除死代码 | — | ContactsTab 未挂载；仅手机通讯录页按需申请 |
| D4 | 无权限时引导去设置 | `showPermissionGuide` | `PermissionGuideUtil` + 空态「去设置」 | ✅ | 🔧 真机弹窗与系统设置 |

---

## E. friend-add 添加好友

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | 搜索用户 id / 手机号 | 输入框 | `FriendAddPage` | ✅ | |
| E2 | 搜索结果列表 | 用户卡片 | 同 | ✅ | |
| E3 | 已是好友 toast | toast | toast | ✅ | 批 A |
| E4 | 无效 id toast | toast | toast | ✅ | 批 A |
| E5 | 跳转申请页 friend-apply | navigate | `friendApply` | ✅ | |
| E6 | 扫码加好友入口 | 扫码参数 keyword | route `keyword` | 🔧 | 从 scan 跳转 |

---

## F. friend-request 新的朋友

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| F1 | 收到的申请列表 | API list | `FriendRequestPage` | ✅ | |
| F2 | 同意 / 拒绝 | approve/reject | API + store refresh | ✅ | |
| F3 | 申请状态展示 | 待处理/已同意 | 同 | 🔧 | |
| F4 | 进入后清角标 | badge clear | `refreshFriendBadge` | ✅ | |

---

## G. friend-apply 发送申请

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| G1 | 展示对方资料摘要 | head + name | `FriendApplyPage` | ✅ | |
| G2 | 验证消息输入 | remark | TextField | ✅ | |
| G3 | 发送申请 API | POST apply | `friendApi.apply` | ✅ | |
| G4 | 成功返回/ toast | navigateBack | pop + toast | ✅ | |

---

## H. user-info 用户资料

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| H1 | 头像/昵称/签名/公司 | 资料卡 | `UserInfoPage` | ✅ | |
| H2 | 发消息 → chat-box | navigate | `chatPath` | ✅ | |
| H3 | 加好友（非好友） | apply | apply 流程 | ✅ | |
| H4 | 设置备注 | friend-remark | `friendRemark` | ✅ | |
| H5 | 删除好友 | delete API | 同 | 🔧 | |
| H6 | 投诉入口 | complaint | ⏭ | 范围外 |
| H7 | 从群成员点头像进入 | query userId | route param | ✅ | |

---

## I. friend-remark 备注

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| I1 | 编辑备注名 | input + save | `FriendRemarkPage` | ✅ | |
| I2 | 保存调 API 刷新 store | PUT remark | 同 | ✅ | |

---

## J. friend-contact 手机通讯录

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| J1 | 读取系统通讯录 | plus.contacts | `flutter_contacts` | ✅ | |
| J2 | 匹配已注册手机号 | API batch | 同逻辑 | ✅ | |
| J3 | 未注册「邀请」/ 已注册「添加」 | 行按钮 | 点击行 → friend-add keyword | ✅ | uniapp 按钮文案为「搜索」 |
| J4 | 权限拒绝空态 | 引导文案 + 去设置 | `PermissionGuideUtil` | ✅ | 🔧 真机 |
| J5 | 列表字母索引 | `up-index-list` | `_FriendIndexBar` + 拼音分组 | ✅ | `m3_friend_test` |

---

## K. 已知缺口

| ID | 检查项 | 状态 | 备注 |
|----|--------|------|------|
| K1 | AI 机器人顶栏项 | ⏭ | uniapp 注释/按需 |
| K2 | `test-contacts.vue` 调试页 | ⏭ | 开发用 |
| K3 | NavBar 标题居中 vs 左对齐 | ✅ | `ImNavBar` 默认居中；消息 Tab 左对齐对齐 chat.vue |

---

## 收口建议

1. ~~**D3** 通讯录权限每日引导~~ ✅ 已做（🔧 真机权限弹窗）
2. ~~**C9** 无好友空态~~ ✅
3. ~~**J3** 手机通讯录行按钮~~ ✅（与 uniapp「搜索」一致）
