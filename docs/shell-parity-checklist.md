# 主壳 / TabBar / 启动 细项对照清单（uniapp → Flutter）

> **对照源**：`im-uniapp/pages.json` tabBar、`App.vue` onLaunch/onShow、`pages/chat/chat.vue` 等 tab 页  
> **Flutter 主文件**：`lib/pages/main/main_shell.dart`、`lib/widgets/im_tab_bar.dart`、`lib/pages/splash/splash_page.dart`、`lib/router/app_router.dart`

**最后核对**：2026-07-01

---

## A. TabBar 结构

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | 三 Tab：消息 / 通讯录 / 我的 | pages.json | `MainShell` IndexedStack | ✅ | uniapp 无独立群 Tab |
| A2 | Tab 文案 | text | `ImTabItem.label` | ✅ | |
| A3 | 图标 PNG 普通/选中 | static/tabbar | `assets/tabbar/*` | ✅ | |
| A4 | 选中色 `#3e45d7` | selectedColor | `ImColors.accent` | ✅ | |
| A5 | 背景白 / 顶部分割线 | borderStyle | `ImTabBar` decoration | ✅ | |
| A6 | 切换 Tab 不销毁页面 | vue keep-alive 类 | `IndexedStack` | ✅ | |
| A7 | 默认选中消息 Tab | first tab | `_index = 0` | ✅ | |

---

## B. Tab 角标

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | 消息 Tab 未读总和 | chat unread | `badgeCounts[0]` | ✅ | |
| B2 | 通讯录 Tab 好友申请数 | recvCount | `badgeCounts[1]` | ✅ | |
| B3 | 角标 max 99+ | badge max | 同 | ✅ | |
| B4 | 进入 Shell 刷新角标 | onShow | `refreshAllBadges` init | ✅ | |
| B5 | 切 Tab 刷新 | 各 tab onShow | `_onTabChanged` + tab内 onShow | ✅ | |
| B6 | WS 新消息更新角标 | dispatcher | `bindBadgeAutoRefresh` | ✅ | |

---

## C. 各 Tab NavBar 约定

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | 消息：标题左对齐 + 线路 | chat.vue | `MessagesTab` | ✅ | |
| C2 | 通讯录：标题居中 + add/search/more | friend.vue | `ContactsTab` | ✅ | |
| C3 | 我的：标题居中 | mine.vue | `MineTab` | ✅ | |
| C4 | Tab 页无系统返回键 | 自定义 nav | 各 Tab `ImNavBar` 无 back | ✅ | |
| C5 | 子页统一 showBack | inner pages | `ImNavBar showBack: true` | ✅ | |

---

## D. 启动与路由

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | Splash → 登录或主页 | reLaunch | `splash_page` → go_router | ✅ | |
| D2 | 未登录拦截主 Tab | 路由守卫 | redirect in router | ✅ | |
| D3 | 深链 chat-box 带参数 | uni route | `GoRoute` query | ✅ | |
| D4 | 深链 scan / qr-login | 同 | 同 | ✅ | |
| D5 | RouteAware 子页回退刷新 | onShow | `imRouteObserver` | ✅ | 群资料等 |

---

## E. 全局 UI 基建

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | 页面背景 `#f6f8fa` / pageBg | scss | `ImColors.pageBg` | ✅ | |
| E2 | NavBar 背景 `#f8f9ff` | nav-bar | `ImColors.navBarBg` | ✅ | |
| E3 | rpx 适配 | uni.upx2px | `rpx(context, n)` | ✅ | |
| E4 | Toast 样式 | uni.showToast | `ImToast` 居中遮罩 | ✅ | `m3_shell_ui_test`；批20：`chat_box`/`group_info` 已接 `ImFeedback` |
| E5 | 全局 loading | uni.showLoading | `ImLoading` 引用计数遮罩 | ✅ | 同 |
| E6 | popup-modal 确认框 | 组件 | `showImConfirmDialog` | ✅ | 同 |

---

## F. 线路（跨 Tab）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| F1 | 多线路列表配置 | lineStore | `lineProvider` | ✅ | |
| F2 | 当前线路探活 | checkCurrentLineStatus | 同 | ✅ | |
| F3 | 切换线路重连 WS | reconnect + onLineSwitched | `LineNotifier.onLineSwitched` | ✅ | `line_switch_test`；🔧 真机双跑 |
| F4 | 登录页/消息 Tab 可切换 | line-switcher | 同 | ✅ | |

---

## G. 已知差异

| ID | 检查项 | 状态 | 备注 |
|----|--------|------|------|
| G1 | uniapp 第四 Tab「群」 | ⏭ | pages.json 仅 3 tab；群从通讯录进 |
| G2 | assets/tabbar/group.png 未用 | ➕ | Flutter 资源有但未挂 Tab |
| G3 | H5 窗口 `active` chat-item | ⏭ | 多窗口桌面端 |

---

## 收口建议

1. ~~**F3** 切线路后 WS/API 双跑~~ ✅ 代码+单测（🔧 真机确认）
2. ~~**E4–E6** 统一 Toast/Loading/确认框~~ ✅ 已做（批20：`chat_box_page`/`group_info_page` 已迁移；其余页仍含少量 `SnackBar`）
