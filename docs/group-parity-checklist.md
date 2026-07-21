# 群组 细项对照清单（uniapp → Flutter）

> **对照源**：`im-uniapp/pages/group/group.vue`、`group-info.vue`、`group-edit.vue`、`group-member.vue`、`group-invite.vue`、`group-manager.vue`、`group-setting.vue`、`group-qrcode.vue`  
> **Flutter 主文件**：`lib/pages/group/*`、`lib/widgets/group/*`  
> **自动化**：`test/m3_group_permission_test.dart`、`test/m3_group_leave_test.dart`、`test/m3_page_smoke_test.dart`

**最后核对**：2026-07-01

---

## A. 我的群聊列表（group.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | NavBar「群聊」+ 返回 | nav-bar back | `GroupListPage` | ✅ | |
| A2 | 群列表头像+名称+人数 | list item | ListTile + HeadImage | ✅ | |
| A3 | 点击进入群资料 | group-info | `groupInfo` route | ✅ | |
| A4 | 空列表提示 | empty tip | 空态 | 🔧 | |
| A5 | onShow 刷新群 store | reload | `RouteAware` / init load | ✅ | |

---

## B. 创建 / 编辑群（group-edit.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | 建群：选好友多选 | checkbox list | `GroupEditPage` create | ✅ | |
| B2 | 建群：群名称输入 | input | TextField | ✅ | |
| B3 | 建群：群头像上传 | chooseImage | image_picker + upload | 🔧 | |
| B4 | 高级用户才能建群 | 身份校验 | messages_tab 已拦；编辑页二次校验 | ✅ | |
| B5 | 改群：名称/头像/公告 | edit mode | `GroupEditPage` edit | ✅ | |
| B6 | 保存调 API 刷新 groupStore | PUT/POST | 同 | ✅ | |
| B7 | 建群成功进 chat-box | redirect | `chatPath` group | ✅ | |

---

## C. 群资料页（group-info.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | NavBar「群聊信息」 | title | `GroupInfoPage` | ✅ | |
| C2 | 成员宫格前 N 人 | `showMaxIdx` | 网格前若干 | ✅ | |
| C3 | 成员点头像 → 用户资料 | user-info | `userInfo` route | ✅ | |
| C4 | 「邀请」+ 号（有权限） | `isAllowInvite` | 邀请入口 | ✅ | |
| C5 | 「移除」群主/管理员 | owner/manager | 移除入口 | ✅ | |
| C6 | 「禁言」/「取消禁言」 | manager tools | `GroupPermissionUtil` + 选择器 | ✅ | 🔧 真机双跑选人与 API |
| C7 | 查看全部成员 → member 页 | `onShowMoreMmeber` | `groupMember` | ✅ | |
| C8 | 展示群名称/群主/备注群名 | form readonly | 同 | ✅ | |
| C9 | 我在本群昵称 | showNickName | 同 | ✅ | |
| C10 | 群公告区块 | notice text | 同 | ✅ | |
| C11 | 修改群聊资料入口 | group-edit | `groupEdit` | ✅ | |
| C12 | 群二维码入口 | group-qrcode | `groupQrcode` | ✅ | |
| C13 | 消息免打扰 switch | `/group/dnd` | `setDnd` | ✅ | |
| C14 | 置顶聊天 switch | `/group/top` | `setTop` | ✅ | |
| C15 | 查找聊天记录 | chat-history | `chatHistory` route | ✅ | |
| C16 | 清空聊天记录 | cleanMessage（uniapp 菜单已隐藏） | 退群/解散弹窗「清除聊天记录」开关 | ✅ | ⏭ 独立入口同 uniapp 隐藏；`GroupLeaveUtil` |
| C17 | 退出群聊 | quit API | 确认 + quit + 可选清会话 | ✅ | 🔧 `GroupLeaveDeviceChecks.quit` |
| C18 | 解散群聊（群主） | dissolve | 确认 + delete API | ✅ | 🔧 `GroupLeaveDeviceChecks.dissolve` |
| C19 | 已退群：隐藏操作项 | `group.quit` | 条件渲染 | ✅ | |
| C20 | 投诉入口 | complaint | ⏭ | 范围外 |

---

## D. 群成员（group-member.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | 全员列表+搜索 | search bar | `GroupMemberPage` | ✅ | |
| D2 | 群主/管理员标识 | tag | 角色标签 | 🔧 | |
| D3 | 点击成员进资料 | navigate | 同 | ✅ | |
| D4 | 移除模式多选 | remove flow | `GroupMemberSelector` | ✅ | |

---

## E. 邀请成员（group-invite.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | 好友多选列表 | checkbox | `GroupInvitePage` | ✅ | |
| E2 | 确认邀请 API | POST invite | 同 | ✅ | |
| E3 | 邀请成功返回刷新 | navigateBack | pop + reload | ✅ | |

---

## F. 群管理员（group-manager.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| F1 | 管理员列表 | list | `GroupManagerPage` | ✅ | |
| F2 | 添加管理员 | 选成员 | 选择器 | 🔧 | |
| F3 | 取消管理员 | API | 同 | 🔧 | |
| F4 | 仅群主可进 | guard | 权限判断 | ✅ | |

---

## G. 群设置（group-setting.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| G1 | 全员禁言 switch | allMuted | `GroupSettingPage` | ✅ | 🔧 真机开关回显 |
| G2 | 允许成员邀请 switch | allowInvite | 同 | ✅ | 🔧 |
| G3 | 允许分享名片 switch | allowShareCard | 同 | ✅ | 对齐 uniapp 字段名 |
| G4 | 保存调群设置 API | PUT setting | `group_store` | ✅ | 契约测 `GroupSettingApiBody` |

---

## H. 群二维码（group-qrcode.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| H1 | 展示群头像+名称 | card | `GroupQrcodePage` | ✅ | |
| H2 | 二维码图片 | uqrcode | `qr_flutter` | ✅ | |
| H3 | 保存到相册 | saveImage | gallery save | 🔧 | |
| H4 | 扫码加群（从 scan 页） | join API | scan 解析 + join | 🔧 | |

---

## I. 与 chat-box 联动

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| I1 | 群标题人数 N | chat-box title | `groupChatNavTitle` | ✅ | 见 chat-box 清单 |
| I2 | 成员 showName / 群主管理员标签 | message item | `ChatSenderNameRow` | ✅ | |
| I3 | @ 列表来自群成员 | at box | chat-box @ | ✅ | |
| I4 | 退群后 send-bar 遮罩 | quit mask | chat-box mask | ✅ | |

---

## 收口建议

1. **C6、G1–G4** 禁言与群设置开关真机双跑
2. **B3、H3** 头像上传与二维码保存
3. **C17–C18** 真机双跑（`GroupLeaveDeviceChecks`）
