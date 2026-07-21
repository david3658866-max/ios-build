# 登录 / 注册 / 找回 细项对照清单（uniapp → Flutter）

> **对照源**：`im-uniapp/pages/login/login.vue`、`qr-login-confirm.vue`、`pages/register/register.vue`、`pages/common/reset-pwd.vue`  
> **Flutter 主文件**：`lib/pages/login/*`、`lib/widgets/auth/*`  
> **自动化**：`test/m3_auth_mine_test.dart`（含 `AuthFormUtil`、`PolicyConsentUtil`）

**最后核对**：2026-07-01

---

## A. 登录页（login.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| A1 | 全屏 auth 布局 | auth-page scss | `AuthPageScaffold` | ✅ | |
| A2 | 顶部线路切换器 | line-switcher | scaffold 内 `LineSwitcher` | ✅ | |
| A3 | 线路切换面板右对齐 | panel align right | `LineSwitcherPanel` + `LinePanelAlign.right` | ✅ | `line_switch_test`；🔧 真机位置 |
| A4 | 品牌名 + hero 标题 | brand + modeName | `AppConstants.appName` + 密码登录 | ✅ | |
| A5 | 副标题「安全稳定的即时通讯」 | hero-sub | 同 | ✅ | |
| A6 | 手机号输入 maxlength 11 | input number | `AuthField` + 校验 | ✅ | |
| A7 | 密码显示/隐藏切换 | icon-pwd-show/hide | obscure toggle | ✅ | |
| A8 | 输入框 focus 边框高亮 | `.focused` | `AuthField` focus 态 | ✅ | |
| A9 | 立即登录按钮 | submit | `GradientButton` | ✅ | |
| A10 | 手机号格式校验 toast | validate | `AuthFormUtil.phoneValidationError` | ✅ | |
| A11 | 登录 API + 存 token | login | `authController.loginWithPassword` | ✅ | |
| A12 | 记住手机号/密码（本地） | storage | `kvStore` loginPhone/savedPassword | ✅ | |
| A13 | 跳转注册「立即注册」 | navigator register | `context.push register` | ✅ | |
| A14 | 图形验证码弹窗 | captcha-image（仅发短信） | ⏭ | uniapp 密码登录 submit 无验证码；找回密码/绑定有 |
| A15 | 多种登录方式切换 | phone/username 等 modes | `AuthLoginModeUtil` | ✅ | uniapp `modes()` 当前仅 username；Flutter 等同 |
| A16 | 用户协议 policy 组件 | APP-PLUS policy | `PolicyConsentGate` + `PolicyConsentPanel` | ✅ | Android/iOS；uniapp iOS 自定义弹窗 |
| A17 | 登录成功进主 Tab | reLaunch main | `go` main shell | ✅ | |
| A18 | 登录失败 toast | showToast | `ImToast` | ✅ | |

---

## B. 注册（register.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| B1 | auth 同布局 | auth-page | `AuthPageScaffold` | ✅ | |
| B2 | 手机号 + 密码 + 邀请码 | form | `RegisterPage` + `AuthFormUtil` | ✅ | |
| B3 | 邀请码/验证码（若开启） | optional field | 🔧 | 视后端配置 |
| B4 | 图形验证码 | captcha | 🔧 | |
| B5 | 注册 API | POST register | `authApi.register` | ✅ | |
| B6 | 成功跳登录或自动登录 | navigate | 同 | 🔧 | |
| B7 | 返回登录链接 | link | TextButton | ✅ | |

---

## C. 找回密码（reset-pwd.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| C1 | 手机号/邮箱输入 | form | `ResetPwdPage` + `AuthFormUtil` | ✅ | |
| C2 | 短信验证码 + 发送 | SMS | 发送按钮 | 🔧 | |
| C3 | 新密码 + 确认 | inputs | 同 | ✅ | |
| C4 | 图形验证码 | captcha-image | `ImageCaptchaDialog` | ✅ | |
| C5 | 提交 reset API | POST | `authApi.resetPwd` | ✅ | |
| C6 | 成功回登录 | navigateBack | pop/go login | ✅ | |

---

## D. 扫码登录确认（qr-login-confirm.vue）

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| D1 | 展示电脑示意图 | illustration | `QrComputerIllustration` | ✅ | |
| D2 | 确认登录 API | qrConfirm | `authApi.qrConfirm` | ✅ | |
| D3 | 取消登录 API | qrCancel | `authApi.qrCancel` | ✅ | |
| D4 | 无效 qrCode 提示 | toast | 页内校验 | ✅ | |
| D5 | 从扫码页带 qr 参数进入 | query | route `qrCode` | ✅ | |

---

## E. 启动与会话恢复

| ID | 检查项 | uniapp | Flutter | 状态 | 备注 |
|----|--------|--------|---------|------|------|
| E1 | Splash 检查 token | App.vue onLaunch | `splash_page` | ✅ | |
| E2 | refreshToken 静默续期 | interceptor | `authController` | ✅ | |
| E3 | token 失效跳登录 | 401 handler | 同 | ✅ | |
| E4 | 异地登录踢下线 cmd2 | WS handler | `message_dispatcher` | 🔧 | 需双机 |
| E5 | 登录后拉 user/friend/group/chat | init load | bootstrap | ✅ | |

---

## F. 范围外 / 缺口汇总

| ID | 检查项 | 状态 | 备注 |
|----|--------|------|------|
| F1 | 用户名登录 mode | ✅ | uniapp 仅 username；`AuthLoginModeUtil` + 单测 |
| F2 | 登录图形验证码 | ⏭ | 与 uniapp 一致：仅 SMS 发送前需验证码 |
| F3 | 隐私政策首次弹窗 | ✅ | `has_read_privacy` KV；登录页门禁 |
| F4 | 忘记密码入口（登录页链） | onForgotPassword | `忘记密码？` → resetPwd | ✅ | uniapp 多 mode 菜单简化为直链 |

---

## 收口建议

1. ~~**A14–A16** 验证码与协议（合规）~~ ✅ A16/F3 已做  
2. **B3–B4、C2** 短信验证码真机
3. **E4** 异地登录双机验收
4. 确认登录页「忘记密码」链接是否存在（`login_page.dart` 尾部）
