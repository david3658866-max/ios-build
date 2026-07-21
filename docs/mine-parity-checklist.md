# 我的 / 设置 细项对照清单（uniapp → Flutter）

> **对照源**：`im-uniapp/pages/mine/mine.vue`、`mine-edit.vue`、`mine-account.vue`、`mine-password.vue`、`mine-phone.vue`、`mine-email.vue`、`mine-qrcode.vue`、`mine-teenager.vue`、`mine-about-us.vue`、`mine-setting.vue`  
> **Flutter 主文件**：`lib/pages/main/tabs/mine_tab.dart`、`lib/pages/mine/*`  
> **自动化**：`test/m3_mine_util_test.dart`、`test/m3_auth_mine_test.dart`、`test/m3_page_smoke_test.dart`

**最后核对**：2026-07-01

---

## A. 我的 Tab（mine.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | NavBar「我的」 | nav-bar | `ImNavBar` | ✅ | |
| A2 | 头部渐变用户信息卡 | `.user-info` 渐变 | `_UserHeader` 渐变 | ✅ | |
| A3 | 头像 160rpx | head-image 160 | `HeadImage` ~160rpx | ✅ | |
| A4 | 昵称 + 公司 @tag | company-tag-mini | 同 | ✅ | |
| A5 | 性别图标 男/女 | icon-man/girl | Icons 男/女 | ✅ | |
| A6 | 用户编号 + 复制 | copy icon | `Clipboard` + toast | ✅ | |
| A7 | 用户名行 | userName | 同 | ✅ | |
| A8 | 个性签名 | signature | 同 | ✅ | |
| A9 | 点击头部 → 个人资料 | mine-edit | `mineProfile` | ✅ | |
| A10 | 二维码图标 → mine-qrcode | icon-qrcode | QR 按钮 | ✅ | |
| A11 | 右箭头进资料 | info-arrow | 同 | ✅ | |
| A12 | 「服务」入口（金融产品） | LOAN_ENABLED | ⏭ | 范围外 |
| A13 | 菜单分组 bar-group | 4 组 | `ImBarGroup` 3 组 | ✅ | 无服务组 |
| A14 | 个人资料 / 账号安全 | arrow-bar 色 | `ImArrowBar` 色值对齐 | ✅ | |
| A15 | 设置 / 关于 | arrow-bar | 同 | ✅ | |
| A16 | 实名认证菜单 | 已注释隐藏 | ⏭ | uniapp 亦隐藏 |

---

## B. 个人资料（mine-edit.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | 修改头像（拍照/相册） | chooseImage | `ProfileEditPage` picker | 🔧 | |
| B2 | 修改昵称 | input | TextField | ✅ | |
| B3 | 修改性别 | picker | 选择 | 🔧 | |
| B4 | 修改个性签名 | textarea | 同 | ✅ | |
| B5 | 保存调 `/user/update` | API | `userApi.update` | ✅ | |
| B6 | 保存后刷新 userStore | loadUser | `loadSelf` | ✅ | |

---

## C. 账号安全（mine-account.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | 修改密码入口 | mine-password | `password` route | ✅ | |
| C2 | 绑定手机入口 + 状态 | mine-phone | `bindPhone` | ✅ | |
| C3 | 绑定邮箱入口 + 状态 | mine-email | `bindEmail` | ✅ | |
| C4 | 展示当前绑定信息脱敏 | mask phone/email | `StringUtil.maskPhone/Email` | ✅ | account + profile |

---

## D. 修改密码（mine-password.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | 原密码 / 新密码 / 确认 | 三输入框 | `PasswordPage` | ✅ | |
| D2 | 提交校验一致性 | validate | 同 | ✅ | |
| D3 | 成功 toast + 返回 | API PUT | 同 | ✅ | |

---

## E. 绑定手机 / 邮箱

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | 发送验证码 | SMS API | `BindPhonePage` + 图形验证码 | ✅ | 🔧 真机短信 |
| E2 | 验证码倒计时 | 60s | `UserBindUtil.smsCodeLockSeconds` | ✅ | |
| E3 | 绑定提交 | bind API | `UserBindApiBody` 契约 | ✅ | 🔧 真机 API |
| E4 | 邮箱绑定流程 | mine-email | `BindEmailPage` 同结构 | ✅ | 🔧 真机邮件 |

---

## F. 我的二维码（mine-qrcode.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| F1 | 头像+昵称卡片 | card | `MineQrcodePage` | ✅ | |
| F2 | 用户 id 二维码 | uqrcode | `qr_flutter` | ✅ | |
| F3 | 保存相册 | save | share/save | 🔧 | |
| F4 | 扫码加好友解析 | scan handler | `scan_page` | 🔧 | |

---

## G. 青少年模式（mine-teenager.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| G1 | 开启需设置 PIN | password | `TeenagerPage` | ✅ | |
| G2 | 关闭需验证 PIN | verify | 同 | ✅ | |
| G3 | 本地 KV `teenagerMode` | storage key | `chats-app-$userId-teenagerMode` | ✅ | |
| G4 | 设置页显示「已开启」 | trailing text | `SettingsPage` | ✅ | |
| G5 | 青少年模式下功能限制 | 业务拦截 | `TeenagerModeUtil` + 5 入口 | ✅ | uniapp 无拦截；Flutter 按文案补全 |

---

## H. 设置（mine-setting.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| H1 | 加好友需验证 switch | manualApprove | `ImSwitchBar` | ✅ | |
| H2 | 新消息提示音 switch | audioTip | 同 | ✅ | |
| H3 | 青少年模式入口 | mine-teenager | `ImArrowBar` | ✅ | |
| H4 | 退出登录确认 | popup-modal | `showImConfirmDialog` | ✅ | `m3_shell_ui_test` |
| H5 | 退出清 token / 回登录 | logout | `authController.logout` | ✅ | |
| H6 | 自动上传通讯录 switch | addressBookUploader | ⏭ | uniapp 注释掉；采集见 app-capability |
| H7 | 自动上传通话记录 switch | callLogs | ⏭ | uniapp 注释掉；同上 |
| H8 | 清除缓存 | 若有 | ⏭ | uniapp 设置页亦无此项 |

---

## I. 关于我们（mine-about-us.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| I1 | App 名称 + logo | about | `AboutPage` | ✅ | |
| I2 | 版本号 | version | `package_info` | ✅ | |
| I3 | 用户协议 / 隐私政策链接 | external-link | `ExternalLinkPage` | 🔧 | |
| I4 | 检查更新 | optional | ⬜ | 可选 |

---

## 收口建议

1. **E1–E4** 绑定手机/邮箱真机（短信）
2. **G5** 青少年模式业务拦截点梳理
3. **B1–B3、F3** 头像与二维码保存
4. ~~H6/H7/H8~~ H6/H7 ⏭ uniapp 注释；H8 ⏭ uniapp 无此项
