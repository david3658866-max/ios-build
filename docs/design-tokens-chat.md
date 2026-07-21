# 聊天模块设计 Token（从 im-uniapp scss 提取）

> 来源文件：
> - `im-uniapp/components/chat-item/chat-item.vue`（scoped scss）
> - `im-uniapp/pages/chat/chat.vue`（scss）
> - `im-uniapp/im-var.scss`（全局变量）
> - `im-uniapp/im.scss`（`.company-tag-mini`）
> - `im-uniapp/components/head-image/head-image.vue`（默认尺寸、在线态）
>
> **rpx → Flutter 逻辑像素换算**：`dp = rpx × screenWidth / 750`  
> 以 iPhone 12/13 宽度 390px 为参考：`dp ≈ rpx × 0.52`  
> Flutter 实现：`lib/theme/rpx.dart` 中 `rpx(context, value)` 按屏宽动态换算。

---

## 1. 色板

### 1.1 全局（im-var.scss）

| Token | scss 变量 | 值 | 用途 |
|-------|-----------|-----|------|
| `primary` | `$im-color-primary` | `#3e45d7` | 主色、置顶角标底色 |
| `danger` | `$im-color-danger` | `#e43d33` | @我 / @全体成员 高亮 |
| `success` | `$im-color-success` | `#18bc37` | — |
| `warning` | `$im-color-warning` | `#f3a73f` | — |
| `text` | `$im-text-color` | `#000000` | 主文字（空态标题等） |
| `textLight` | `$im-text-color-light` | `#6a6a6a` | 次要文字 |
| `textLighter` | `$im-text-color-lighter` | `#909399` | 时间、摘要、空态副文案 |
| `border` | `$im-border` | `#F0F0F0` | — |
| `borderLight` | `$im-border-light` | `#EDEDED` | chat-item 底部分割线 |
| `bgActive` | `$im-bg-active` | `#f7f8fc` | 列表项 hover/active/选中 |
| `pageBg` | `$im-bg` | `#eef0f5` | Tab 页背景 |
| `navBarBg` | `$im-nav-bar-bg` | `#ffffff` | 导航栏、列表区背景 |

### 1.2 chat-item 专用

| Token | 值 | 用途 |
|-------|-----|------|
| `itemBg` | `#ffffff` | 列表项默认背景 |
| `itemBgActive` | `$im-bg-active` (#f7f8fc) | hover / active / `.active` |
| `divider` | `$im-border-light` (#EDEDED) | 底部分割线 |
| `atText` | `$im-color-danger` (#e43d33) | `.chat-at-text` |
| `contentText` | `$im-text-color-lighter` (#909399) | 摘要行默认色 |
| `timeText` | `$im-text-color-lighter` (#909399) | `.chat-time` |
| `nameText` | 继承默认（黑色） | `.chat-name-text`，未单独设 color |
| `topBadgeGradient` | `linear-gradient(225deg, #ffffff50 25%, #00000060), #3e45d7` | 置顶角标 |
| `topBadgeIcon` | `#ffffff` | 角标内图标 |

### 1.3 company-tag-mini（im.scss，chat-item 内联使用）

| Token | 值 | 用途 |
|-------|-----|------|
| `companyTag` | `#fa9d3b` | `@公司名` 标签 |
| `companyTagSize` | `$im-font-size-smaller` (28rpx) | 字号 |
| `companyTagMarginLeft` | 3rpx | 与昵称间距 |

### 1.4 chat.vue 页面

| Token | 值 | 用途 |
|-------|-----|------|
| `scrollBg` | `#ffffff` | `.chat-scroll-box` |
| `statusTipBg` | `rgba(255,255,255,0.9)` | 初始化/加载条背景 |
| `statusTipBorder` | `rgba(0,0,0,0.05)` | 状态条底边 |
| `statusTipText` | `$im-text-color-lighter` | 状态文案 |
| `emptyIconGradient` | `linear-gradient(135deg, #f8f9fa, #e9ecef)` | 空态图标圆底 |
| `emptyIconShadow` | `0 4rpx 12rpx rgba(0,0,0,0.08)` | 空态图标阴影 |
| `emptyIconBorder` | `$im-bg-active` (#f7f8fc) | 空态图标描边 |
| `emptyIconColor` | `$im-text-color-lighter` | 空态图标色 |
| `emptyTitle` | `$im-text-color` (#000) | 「还没有聊天」 |
| `emptyContent` | `$im-text-color-lighter` | 引导副文案 |

### 1.5 head-image 在线态（head-image.vue）

| Token | 值 | 用途 |
|-------|-----|------|
| `onlineDot` | `limegreen` | 在线绿点 |
| `onlineDotBorder` | `#ffffff` 6rpx | 绿点外白环 |

### 1.6 uni-badge（chat-item 未覆写样式）

chat-item 使用 `<uni-badge :max-num="99">`，未传 `type`/`color`，走 uni-ui 默认（一般为红底白字圆角胶囊）。Flutter 实现时可暂用 `ImColors.danger` 或 Material `Colors.red` 近似，待引入 uni-badge 等价组件时再对齐。

---

## 2. 字号（im-var.scss）

| scss 变量 | rpx | 390px 参考 dp | chat 模块用途 |
|-----------|-----|---------------|---------------|
| `$im-font-size-smaller-extra` | 26 | 14 | `.chat-time` |
| `$im-font-size-smaller` | 28 | 15 | 摘要行、状态条、空态副文案 |
| `$im-font-size-small` | 30 | 16 | — |
| `$im-font-size` | 32 | 17 | 免打扰图标 `.icon` |
| `$im-font-size-large` | 34 | 18 | 会话昵称、空态标题 |
| 置顶角标图标 | 20 | 10 | `.chat-top .icon` |
| 空态图标 | 60 | 31 | `.tip-icon .iconfont` |
| 状态 loading 图标 | 40 | 21 | `.chat-status-tip .rotate` |

---

## 3. 间距与尺寸

### 3.1 chat-item 布局

| 元素 | scss 值 | 390px 参考 dp | 说明 |
|------|---------|---------------|------|
| `.chat-item` height | **120rpx** | 62 | 固定行高 |
| padding | **10rpx 24rpx** | 5 × 12 | 上下 × 左右 |
| `.left`（头像区） | **96×96rpx** | 50 × 50 | 与 head-image default 一致 |
| `.chat-right` padding-left | **20rpx** | 10 | 头像与文字间距 |
| `.chat-right` padding-right | **5rpx** | 3 | 右侧留白 |
| 底部分割线 left | **140rpx** | 73 | = 24(padding) + 96(avatar) + 20(padding-left) |
| 底部分割线 height | **1rpx** | 0.5 | |
| `.chat-time` margin-left | **20rpx** | 10 | |
| `.chat-time` min-width | **80rpx** | 42 | |
| `.chat-content` padding-top | **8rpx** | 4 | 昵称与摘要间距 |
| DND 图标 margin-left | **10rpx** | 5 | |

### 3.2 置顶角标 `.chat-top`

| 属性 | scss 值 | 390px 参考 dp |
|------|---------|---------------|
| position | top/right **3rpx** | 2 |
| size | **35×35rpx** | 18 × 18 |
| border-radius | **6rpx 0 6rpx 0** | 3 0 3 0 |
| 图标 font-size | **20rpx** | 10 |
| 图标 offset | top **2rpx**, right **0** | 1, 0 |

### 3.3 head-image（chat-item 默认 size）

| 属性 | 值 |
|------|-----|
| 默认 `_size` | **96rpx**（字符串 `'default'`） |
| 文字头像 font-size | `_size × 0.45` → **43.2rpx** |
| 文字头像背景 | `linear-gradient(145deg,#ffffff20 25%,#00000060), {hash色}` |
| 在线点 size | **24rpx**，border **6rpx** white，right **-10%** |

### 3.4 chat.vue 页面

| 元素 | scss 值 | 390px 参考 dp |
|------|---------|---------------|
| `.drop-menu-btn` margin | **0 8rpx** | 0 × 4 |
| `.chat-status-tip` padding | **12rpx 24rpx** | 6 × 12 |
| `.chat-status-tip` gap | **14rpx** | 7 |
| `.chat-tip` padding | **40rpx** | 21 |
| `.chat-tip` width | **80%** | — |
| `.tip-icon` size | **120×120rpx** | 62 × 62 |
| `.tip-icon` margin-bottom | **40rpx** | 21 |
| `.tip-title` margin-bottom | **20rpx** | 10 |
| `.tip-content` margin-bottom | **50rpx** | 26 |
| `.tip-content` line-height | **1.6** | — |

### 3.5 导航栏（chat 页 nav-bar，im-var.scss）

| 属性 | 值 |
|------|-----|
| height | `$im-nav-bar-height` = **50px**（固定 px） |
| background | `#ffffff` |
| title | `$im-font-size-large` = 34rpx，左对齐 `title-align="left"` |

---

## 4. 与 ImColors 映射 / 差异

当前定义见 `lib/theme/im_colors.dart`。

| scss / 用途 | scss 值 | ImColors 常量 | 状态 |
|-------------|---------|---------------|------|
| `$im-bg` | `#eef0f5` | `pageBg` | ✅ 一致 |
| `$im-color-primary` | `#3e45d7` | `accent` | ✅ 一致 |
| 渐变浅色 | `#6e73e1` | `accentLight` | ✅ 一致（mine 头部） |
| `$im-nav-bar-bg` | `#ffffff` | `navBarBg` | ✅ 一致 |
| `$im-text-color` | `#000000` | `text` = `#333333` | ⚠️ **差异**：Flutter 略浅 |
| `$im-text-color-light` | `#6a6a6a` | `textLight` | ✅ 一致 |
| `$im-text-color-lighter` | `#909399` | `textLighter` | ✅ 一致 |
| `$im-border-light` | `#EDEDED` | `border` | ✅ 一致（命名：`border` = scss 的 border-light） |
| `$im-border` | `#F0F0F0` | `borderLight` | ✅ 一致（命名对调） |
| `$im-bg-active` | `#f7f8fc` | `bgActive` | ✅ 一致 |
| `$im-color-danger` | `#e43d33` | — | ❌ **缺失**，@我 文案需新增 |
| `#fa9d3b` company-tag | — | — | ❌ **缺失**，公司标签需新增 |
| 列表项白底 `#fff` | — | 硬编码 `Colors.white` | 可接受 |
| 置顶角标渐变 | 见 §1.2 | — | ❌ **缺失**，需组件内局部实现 |
| 空态图标渐变 | `#f8f9fa→#e9ecef` | — | ❌ **缺失** |
| 在线点 `limegreen` | — | — | ❌ **缺失** |

### 建议补充（ImColors 或 ChatColors）

```dart
// 建议在 im_colors.dart 或 lib/theme/chat_colors.dart 补充：
static const danger = Color(0xFFE43D33);
static const companyTag = Color(0xFFFA9D3B);
static const onlineDot = Color(0xFF32CD32); // CSS limegreen
static const emptyIconStart = Color(0xFFF8F9FA);
static const emptyIconEnd = Color(0xFFE9ECEF);
```

---

## 5. Flutter 实现映射

```
lib/theme/
  im_colors.dart          ← §4 全局色（补充 danger / companyTag）
  rpx.dart                ← rpx→dp
lib/widgets/chat/
  chat_item.dart          ← §3.1 chat-item 布局（勿改 M2 热点逻辑）
  head_image.dart         ← §3.3 头像尺寸、在线态
lib/pages/main/tabs/
  messages_tab.dart       ← §3.4 空态、状态条（M2 热点，仅引用 token）
```

每处 UI 数值应能在此文档找到 scss 来源；新增 chat 相关色优先写入 `ImColors` 或独立 `ChatColors`，避免魔法数散落。

---

## 6. 快速对照表（chat-item 核心）

| 属性 | uniapp | Flutter（rpx  helper） |
|------|--------|------------------------|
| 行高 | 120rpx | `rpx(context, 120)` |
| 水平 padding | 24rpx | `rpx(context, 24)` |
| 垂直 padding | 10rpx | `rpx(context, 10)` |
| 头像 | 96rpx default | `HeadImage(size: 96)` |
| 昵称字号 | 34rpx large | `rpx(context, 34)` |
| 时间字号 | 26rpx smaller-extra | `rpx(context, 26)` |
| 摘要字号 | 28rpx smaller | `rpx(context, 28)` |
| 摘要上间距 | 8rpx | `rpx(context, 8)` |
| 分割线 left inset | 140rpx | `rpx(context, 140)` |
| 选中/按压背景 | #f7f8fc | `ImColors.bgActive` |
| @我 颜色 | #e43d33 | 待 `ImColors.danger` |
