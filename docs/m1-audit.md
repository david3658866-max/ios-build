# M1 复刻差异清单（im-uniapp → im-flutter）

> 目的：逐页/逐接口对照"老代码（im-uniapp + 后端 im-platform）"与现有 Flutter 实现，
> 列出所有偏差，作为返工依据。UI 标准 = **高度接近**（结构与视觉风格一致，细微间距可偏差）。
>
> 严重度：🔴 必改（明显偏离/可能影响功能） · 🟡 应改（视觉/交互不一致） · 🔵 待核对（需真机或账号验证）

---

## 0. 总体结论

现有 Flutter 登录模块**功能骨架在、但"复刻"严重不到位**，根因是：

1. **没有复刻设计系统**：原 App 登录/注册共用 `common/auth-page.scss`（靛蓝 Hero 渐变 + 白色圆角浮层 + 自定义圆角输入框 + 渐变胶囊按钮 + iconfont 图标）。Flutter 全部用了 Material 默认控件（`AppBar` + `OutlineInputBorder` + `FilledButton` + Material 图标），外观完全不同。
2. **接口入参没对齐**：`deviceInfo`/`deviceId`/`clientVersion` 取值方式与原 App 不同；登录少传 `phone/email/code` 字段。这正是登录 500 的高度可疑点。
3. **个别页面自创了原版没有的交互**（登录页多了"忘记密码"、注册页多了"确认密码"、找回密码页多了"手机/邮箱切换"）。

> 下面按"设计系统 → 逐页 → 接口契约"列出明细。

---

## 1. 全局 / 设计系统差异（最高优先级，所有页面共享）

来源：`im-uniapp/common/auth-page.scss`、`im.scss`、`static/icon/iconfont.css`、`pages.json`

| # | 维度 | 原 App | 现 Flutter | 严重度 |
|---|------|--------|-----------|--------|
| G1 | 整体布局 | 顶部 **Hero 渐变区**（min-height 640rpx，靛蓝 152° 渐变 + 两个装饰圆）+ 下方 **白色圆角浮层 `auth-sheet`**（上移 -64rpx 盖住 Hero，圆角 48rpx，顶部有渐变小横条） | 居中单列 `Column`，无 Hero、无浮层 | 🔴 |
| G2 | 主题色 | Hero `#262a8f→#3e45d7→#6e73e1`；主色 `#3e45d7`；浮层底 `#f5f5fd→#eeeefb`；页面底 `#e8e8f6`；输入框边框 `#dcddf4` | Material `colorScheme` 默认（紫蓝），未落这套色板 | 🔴 |
| G3 | 输入框 | `form-item`：高 108rpx、圆角 20rpx、白底 2rpx 边框；左侧**圆形渐变图标底座**内嵌 iconfont；聚焦时边框变主色 + 外发光；右侧明文切换 iconfont | `TextField` + `OutlineInputBorder` + Material `prefixIcon` + `labelText` 浮动标签 | 🔴 |
| G4 | 主按钮 | `submit-btn`：高 100rpx、圆角 50rpx、**三段渐变胶囊** + 阴影 + 按压缩放 | `FilledButton`（圆角矩形，纯色） | 🟡 |
| G5 | 图标体系 | iconfont：`icon-phone / icon-pwd / icon-pwd-show / icon-pwd-hide / icon-code / icon-email / icon-refresh / icon-shield` | Material：`Icons.phone_android / lock_outline / visibility...` | 🟡（建议引入 iconfont.ttf，或统一映射近似图标） |
| G6 | 品牌名 | `UNI_APP.APP_NAME`（默认"星语"），Hero 内 72rpx 字间距 10rpx | `AppConstants.appName` + `Icons.chat_rounded`（用了聊天图标当 Logo） | 🟡（需确认 appName 文案一致） |
| G7 | TabBar | 自定义底栏：消息 / 通讯录 / 我的，**PNG 图标**（`static/tabbar/*.png`），选中色 `#3e45d7`；页面顶部为自定义 `nav-bar` 组件 | `NavigationBar` + Material 图标 + `AppBar`（右侧塞了 WS 状态指示） | 🟡 |

**返工建议**：先在 Flutter 建一套 `auth` 设计资产——`AuthTheme`（色板常量）+ 可复用组件 `AuthHero`、`AuthSheet`、`AuthField`（圆角+圆形图标底座+聚焦态）、`GradientButton`。登录/注册/找回三页共用，避免再次各写各的。

---

## 2. 逐页差异

### 2.1 登录页 `login.vue` ↔ `login_page.dart`

UI：
- 🔴 **整页结构不同**：原版 = Hero（品牌名 + 动态标题 `密码登录` + 副标题"安全稳定的即时通讯"）+ 白色浮层（手机号框、密码框、登录按钮、"立即注册"）。Flutter = 聊天图标 + 大标题 appName + 副标题 + 两个 Material 输入框 + 按钮。
- 🔴 Hero 的 `hero-title` 是**动态登录方式名**（`密码登录`），Flutter 没有这一层级。
- 🟡 线路切换器：原版右上角绝对定位自定义 chip + 底部弹出面板（`line-switcher` + `line-switcher-panel`）。Flutter 用了 `LineSwitcher` chip，需对照视觉。

交互：
- 🔴 **多了"忘记密码"入口**：生产版 `modes=['username']` → 忘记密码菜单 `menuItems` 为空、`nav-tool-bar` **只有"立即注册"**。Flutter 额外加了"忘记密码"按钮 → 应移除（或与原版一致地隐藏）。
- 🟡 **缺少回填**：原版 `onLoad` 从缓存 `loginPhone/userName/password` 回填输入框。Flutter 未回填。
- 🟡 登录前后副作用：原版登录前 `unloadStore()+initStarted=false`，成功后写 `loginPhone/password/loginInfo` 再 `init()`。Flutter 由 `AuthController` 接管，但未保存 `loginPhone/password`（影响下次回填）。

接口入参（见 §3.1）：🔴 deviceInfo/字段不一致。

### 2.2 注册页 `register.vue` ↔ `register_page.dart`

UI：
- 🔴 整页结构同 §2.1（Hero + 浮层），Flutter 用了 `AppBar` + 普通表单。
- Hero 副标题应为"创建账号，即刻畅聊"，标题"手机注册"。

交互（生产 `modes=['phone']`，仅手机注册）：
- 🔴 **字段集不一致**：原版手机注册字段 = 手机号 → 密码 → **邀请码**（无"确认密码"！）。Flutter 加了"确认密码"框，且顺序为 手机/密码/确认/邀请。应去掉确认密码并把邀请码放到密码之后。
- 🔴 **校验不一致**：原版手机注册**不做密码长度/二次确认校验**（无确认框）。Flutter 校验了 5–20 位 + 两次一致。
- 🔵 `code` 固定 `123456`、`userName=user_<手机号>`、`registerTerminal=1` —— Flutter `AuthController.register` **已正确对齐**（✅），仅 deviceInfo 系列待修（见 §3）。

### 2.3 找回密码页 `reset-pwd.vue` ↔ `reset_pwd_page.dart`

UI：
- 🔴 原版用自定义 `nav-bar`("重置密码") + 一套**独立 scss**（白底 0.9、圆角 25rpx、`$im-color-primary` 主色、按钮下方副标题"验证身份，设置新密码"）。Flutter 用 `AppBar` + Material 表单 + `SegmentedButton`。
- 🔴 **多了"手机/邮箱"切换器**：原版**没有页内切换**，`mode` 由路由参数（`?mode=phone|email`）决定，从登录页"忘记密码菜单"进入。Flutter 自创了 `SegmentedButton`。

交互：
- 字段：手机模式 = 手机号 → 验证码（含"获取验证码"，**先图形验证码再短信**）→ 新密码 → 确认密码；邮箱模式 = 邮箱 → 验证码 → 新密码 → 确认密码。Flutter 流程基本一致（图形验证码弹窗已复刻 ✅）。
- 🔵 入口：由于生产登录页隐藏了忘记密码菜单，此页**实际入口缺失**——需确认产品是否仍要保留该页/入口。

接口：PUT `/resetPwd`，后端 `ResetPwdDTO` 仅需 `{mode, phone|email, code, password}`（无 confirmPassword）。Flutter 多传 `confirmPassword`（后端忽略，无害）；🟡 原版 phone/email 两键都传（一个空），Flutter 只传其一。

### 2.4 扫码登录确认页 `qr-login-confirm.vue` ↔ `qr_login_confirm_page.dart`

UI：
- 🟡 原版有**纯 CSS 绘制的"电脑"插画**（屏幕+底座+浏览器圆点+表单线）、状态文案"登录 {appName}网页端"、蓝色"安全提示"卡片、**固定底部**确认胶囊 + 取消文字。Flutter 用 `Icons.computer` + 标题 + Card 提示 + 普通按钮，结构近似但视觉差距大。

接口：
- ✅ 确认：POST `/qrLogin/confirm` body `{qrCode}`，与后端 `@RequestBody QrLoginDTO` 一致。
- 🔵 **取消接口路径需核对**：后端是 `DELETE /qrLogin/cancel/{qrCode}`（**路径参数**）；原版 uniapp 写的是 `delete '/qrLogin/cancel'` + body `{qrCode}`（疑似老代码 bug）。Flutter `authApi.qrCancel` 的真实请求需核对是否用了路径参数。

### 2.5 启动链路 `App.vue onLaunch/init` ↔ `splash_page.dart` + `AuthController.bootstrap`

- 🔴 **冷启动缺少主动刷新 token**：原版 `onLaunch` **先** `PUT /refreshToken`（refreshToken 放 header）拿到新 token，**再** `loadUser`；失败才去登录页。Flutter `bootstrap` 直接 `loadSelf`，依赖 Dio 401 单飞刷新兜底——行为不同（原版每次冷启动都会主动换新 token）。
- 🟡 `bootstrap` 仅 `loadSelf`；原版 `init→loadStore` 还会并行加载 friend/group/chat/config（属 M2 数据，可暂缓，但需登记）。
- 🟡 Splash 视觉：原版用系统启动图（`closeSplashscreen`）；Flutter 自绘了聊天图标 + loading，可接受。

### 2.6 主框架 `tabBar` ↔ `main_shell.dart`

- 🟡 Tab 文案/顺序一致（消息/通讯录/我的 ✅），但图标为 Material 矢量 vs 原版 PNG；选中色未必是 `#3e45d7`。
- 🟡 顶部：原版每个 tab 页是自定义 `nav-bar`；Flutter 统一 `AppBar` 且把 WS 状态做成右上角指示器（原版 WS 状态展示位置/样式需核对）。

---

## 3. 接口契约 / 参数级差异（与后端 im-platform 对照）

### 3.1 `POST /login`（🔴 重点，疑似 500 根因）

后端 `LoginDTO` 字段：`mode, terminal(0/1/2,必填), userName, phone, email, password, totpCode, code, deviceInfo, deviceId, clientVersion, loginType`。

原版实际发送（`login.vue` 把整个 `dataForm` 发出）：
```
{ terminal:1, mode:'username', userName:<手机号>, password:<明文>,
  phone:<手机号>, email:'', code:'',
  deviceInfo:'<model>|<version>|<vendor>', clientVersion:'<版本>', deviceId:'<UUID>', loginType:'android'|'ios' }
```
Flutter 现发送（`LoginDTO`）：
```
{ mode:'username', terminal:1, userName:<手机号>, password,
  deviceId:kv.devId, loginType:'android', deviceInfo, clientVersion:'1.0.0' }
```

差异：
- 🔴 **`deviceInfo` 取值错误**：原版 = `型号|系统版本|厂商`（如 `Pixel 6|13|Google`）；Flutter = `Platform.operatingSystem|operatingSystemVersion|`（如 `android|...|`，**厂商空、用 OS 名当型号**）。需接 `device_info_plus` 真实取值。
- 🟡 **少传 `phone/email/code`**：原版即使用户名登录也带 `phone=<手机号>, email:'', code:''`。建议补齐以完全一致。
- 🔵 **`deviceId`**：原版来自 `getDeviceInfo().deviceId`（持久化 UUID）；Flutter 用 `kv.devId`，需确认是否同源/持久化。
- 🔵 **`clientVersion`**：原版来自 `version.js`；Flutter 硬编码 `1.0.0`，需确认后端是否对版本号有校验。

> 注：当前真机登录返回 `HTTP200 + {code:500,"系统繁忙"}`，结合上述 deviceInfo/字段差异，**优先怀疑后端按 deviceInfo/deviceId 做了处理而入参不规范**；待用账号 + curl 复刻原版完整入参后即可定位（属后续"接口验证"步骤）。

### 3.2 `POST /register`
- 后端 `RegisterDTO` 必填：`userName(非空,≤20)`、`password(5-20)`；手机注册另需 `inviteCode`。
- Flutter `AuthController.register` 入参 ✅ 对齐（`mode=phone, userName=user_<phone>, code=123456, registerTerminal=1, inviteCode`），仅 deviceInfo 同 §3.1 问题。

### 3.3 `PUT /resetPwd`
- 后端 `ResetPwdDTO`：`{mode, phone, email, password(5-20,非空), code}`。
- Flutter ✅ 基本一致；多传 `confirmPassword`（忽略）；🟡 只传 phone 或 email 之一。

### 3.4 验证码 `captcha-image` ↔ `image_captcha_dialog.dart`
- 取图 POST `/captcha/img/code` → `{id, image(base64)}`；校验 GET `/captcha/img/vertify?id=&code=` → bool。Flutter ✅ 对齐。
- 🟡 视觉：原版 220×110 图 + 圆形刷新按钮（iconfont）；Flutter 180×70 + "点击图片刷新"，可接受。

### 3.5 HTTP 响应包 / 鉴权（待逐行核对 `common/request.js` ↔ `dio_client/token_interceptor`）
- 🔵 统一信封 `Result<T>{code,message,data}`：`code==200` 取 `data`，否则 reject `{code,message}`。需确认 Flutter 对 **`data:null` 的成功响应**（register/resetPwd 返回 data 为 null）解析不抛 "Null is not a subtype"。
- 🔵 401 单飞刷新（refreshToken 放 header）、刷新失败 → exit/回登录。需对照 Flutter `token_interceptor` 行为一致。

---

## 4. 建议返工优先级与顺序

1. **P0 设计系统**（§1）：建 `auth` 主题色板 + 复用组件（Hero/Sheet/Field/GradientButton），是后续所有页面的地基。
2. **P0 登录页**（§2.1 + §3.1）：用新组件复刻 UI；修 `deviceInfo` 取真值、补齐入参；移除多余"忘记密码"；加回填。→ 用账号 curl + 真机验证登录闭环。
3. **P1 注册页**（§2.2）：复刻 UI；去掉"确认密码"、调字段顺序、对齐校验。
4. **P1 启动链路**（§2.5）：补"冷启动主动 refreshToken"。
5. **P2 找回密码 / 扫码确认 / 主框架**（§2.3/2.4/2.6）：复刻 UI；确认 reset 入口策略；核对 qrCancel 路径。
6. **P2 契约核对**（§3.5）：逐行核对 request.js ↔ dio 拦截器。

---

## 5. 今后固定工作法（写代码前必做）

- **真值优先级**：后端 Java 源码 > im-uniapp 源码 > 自行判断。
- **逐页三对照**：① 对照 `.vue` 模板/字段/校验/文案/跳转 ② 对照 scss 还原视觉 ③ 对照后端 Controller+DTO 核对入参/响应。
- **每页 DoD（完成定义）**：`flutter analyze` 0 error + 涉及接口 curl 实测通过（贴真实返回）+ 真机截图 vs 原 App 截图并排一致 + 入参字段逐一 diff 经确认。
